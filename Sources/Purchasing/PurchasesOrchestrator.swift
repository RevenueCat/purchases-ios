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

    func shouldPurchasePromoProduct(_ product: StoreProduct,
                                    defermentBlock: @escaping DeferredPromotionalPurchaseBlock)

}

// swiftlint:disable file_length type_body_length
class PurchasesOrchestrator {

    var finishTransactions: Bool { systemInfo.finishTransactions }
    var allowSharingAppStoreAccount: Bool {
        get {
            return _allowSharingAppStoreAccount ?? self.currentUserProvider.currentUserIsAnonymous
        }
        set {
            _allowSharingAppStoreAccount = newValue
        }
    }

    @objc weak var delegate: PurchasesOrchestratorDelegate?

    private var _allowSharingAppStoreAccount: Bool?
    private var presentedOfferingIDsByProductID: [String: String] = [:]
    private var purchaseCompleteCallbacksByProductID: [String: PurchaseCompletedBlock] = [:]

    private var appUserID: String { self.currentUserProvider.currentAppUserID }
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
    private let currentUserProvider: CurrentUserProvider
    private let transactionsManager: TransactionsManager
    private let deviceCache: DeviceCache
    private let manageSubscriptionsHelper: ManageSubscriptionsHelper
    private let beginRefundRequestHelper: BeginRefundRequestHelper
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
         currentUserProvider: CurrentUserProvider,
         transactionsManager: TransactionsManager,
         deviceCache: DeviceCache,
         manageSubscriptionsHelper: ManageSubscriptionsHelper,
         beginRefundRequestHelper: BeginRefundRequestHelper) {
        self.productsManager = productsManager
        self.storeKitWrapper = storeKitWrapper
        self.systemInfo = systemInfo
        self.subscriberAttributesManager = subscriberAttributesManager
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.customerInfoManager = customerInfoManager
        self.backend = backend
        self.currentUserProvider = currentUserProvider
        self.transactionsManager = transactionsManager
        self.deviceCache = deviceCache
        self.manageSubscriptionsHelper = manageSubscriptionsHelper
        self.beginRefundRequestHelper = beginRefundRequestHelper

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            storeKit2Listener.listenForTransactions()
        }
    }

    func restorePurchases(completion: ((Result<CustomerInfo, Error>) -> Void)?) {
        syncPurchases(receiptRefreshPolicy: .always, isRestore: true, completion: completion)
    }

    func syncPurchases(completion: ((Result<CustomerInfo, Error>) -> Void)? = nil) {
        syncPurchases(receiptRefreshPolicy: .never,
                      isRestore: allowSharingAppStoreAccount,
                      completion: completion)
    }

    func products(withIdentifiers identifiers: [String], completion: @escaping ([StoreProduct]) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        productsManager.products(withIdentifiers: productIdentifiersSet) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(Array(products.value ?? []))
            }
        }
    }

    func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: [String],
                                            completion: @escaping ([StoreProduct]) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        productsManager.products(withIdentifiers: productIdentifiersSet) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(Array(products.value ?? []))
            }
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func promotionalOffer(forProductDiscount productDiscount: StoreProductDiscountType,
                          product: StoreProductType,
                          completion: @escaping (Result<PromotionalOffer, Error>) -> Void) {
        guard let discountIdentifier = productDiscount.offerIdentifier else {
            completion(.failure(ErrorUtils.productDiscountMissingIdentifierError()))
            return
        }

        guard let subscriptionGroupIdentifier = product.subscriptionGroupIdentifier else {
            completion(.failure(ErrorUtils.productDiscountMissingSubscriptionGroupIdentifierError()))
            return
        }

        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { receiptData in
            guard let receiptData = receiptData,
                  !receiptData.isEmpty else {
                completion(.failure(ErrorUtils.missingReceiptFileError()))
                return
            }

            self.backend.post(
                offerIdForSigning: discountIdentifier,
                productIdentifier: product.productIdentifier,
                subscriptionGroup: subscriptionGroupIdentifier,
                receiptData: receiptData,
                appUserID: self.appUserID
            ) { result in
                let result: Result<PromotionalOffer, Error> = result
                    .map { data in
                        let signedData = PromotionalOffer.SignedData(identifier: discountIdentifier,
                                                                     keyIdentifier: data.keyIdentifier,
                                                                     nonce: data.nonce,
                                                                     signature: data.signature,
                                                                     timestamp: data.timestamp)

                        return .init(discount: productDiscount, signedData: signedData)
                    }

                completion(result)
            }
        }
    }

    func purchase(product: StoreProduct,
                  package: Package?,
                  completion: @escaping PurchaseCompletedBlock) {
        if let sk1Product = product.sk1Product {
            let payment = storeKitWrapper.payment(withProduct: sk1Product)

            purchase(sk1Product: sk1Product,
                     payment: payment,
                     package: package,
                     completion: completion)
        } else if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
                  let sk2Product = product.sk2Product {
            purchase(sk2Product: sk2Product,
                     promotionalOffer: nil,
                     completion: completion)
        } else {
            fatalError("Unrecognized product: \(product)")
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func purchase(product: StoreProduct,
                  package: Package?,
                  promotionalOffer: PromotionalOffer,
                  completion: @escaping PurchaseCompletedBlock) {
        if let sk1Product = product.sk1Product {
            purchase(sk1Product: sk1Product,
                     promotionalOffer: promotionalOffer,
                     package: package,
                     completion: completion)
        } else if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
                  let sk2Product = product.sk2Product {
            purchase(sk2Product: sk2Product,
                     promotionalOffer: promotionalOffer,
                     completion: completion)
        } else {
            fatalError("Unrecognized product: \(product)")
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func purchase(sk1Product: SK1Product,
                  promotionalOffer: PromotionalOffer,
                  package: Package?,
                  completion: @escaping PurchaseCompletedBlock) {
        let discount = promotionalOffer.signedData.sk1PromotionalOffer
        let payment = self.storeKitWrapper.payment(withProduct: sk1Product, discount: discount)
        self.purchase(sk1Product: sk1Product,
                      payment: payment,
                      package: package,
                      completion: completion)
    }

    func purchase(sk1Product: SK1Product,
                  payment: SKMutablePayment,
                  package: Package?,
                  completion: @escaping PurchaseCompletedBlock) {
        Logger.debug(String(format: "Make purchase called: %@", #function))
        guard let productIdentifier = sk1Product.extractProductIdentifier(withPayment: payment) else {
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

        if let presentedOfferingIdentifier = package?.offeringIdentifier {
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

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(sk2Product product: SK2Product,
                  promotionalOffer: PromotionalOffer?,
                  completion: @escaping PurchaseCompletedBlock) {
        _ = Task<Void, Never> {
            do {
                let result: PurchaseResultData = try await self.purchase(sk2Product: product,
                                                                         promotionalOffer: promotionalOffer)

                DispatchQueue.main.async {
                    completion(result.0, result.1, nil, result.2)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(nil, nil, error, false)
                }
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(
        sk2Product: SK2Product,
        promotionalOffer: PromotionalOffer?
    ) async throws -> PurchaseResultData {
        var options: Set<Product.PurchaseOption> = [
            .simulatesAskToBuyInSandbox(Purchases.simulatesAskToBuyInSandbox)
        ]

        if let signedData = promotionalOffer?.signedData {
            Logger.debug(Strings.storeKit.sk2_purchasing_added_promotional_offer_option(signedData.identifier))
            options.insert(try signedData.sk2PurchaseOption)
        }

        let result: Product.PurchaseResult

        do {
            result = try await sk2Product.purchase(options: options)
        } catch {
            throw ErrorUtils.purchasesError(withStoreKitError: error)
        }

        let (userCancelled, transaction) = try await storeKit2Listener.handle(purchaseResult: result)

        return try await withCheckedThrowingContinuation { continuation in
            syncPurchases(receiptRefreshPolicy: .always, isRestore: false) { result in
                continuation.resume(
                    with: result
                        .map { customerInfo in
                            (transaction.map(StoreTransaction.init(sk2Transaction:)),
                             customerInfo,
                             userCancelled)
                        }
                )
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func promotionalOffer(
        forProductDiscount discount: StoreProductDiscountType,
        product: StoreProductType
    ) async throws -> PromotionalOffer {
        return try await withCheckedThrowingContinuation { continuation in
            self.promotionalOffer(forProductDiscount: discount,
                                  product: product) { result in
                continuation.resume(with: result)
            }
        }
    }

#if os(iOS) || os(macOS)

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscription(completion: @escaping (Error?) -> Void) {
        self.manageSubscriptionsHelper.showManageSubscriptions { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success:
                completion(nil)
            }
        }
    }
#endif

#if os(iOS)

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        return try await beginRefundRequestHelper.beginRefundRequest(forProduct: productID)
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequestForActiveEntitlement() async throws -> RefundRequestStatus {
        return try await beginRefundRequestHelper.beginRefundRequestForActiveEntitlement()
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(forEntitlement entitlementID: String) async throws -> RefundRequestStatus {
        return try await beginRefundRequestHelper.beginRefundRequest(forEntitlement: entitlementID)
    }

#endif

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
        guard let delegate = delegate else { return false }

        let storeProduct = StoreProduct(sk1Product: product)
        lock.lock()
        delegate.shouldPurchasePromoProduct(storeProduct) { completion in
            self.purchaseCompleteCallbacksByProductID[product.productIdentifier] = completion
            storeKitWrapper.add(payment)
        }
        lock.unlock()
        return false
    }

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(Strings.purchase.entitlements_revoked_syncing_purchases(productIdentifiers: productIdentifiers))
        syncPurchases { _ in
            Logger.debug(Strings.purchase.purchases_synced)
        }
    }

}

// MARK: Transaction state updates.
private extension PurchasesOrchestrator {

    func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { receiptData in
            if let receiptData = receiptData,
               !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(withTransaction: transaction, receiptData: receiptData)
            } else {
                self.handleReceiptPost(withTransaction: transaction,
                                       result: .failure(ErrorUtils.missingReceiptFileError()),
                                       subscriberAttributes: nil)
            }
        }
    }

    func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error,
           let completion = getAndRemovePurchaseCompletedCallback(forTransaction: transaction) {
            let purchasesError = ErrorUtils.purchasesError(withSKError: error)
            operationDispatcher.dispatchOnMainThread {
                completion(StoreTransaction(sk1Transaction: transaction),
                           nil,
                           purchasesError,
                           purchasesError.isCancelledError)
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
            completion(
                StoreTransaction(sk1Transaction: transaction),
                nil,
                ErrorUtils.paymentDeferredError(), userCancelled
            )
        }
    }

}

extension PurchasesOrchestrator: StoreKit2TransactionListenerDelegate {

    func transactionsUpdated() {
        // Need to restore if using observer mode (which is inverse of finishTransactions)
        let isRestore = !systemInfo.finishTransactions
        syncPurchases(receiptRefreshPolicy: .always, isRestore: isRestore, completion: nil)
    }

}

// MARK: Private funcs.
private extension PurchasesOrchestrator {

    func getAndRemovePurchaseCompletedCallback(
        forTransaction transaction: SKPaymentTransaction
    ) -> PurchaseCompletedBlock? {
        guard let productIdentifier = transaction.productIdentifier else {
            return nil
        }

        lock.lock()
        let completion = purchaseCompleteCallbacksByProductID.removeValue(forKey: productIdentifier)
        lock.unlock()
        return completion
    }

    func fetchProductsAndPostReceipt(withTransaction transaction: SKPaymentTransaction, receiptData: Data) {
        if let productIdentifier = transaction.productIdentifier {
            self.products(withIdentifiers: [productIdentifier]) { products in
                self.postReceipt(withTransaction: transaction,
                                 receiptData: receiptData,
                                 products: Set(products))
            }
        } else {
            self.handleReceiptPost(withTransaction: transaction,
                                   result: .failure(ErrorUtils.unknownError()),
                                   subscriberAttributes: nil)

        }
    }

    func postReceipt(withTransaction transaction: SKPaymentTransaction,
                     receiptData: Data,
                     products: Set<StoreProduct>) {
        var productData: ProductRequestData?
        var presentedOfferingID: String?
        if let product = products.first {
            let receivedProductData = ProductRequestData(with: product)
            productData = receivedProductData

            let productID = receivedProductData.productIdentifier
            let foundPresentedOfferingID = presentedOfferingIDsByProductID[productID]
            presentedOfferingID = foundPresentedOfferingID

            presentedOfferingIDsByProductID.removeValue(forKey: productID)
        }
        let unsyncedAttributes = unsyncedAttributes

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: allowSharingAppStoreAccount,
                     productData: productData,
                     presentedOfferingIdentifier: presentedOfferingID,
                     observerMode: !finishTransactions,
                     subscriberAttributes: unsyncedAttributes) { result in
            self.handleReceiptPost(withTransaction: transaction,
                                   result: result,
                                   subscriberAttributes: unsyncedAttributes)
        }
    }

    func handleReceiptPost(withTransaction transaction: SKPaymentTransaction,
                           result: Result<CustomerInfo, Error>,
                           subscriberAttributes: SubscriberAttributeDict?) {
        operationDispatcher.dispatchOnMainThread {
            let appUserID = self.appUserID
            self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                    appUserID: appUserID,
                                    error: result.error)

            let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: transaction)
            let error = result.error
            let nsError = error as NSError?
            let finishable = (nsError?.userInfo[ErrorDetails.finishableKey as String] as? NSNumber)?.boolValue ?? false

            let storeTransaction = StoreTransaction(sk1Transaction: transaction)

            if let customerInfo = result.value {
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: appUserID)
                completion?(storeTransaction, customerInfo, nil, false)

                if self.finishTransactions {
                    self.storeKitWrapper.finishTransaction(transaction)
                }
            } else if finishable {
                completion?(storeTransaction, nil, error, false)
                if self.finishTransactions {
                    self.storeKitWrapper.finishTransaction(transaction)
                }
            } else {
                Logger.error(Strings.receipt.unknown_backend_error)
                completion?(storeTransaction, nil, error, false)
            }
        }
    }

    func markSyncedIfNeeded(subscriberAttributes: SubscriberAttributeDict?, appUserID: String, error: Error?) {
        if let error = error as NSError? {
            if !error.successfullySynced {
                return
            }
            Logger.error(Strings.attribution.subscriber_attributes_error(errors: error.subscriberAttributesErrors))
        }

        subscriberAttributesManager.markAttributesAsSynced(subscriberAttributes, appUserID: appUserID)
    }

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       completion: ((Result<CustomerInfo, Error>) -> Void)?) {
        if !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.restore.restorepurchases_called_with_allow_sharing_appstore_account_false_warning)
        }

        let currentAppUserID = appUserID
        let unsyncedAttributes = unsyncedAttributes
        // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
        // https://rev.cat/apple-restoring-purchased-products
        receiptFetcher.receiptData(refreshPolicy: receiptRefreshPolicy) { receiptData in
            guard let receiptData = receiptData,
                  !receiptData.isEmpty else {
                      if self.systemInfo.isSandbox {
                          Logger.appleWarning(Strings.receipt.no_sandbox_receipt_restore)
                      }

                      if let completion = completion {
                          self.operationDispatcher.dispatchOnMainThread {
                              completion(.failure(ErrorUtils.missingReceiptFileError()))
                          }
                      }
                      return
                  }

            self.transactionsManager.customerHasTransactions(receiptData: receiptData) { hasTransactions in
                let cachedCustomerInfo = self.customerInfoManager.cachedCustomerInfo(appUserID: currentAppUserID)
                let hasOriginalPurchaseDate = cachedCustomerInfo?.originalPurchaseDate != nil

                if !hasTransactions && hasOriginalPurchaseDate {
                    if let completion = completion {
                        self.operationDispatcher.dispatchOnMainThread {
                            completion(
                                Result(cachedCustomerInfo,
                                       ErrorUtils.customerInfoError(withMessage: "No cached customer info"))
                            )
                        }
                    }
                    return
                }

                self.backend.post(receiptData: receiptData,
                                  appUserID: currentAppUserID,
                                  isRestore: isRestore,
                                  productData: nil,
                                  presentedOfferingIdentifier: nil,
                                  observerMode: !self.finishTransactions,
                                  subscriberAttributes: unsyncedAttributes) { result in
                    self.handleReceiptPost(result: result,
                                           subscriberAttributes: unsyncedAttributes,
                                           completion: completion)
                }
            }
        }
    }

    func handleReceiptPost(result: Result<CustomerInfo, Error>,
                           subscriberAttributes: SubscriberAttributeDict,
                           completion: ((Result<CustomerInfo, Error>) -> Void)?) {
        operationDispatcher.dispatchOnMainThread {
            if let customerInfo = result.value {
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: self.appUserID)
            }

            self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                    appUserID: self.appUserID,
                                    error: result.error)

            if let completion = completion {
                self.operationDispatcher.dispatchOnMainThread {
                    completion(result)
                }
            }
        }
    }

    func preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: String) {
        deviceCache.setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: appUserID)
        deviceCache.setOfferingsCacheTimestampToNow()
    }

    func purchase(sk1Product: SK1Product, package: Package, completion: @escaping PurchaseCompletedBlock) {
        let payment = storeKitWrapper.payment(withProduct: sk1Product)
        purchase(sk1Product: sk1Product,
                 payment: payment,
                 package: package,
                 completion: completion)
    }

}

private extension Error {

    var isCancelledError: Bool {
        return (self as? ErrorCode) == .purchaseCancelledError
    }

}
