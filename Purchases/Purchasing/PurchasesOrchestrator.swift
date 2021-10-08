//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestrator.swift
//
//  Created by Andrés Boedo on 10/8/21.

import Foundation
import StoreKit

@objc protocol PurchasesOrchestratorDelegate {

    func shouldPurchasePromoProduct(_ product: SK1Product,
                                    defermentBlock: @escaping DeferredPromotionalPurchaseBlock)

}

class PurchasesOrchestrator {

    var finishTransactions: Bool { systemInfo.finishTransactions }
    var allowSharingAppStoreAccount: Bool {
        get {
            return maybeAllowSharingAppStoreAccount ?? identityManager.currentUserIsAnonymous
        }
        set {
            maybeAllowSharingAppStoreAccount = newValue
        }
    }

    @objc weak var maybeDelegate: PurchasesOrchestratorDelegate?

    private var maybeAllowSharingAppStoreAccount: Bool?
    private var presentedOfferingIDsByProductID: [String: String] = [:]
    private var purchaseCompleteCallbacksByProductID: [String: PurchaseCompletedBlock] = [:]

    private var appUserID: String { identityManager.currentAppUserID }
    private var unsyncedAttributes: SubscriberAttributeDict {
        subscriberAttributesManager.unsyncedAttributesByKey(appUserID: self.appUserID)
    }

    private let productsManager: ProductsManager
    private let storeKitWrapper: StoreKitWrapper
    private let systemInfo: SystemInfo
    private let subscriberAttributesManager: SubscriberAttributesManager
    private let operationDispatcher: OperationDispatcher
    private let receiptFetcher: ReceiptFetcher
    private let customerInfoManager: CustomerInfoManager
    private let backend: Backend
    private let identityManager: IdentityManager
    private let receiptParser: ReceiptParser
    private let deviceCache: DeviceCache
    private let manageSubscriptionsModalHelper: ManageSubscriptionsModalHelper
    private let lock = NSRecursiveLock()

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    lazy var storeKit2Listener = StoreKit2TransactionListener(delegate: self)

    init(productsManager: ProductsManager,
         storeKitWrapper: StoreKitWrapper,
         systemInfo: SystemInfo,
         subscriberAttributesManager: SubscriberAttributesManager,
         operationDispatcher: OperationDispatcher,
         receiptFetcher: ReceiptFetcher,
         customerInfoManager: CustomerInfoManager,
         backend: Backend,
         identityManager: IdentityManager,
         receiptParser: ReceiptParser,
         deviceCache: DeviceCache,
         manageSubscriptionsModalHelper: ManageSubscriptionsModalHelper) {
        self.productsManager = productsManager
        self.storeKitWrapper = storeKitWrapper
        self.systemInfo = systemInfo
        self.subscriberAttributesManager = subscriberAttributesManager
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.customerInfoManager = customerInfoManager
        self.backend = backend
        self.identityManager = identityManager
        self.receiptParser = receiptParser
        self.deviceCache = deviceCache
        self.manageSubscriptionsModalHelper = manageSubscriptionsModalHelper
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            storeKit2Listener.listenForTransactions()
        }
    }

    func restoreTransactions(completion maybeCompletion: ((CustomerInfo?, Error?) -> Void)?) {
        syncPurchases(receiptRefreshPolicy: .always, isRestore: true, maybeCompletion: maybeCompletion)
    }

    func syncPurchases(completion maybeCompletion: ((CustomerInfo?, Error?) -> Void)? = nil) {
        syncPurchases(receiptRefreshPolicy: .never,
                      isRestore: allowSharingAppStoreAccount,
                      maybeCompletion: maybeCompletion)
    }

    func products(withIdentifiers identifiers: [String], completion: @escaping ([SK1Product]) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        productsManager.products(withIdentifiers: productIdentifiersSet) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(Array(products))
            }
        }
    }

    func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: [String],
                                            completion: @escaping ([ProductDetails]) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: productIdentifiersSet) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(Array(products))
            }
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func paymentDiscount(forProductDiscount productDiscount: SKProductDiscount,
                         product: SK1Product,
                         completion: @escaping (SKPaymentDiscount?, Error?) -> Void) {
        guard let discountIdentifier = productDiscount.identifier else {
            completion(nil, ErrorUtils.productDiscountMissingIdentifierError())
            return
        }

        guard let subscriptionGroupIdentifier = product.subscriptionGroupIdentifier else {
            completion(nil, ErrorUtils.productDiscountMissingSubscriptionGroupIdentifierError())
            return
        }

        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeReceiptData in
            guard let receiptData = maybeReceiptData,
                  !receiptData.isEmpty else {
                      completion(nil, ErrorUtils.missingReceiptFileError())
                      return
                  }

            // swiftlint:disable line_length
            self.backend.post(offerIdForSigning: discountIdentifier,
                              productIdentifier: product.productIdentifier,
                              subscriptionGroup: subscriptionGroupIdentifier,
                              receiptData: receiptData,
                              appUserID: self.appUserID) { maybeSignature, maybeKeyIdentifier, maybeNonce, maybeTimestamp, maybeError in
                if let error = maybeError {
                    completion(nil, error)
                    return
                }
            // swiftlint:enable line_length
                guard let keyIdentifier = maybeKeyIdentifier,
                      let nonce = maybeNonce,
                      let signature = maybeSignature,
                      let timestamp = maybeTimestamp else {
                          completion(nil, ErrorUtils.unexpectedBackendResponseError())
                          return
                      }

                let paymentDiscount = SKPaymentDiscount(identifier: discountIdentifier,
                                                        keyIdentifier: keyIdentifier,
                                                        nonce: nonce,
                                                        signature: signature,
                                                        timestamp: timestamp)
                completion(paymentDiscount, nil)
            }
        }
    }

    func purchase(package: Package, completion: @escaping PurchaseCompletedBlock) {
        // todo: clean up, move to new class along with the private funcs below
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           package.productDetails is SK2ProductDetails {
            Task {
                let result = await purchase(sk2Package: package)
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        completion(nil, nil, error, false)
                    case .success(let (customerInfo, userCancelled)):
                        // todo: change API and send transaction
                        if userCancelled {
                            completion(nil, nil, ErrorUtils.purchaseCancelledError(), userCancelled)
                        } else {
                            completion(nil, customerInfo, nil, userCancelled)
                        }
                    }
                }
            }
        } else {
            guard package.productDetails is SK1ProductDetails else {
                fatalError("could not identify StoreKit version to use!")
            }
            purchase(sk1Package: package, completion: completion)
        }

    }

    func purchase(sk1Product: SK1Product,
                  payment: SKMutablePayment,
                  presentedOfferingIdentifier maybePresentedOfferingIdentifier: String?,
                  completion: @escaping PurchaseCompletedBlock) {
        Logger.debug(String(format: "Make purchase called: %@", #function))
        guard let productIdentifier = extractProductIdentifier(fromProduct: sk1Product, orPayment: payment) else {
            Logger.error(Strings.purchase.could_not_purchase_product_id_not_found)
            let errorMessage = "There was a problem purchasing the product: productIdentifier was nil"
            completion(nil, nil, ErrorUtils.unknownError(message: errorMessage), false)
            return
        }

        if !self.finishTransactions {
            Logger.warn(Strings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning)
        }

        payment.applicationUsername = appUserID
        preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: appUserID)

        if let presentedOfferingIdentifier = maybePresentedOfferingIdentifier {
            Logger.purchase(
                Strings.purchase.purchasing_product_from_package(
                    productIdentifier: productIdentifier,
                    offeringIdentifier: presentedOfferingIdentifier
                )
            )
            lock.lock()
            presentedOfferingIDsByProductID[productIdentifier] = presentedOfferingIdentifier
            lock.unlock()

        } else {
            Logger.purchase(Strings.purchase.purchasing_product(productIdentifier: productIdentifier))
        }

        productsManager.cacheProduct(sk1Product)

        lock.lock()
        defer {
            lock.unlock()
        }

        guard purchaseCompleteCallbacksByProductID[productIdentifier] == nil else {
            completion(nil, nil, ErrorUtils.operationAlreadyInProgressError(), false)
            return
        }
        purchaseCompleteCallbacksByProductID[productIdentifier] = completion
        storeKitWrapper.add(payment)
    }

    @available(iOS 9.0, *)
    @available(macOS 10.12, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscriptionModal(completion: @escaping (ManageSubscriptionsModalError?) -> Void) {
        self.manageSubscriptionsModalHelper.showManageSubscriptionModal { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success():
                completion(nil)
            }
        }
    }

}

extension PurchasesOrchestrator: StoreKitWrapperDelegate {

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper, updatedTransaction transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .restored, // for observer mode
             .purchased:
            handlePurchasedTransaction(transaction)
        case .purchasing:
            break
        case .failed:
            handleFailedTransaction(transaction)
        case .deferred:
            handleDeferredTransaction(transaction)
        @unknown default:
            Logger.warn("unhandled transaction state!")
        }
    }

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         removedTransaction transaction: SKPaymentTransaction) {
        // unused for now
    }

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         shouldAddStorePayment payment: SKPayment,
                         for product: SK1Product) -> Bool {
        productsManager.cacheProduct(product)
        guard let delegate = maybeDelegate else { return false }

        lock.lock()
        delegate.shouldPurchasePromoProduct(product) { completion in
            self.purchaseCompleteCallbacksByProductID[product.productIdentifier] = completion
            storeKitWrapper.add(payment)
        }
        lock.unlock()
        return false
    }

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(Strings.purchase.entitlements_revoked_syncing_purchases(productIdentifiers: productIdentifiers))
        syncPurchases { _, _ in
            Logger.debug(Strings.purchase.purchases_synced)
        }
    }

}

// MARK: Transaction state updates.
private extension PurchasesOrchestrator {

    func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeReceiptData in
            if let receiptData = maybeReceiptData,
               !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(withTransaction: transaction, receiptData: receiptData)
            } else {
                self.handleReceiptPost(withTransaction: transaction,
                                       maybeCustomerInfo: nil,
                                       maybeSubscriberAttributes: nil,
                                       maybeError: ErrorUtils.missingReceiptFileError())
            }
        }
    }

    func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error,
           let completion = getAndRemovePurchaseCompletedCallback(forTransaction: transaction) {
            let nsError = error as NSError
            let userCancelled = nsError.code == SKError.paymentCancelled.rawValue
            operationDispatcher.dispatchOnMainThread {
                completion(transaction,
                           nil,
                           ErrorUtils.purchasesError(withSKError: error),
                           userCancelled)
            }
        }

        if finishTransactions {
            storeKitWrapper.finishTransaction(transaction)
        }
    }

    func handleDeferredTransaction(_ transaction: SKPaymentTransaction) {
        let userCancelled: Bool
        if let error = transaction.error as NSError? {
            userCancelled = error.code == SKError.paymentCancelled.rawValue
        } else {
            userCancelled = false
        }

        guard let completion = getAndRemovePurchaseCompletedCallback(forTransaction: transaction) else {
            return
        }

        operationDispatcher.dispatchOnMainThread {
            completion(transaction, nil, ErrorUtils.paymentDeferredError(), userCancelled)
        }
    }

}

extension PurchasesOrchestrator: StoreKit2TransactionListenerDelegate {

    func transactionsUpdated() {
        // todo: should isRestore here be set to observer mode?
        syncPurchases(receiptRefreshPolicy: .always, isRestore: false, maybeCompletion: nil)
    }
}

// MARK: Private funcs.
private extension PurchasesOrchestrator {

    func getAndRemovePurchaseCompletedCallback(forTransaction transaction: SKPaymentTransaction) ->
        PurchaseCompletedBlock? {
        guard let productIdentifier = transaction.productIdentifier else {
            return nil
        }

        lock.lock()
        let maybeCompletion = purchaseCompleteCallbacksByProductID.removeValue(forKey: productIdentifier)
        lock.unlock()
        return maybeCompletion
    }

    func fetchProductsAndPostReceipt(withTransaction transaction: SKPaymentTransaction, receiptData: Data) {
        guard let productIdentifier = transaction.productIdentifier else {
            self.handleReceiptPost(withTransaction: transaction,
                                   maybeCustomerInfo: nil,
                                   maybeSubscriberAttributes: nil,
                                   maybeError: ErrorUtils.unknownError())
            return
        }

        self.products(withIdentifiers: [productIdentifier]) { products in
            self.postReceipt(withTransaction: transaction,
                             receiptData: receiptData,
                             products: Set(products))
        }
    }

    func postReceipt(withTransaction transaction: SKPaymentTransaction,
                     receiptData: Data,
                     products: Set<SK1Product>) {
        var maybeProductInfo: ProductInfo?
        var maybePresentedOfferingID: String?
        if let product = products.first {
            let productInfo = ProductInfoExtractor().extractInfo(from: product)
            maybeProductInfo = productInfo

            let productID = productInfo.productIdentifier
            let presentedOfferingID = presentedOfferingIDsByProductID[productID]
            maybePresentedOfferingID = presentedOfferingID

            presentedOfferingIDsByProductID.removeValue(forKey: productID)
        }
        let unsyncedAttributes = unsyncedAttributes

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: allowSharingAppStoreAccount,
                     productInfo: maybeProductInfo,
                     presentedOfferingIdentifier: maybePresentedOfferingID,
                     observerMode: !finishTransactions,
                     subscriberAttributes: unsyncedAttributes) { maybeCustomerInfo, maybeError in
            self.handleReceiptPost(withTransaction: transaction,
                                   maybeCustomerInfo: maybeCustomerInfo,
                                   maybeSubscriberAttributes: unsyncedAttributes,
                                   maybeError: maybeError)
        }
    }

    func handleReceiptPost(withTransaction transaction: SKPaymentTransaction,
                           maybeCustomerInfo: CustomerInfo?,
                           maybeSubscriberAttributes: SubscriberAttributeDict?,
                           maybeError: Error?) {
        operationDispatcher.dispatchOnMainThread {
            let appUserID = self.appUserID
            self.markSyncedIfNeeded(subscriberAttributes: maybeSubscriberAttributes,
                                    appUserID: appUserID,
                                    maybeError: maybeError)

            let maybeCompletion = self.getAndRemovePurchaseCompletedCallback(forTransaction: transaction)
            let nsError = maybeError as NSError?
            let finishable = (nsError?.userInfo[ErrorDetails.finishableKey as String] as? NSNumber)?.boolValue ?? false
            if let customerInfo = maybeCustomerInfo {
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: appUserID)
                maybeCompletion?(transaction, customerInfo, nil, false)

                if self.finishTransactions {
                    self.storeKitWrapper.finishTransaction(transaction)
                }
            } else if finishable {
                maybeCompletion?(transaction, nil, maybeError, false)
                if self.finishTransactions {
                    self.storeKitWrapper.finishTransaction(transaction)
                }
            } else {
                Logger.error(Strings.receipt.unknown_backend_error)
                maybeCompletion?(transaction, nil, maybeError, false)
            }
        }
    }

    func markSyncedIfNeeded(subscriberAttributes: SubscriberAttributeDict?, appUserID: String, maybeError: Error?) {
        if let error = maybeError as NSError? {
            if !error.successfullySynced {
                return
            }
            Logger.error(Strings.attribution.subscriber_attributes_error(errors: error.subscriberAttributesErrors))
        }

        subscriberAttributesManager.markAttributesAsSynced(subscriberAttributes, appUserID: appUserID)
    }

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       maybeCompletion: ((CustomerInfo?, Error?) -> Void)?) {
        if !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.restore.restoretransactions_called_with_allow_sharing_appstore_account_false_warning)
        }

        let currentAppUserID = appUserID
        let unsyncedAttributes = unsyncedAttributes
        // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
        // swiftlint:disable line_length
        // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
        // swiftlint:enable line_length
        receiptFetcher.receiptData(refreshPolicy: receiptRefreshPolicy) { maybeReceiptData in
            guard let receiptData = maybeReceiptData,
                  !receiptData.isEmpty else {
                      if SystemInfo.isSandbox {
                          Logger.appleWarning(Strings.receipt.no_sandbox_receipt_restore)
                      }

                      if let completion = maybeCompletion {
                          completion(nil, ErrorUtils.missingReceiptFileError())
                      }
                      return
                  }

            let maybeCachedCustomerInfo = self.customerInfoManager.cachedCustomerInfo(appUserID: currentAppUserID)
            let hasOriginalPurchaseDate = maybeCachedCustomerInfo?.originalPurchaseDate != nil
            let receiptHasTransactions = self.receiptParser.receiptHasTransactions(receiptData: receiptData)

            if !receiptHasTransactions && hasOriginalPurchaseDate {
                if let completion = maybeCompletion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(maybeCachedCustomerInfo, nil)
                    }
                }
                return
            }

            self.backend.post(receiptData: receiptData,
                              appUserID: currentAppUserID,
                              isRestore: isRestore,
                              productInfo: nil,
                              presentedOfferingIdentifier: nil,
                              observerMode: !self.finishTransactions,
                              subscriberAttributes: unsyncedAttributes) { maybeCustomerInfo, maybeError in
                self.handleReceiptPost(withCustomerInfo: maybeCustomerInfo,
                                       error: maybeError,
                                       subscriberAttributes: unsyncedAttributes,
                                       completion: maybeCompletion)
            }
        }
    }

    func handleReceiptPost(withCustomerInfo maybeCustomerInfo: CustomerInfo?,
                           error maybeError: Error?,
                           subscriberAttributes: SubscriberAttributeDict,
                           completion maybeCompletion: ((CustomerInfo?, Error?) -> Void)?) {
        operationDispatcher.dispatchOnMainThread {
            if let customerInfo = maybeCustomerInfo {
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: self.appUserID)
            }

            self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                    appUserID: self.appUserID,
                                    maybeError: maybeError)

            if let completion = maybeCompletion {
                self.operationDispatcher.dispatchOnMainThread {
                    completion(maybeCustomerInfo, maybeError)
                }
            }
        }
    }

    // Although both SK1Product.productIdentifier and SKPayment.productIdentifier
    // are supposed to be non-null, we've seen instances where this is not true.
    // so we cast into optionals in order to check nullability, and try to fall back if possible.
    func extractProductIdentifier(fromProduct product: SK1Product, orPayment payment: SKPayment) -> String? {
        if let identifierFromProduct = product.productIdentifier as String?,
           !identifierFromProduct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return identifierFromProduct
        }
        Logger.appleWarning(Strings.purchase.product_identifier_nil)

        if let identifierFromPayment = payment.productIdentifier as String?,
           !identifierFromPayment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return identifierFromPayment
        }
        Logger.appleWarning(Strings.purchase.payment_identifier_nil)

        return nil
    }

    func preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: String) {
        deviceCache.setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: appUserID)
        deviceCache.setOfferingsCacheTimestampToNow()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(sk2Package: Package) async -> Result<(CustomerInfo, Bool), Error> {
        guard let sk2ProductDetails = sk2Package.productDetails as? SK2ProductDetails else {
            // todo: use custom error
            return .failure(ErrorUtils.unexpectedBackendResponseError())
        }

        let sk2Product = sk2ProductDetails.underlyingSK2Product
        do {
            let result = try await sk2Product.purchase()
            let userCancelled = await storeKit2Listener.handle(purchaseResult: result)

            return await withCheckedContinuation { continuation in
                syncPurchases(receiptRefreshPolicy: .always, isRestore: false) { maybeCustomerInfo, maybeError in
                    if let error = maybeError {
                        continuation.resume(returning: .failure(error))
                        return
                    }
                    guard let customerInfo = maybeCustomerInfo else {
                        continuation.resume(returning: .failure(ErrorUtils.unexpectedBackendResponseError()))
                        return
                    }

                    continuation.resume(returning: .success((customerInfo, userCancelled)))
                }
            }
        } catch {
            return .failure(error)
        }
    }

    func purchase(sk1Package: Package, completion: @escaping PurchaseCompletedBlock) {
        guard let sk1ProductDetails = sk1Package.productDetails as? SK1ProductDetails else {
            return
        }
        let sk1Product = sk1ProductDetails.underlyingSK1Product
        let payment = storeKitWrapper.payment(withProduct: sk1Product)
        purchase(sk1Product: sk1Product,
                 payment: payment,
                 presentedOfferingIdentifier: sk1Package.offeringIdentifier,
                 completion: completion)
    }

}

// swiftlint:disable:this file_length
