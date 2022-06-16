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

    func readyForPromotedProduct(_ product: StoreProduct,
                                 purchase startPurchase: @escaping StartPurchaseBlock)

    @available(iOS 13.4, macCatalyst 13.4, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    var shouldShowPriceConsent: Bool { get }

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
    private var presentedOfferingIDsByProductID: Atomic<[String: String]> = .init([:])
    private var purchaseCompleteCallbacksByProductID: Atomic<[String: PurchaseCompletedBlock]> = .init([:])

    private var appUserID: String { self.currentUserProvider.currentAppUserID }
    private var unsyncedAttributes: SubscriberAttributeDict {
        self.attribution.unsyncedAttributesByKey(appUserID: self.appUserID)
    }

    private let productsManager: ProductsManager
    private let storeKitWrapper: StoreKitWrapper
    private let systemInfo: SystemInfo
    private let attribution: Attribution
    private let operationDispatcher: OperationDispatcher
    private let receiptFetcher: ReceiptFetcher
    private let customerInfoManager: CustomerInfoManager
    private let backend: Backend
    private let currentUserProvider: CurrentUserProvider
    private let transactionsManager: TransactionsManager
    private let deviceCache: DeviceCache
    private let manageSubscriptionsHelper: ManageSubscriptionsHelper
    private let beginRefundRequestHelper: BeginRefundRequestHelper

    // Can't have these properties with `@available`.
    // swiftlint:disable identifier_name
    var _storeKit2TransactionListener: Any?
    var _storeKit2StorefrontListener: Any?
    // swiftlint:enable identifier_name

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var storeKit2TransactionListener: StoreKit2TransactionListener {
        // swiftlint:disable:next force_cast
        return self._storeKit2TransactionListener! as! StoreKit2TransactionListener
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var storeKit2StorefrontListener: StoreKit2StorefrontListener {
        // swiftlint:disable:next force_cast
        return self._storeKit2StorefrontListener! as! StoreKit2StorefrontListener
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    convenience init(productsManager: ProductsManager,
                     storeKitWrapper: StoreKitWrapper,
                     systemInfo: SystemInfo,
                     subscriberAttributes: Attribution,
                     operationDispatcher: OperationDispatcher,
                     receiptFetcher: ReceiptFetcher,
                     customerInfoManager: CustomerInfoManager,
                     backend: Backend,
                     currentUserProvider: CurrentUserProvider,
                     transactionsManager: TransactionsManager,
                     deviceCache: DeviceCache,
                     manageSubscriptionsHelper: ManageSubscriptionsHelper,
                     beginRefundRequestHelper: BeginRefundRequestHelper,
                     storeKit2TransactionListener: StoreKit2TransactionListener,
                     storeKit2StorefrontListener: StoreKit2StorefrontListener
    ) {
        self.init(
            productsManager: productsManager,
            storeKitWrapper: storeKitWrapper,
            systemInfo: systemInfo,
            subscriberAttributes: subscriberAttributes,
            operationDispatcher: operationDispatcher,
            receiptFetcher: receiptFetcher,
            customerInfoManager: customerInfoManager,
            backend: backend,
            currentUserProvider: currentUserProvider,
            transactionsManager: transactionsManager,
            deviceCache: deviceCache,
            manageSubscriptionsHelper: manageSubscriptionsHelper,
            beginRefundRequestHelper: beginRefundRequestHelper
        )

        self._storeKit2TransactionListener = storeKit2TransactionListener
        self._storeKit2StorefrontListener = storeKit2StorefrontListener

        storeKit2TransactionListener.delegate = self
        storeKit2StorefrontListener.delegate = self

        if systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
            storeKit2TransactionListener.listenForTransactions()
            storeKit2StorefrontListener.listenForStorefrontChanges()
        }
    }

    init(productsManager: ProductsManager,
         storeKitWrapper: StoreKitWrapper,
         systemInfo: SystemInfo,
         subscriberAttributes: Attribution,
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
        self.attribution = subscriberAttributes
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.customerInfoManager = customerInfoManager
        self.backend = backend
        self.currentUserProvider = currentUserProvider
        self.transactionsManager = transactionsManager
        self.deviceCache = deviceCache
        self.manageSubscriptionsHelper = manageSubscriptionsHelper
        self.beginRefundRequestHelper = beginRefundRequestHelper
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
                    .mapError { $0.asPurchasesError }

                completion(result)
            }
        }
    }

    func purchase(product: StoreProduct,
                  package: Package?,
                  completion: @escaping PurchaseCompletedBlock) {
        Self.logPurchase(product: product, package: package)

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
        Self.logPurchase(product: product, package: package)

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
        guard let productIdentifier = sk1Product.extractProductIdentifier(withPayment: payment) else {
            Logger.error(Strings.purchase.could_not_purchase_product_id_not_found)
            let errorMessage = "There was a problem purchasing the product: productIdentifier was nil"
            completion(nil, nil, ErrorUtils.unknownError(message: errorMessage), false)
            return
        }

        if !self.finishTransactions {
            Logger.warn(Strings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning)
        }

        payment.applicationUsername = self.appUserID
        self.preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: self.appUserID)

        if let presentedOfferingIdentifier = package?.offeringIdentifier {
            self.presentedOfferingIDsByProductID.modify { $0[productIdentifier] = presentedOfferingIdentifier }

        }

        self.productsManager.cacheProduct(sk1Product)

        let addPayment: Bool = self.addPurchaseCompletedCallback(
            productIdentifier: productIdentifier,
            completion: { transaction, customerInfo, error, cancelled in
                if !cancelled {
                    if let error = error {
                        Logger.rcPurchaseError(Strings.purchase.product_purchase_failed(
                            productIdentifier: productIdentifier,
                            error: error
                        ))
                    } else {
                        Logger.rcPurchaseSuccess(Strings.purchase.purchased_product(
                            productIdentifier: productIdentifier
                        ))
                    }
                }

                completion(transaction, customerInfo, error, cancelled)
            }
        )

        if addPayment {
            self.storeKitWrapper.add(payment)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(sk2Product product: SK2Product,
                  promotionalOffer: PromotionalOffer?,
                  completion: @escaping PurchaseCompletedBlock) {
        _ = Task<Void, Never> {
            do {
                let result: PurchaseResultData = try await self.purchase(sk2Product: product,
                                                                         promotionalOffer: promotionalOffer)

                Logger.rcPurchaseSuccess(Strings.purchase.purchased_product(
                    productIdentifier: product.id
                ))

                DispatchQueue.main.async {
                    completion(result.0, result.1, nil, result.2)
                }
            } catch let error {
                Logger.rcPurchaseError(Strings.purchase.product_purchase_failed(
                    productIdentifier: product.id,
                    error: error
                ))

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
            options.insert(signedData.sk2PurchaseOption)
        }

        let result: Product.PurchaseResult

        do {
            result = try await sk2Product.purchase(options: options)
        } catch StoreKitError.userCancelled {
            return (
                transaction: nil,
                customerInfo: try await self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                                              fetchPolicy: .cachedOrFetched),
                userCancelled: true
            )
        } catch {
            throw ErrorUtils.purchasesError(withStoreKitError: error)
        }

        // `userCancelled` above comes from `StoreKitError.userCancelled`.
        // This detects if `Product.PurchaseResult.userCancelled` is true.
        let (userCancelled, sk2Transaction) = try await self.storeKit2TransactionListener
            .handle(purchaseResult: result)
        let transaction = sk2Transaction.map(StoreTransaction.init(sk2Transaction:))
        let customerInfo: CustomerInfo

        if let transaction = transaction {
            customerInfo = try await self.handlePurchasedTransaction(transaction)
        } else {
            // `transaction` would be `nil` for `Product.PurchaseResult.pending` and
            // `Product.PurchaseResult.userCancelled`.
            customerInfo = try await self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                                           fetchPolicy: .cachedOrFetched)
        }

        return (transaction, customerInfo, userCancelled)
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
        let storeTransaction = StoreTransaction(sk1Transaction: transaction)

        switch transaction.transactionState {
        case .restored, // for observer mode
             .purchased:
            self.handlePurchasedTransaction(storeTransaction, storefront: storeKitWrapper.currentStorefront)
        case .purchasing:
            break
        case .failed:
            self.handleFailedTransaction(transaction)
        case .deferred:
            self.handleDeferredTransaction(transaction)
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
        delegate.readyForPromotedProduct(storeProduct) { completion in
            self.purchaseCompleteCallbacksByProductID.modify { $0[product.productIdentifier] = completion }
            storeKitWrapper.add(payment)
        }
        return false
    }

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(Strings.purchase.entitlements_revoked_syncing_purchases(productIdentifiers: productIdentifiers))
        syncPurchases { _ in
            Logger.debug(Strings.purchase.purchases_synced)
        }
    }

    @available(iOS 13.4, macCatalyst 13.4, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    var storeKitWrapperShouldShowPriceConsent: Bool {
        return delegate?.shouldShowPriceConsent ?? true
    }

    func storeKitWrapperDidChangeStorefront(_ storeKitWrapper: StoreKitWrapper) {
        handleStorefrontChange()
    }

}

// MARK: Transaction state updates.
private extension PurchasesOrchestrator {

    func handlePurchasedTransaction(_ transaction: StoreTransaction,
                                    storefront: StorefrontType?) {
        self.receiptFetcher.receiptData(refreshPolicy: .always) { receiptData in
            if let receiptData = receiptData,
               !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(withTransaction: transaction,
                                                 receiptData: receiptData,
                                                 storefront: storefront)
            } else {
                self.handleReceiptPost(withTransaction: transaction,
                                       result: .failure(.missingReceiptFile()),
                                       subscriberAttributes: nil)
            }
        }
    }

    func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        let storeTransaction = StoreTransaction(sk1Transaction: transaction)

        if let error = transaction.error,
           let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: storeTransaction) {
            let purchasesError = ErrorUtils.purchasesError(withSKError: error)
            operationDispatcher.dispatchOnMainThread {
                completion(storeTransaction,
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
        let userCancelled = transaction.error?.isCancelledError ?? false
        let storeTransaction = StoreTransaction(sk1Transaction: transaction)

        guard let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: storeTransaction) else {
            return
        }

        operationDispatcher.dispatchOnMainThread {
            completion(
                storeTransaction,
                nil,
                ErrorUtils.paymentDeferredError(),
                userCancelled
            )
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesOrchestrator: StoreKit2TransactionListenerDelegate {

    func transactionsUpdated() async throws {
        // Need to restore if using observer mode (which is inverse of finishTransactions)
        let isRestore = !systemInfo.finishTransactions

        _ = try await syncPurchases(receiptRefreshPolicy: .always, isRestore: isRestore)
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesOrchestrator: StoreKit2StorefrontListenerDelegate {

    func storefrontDidUpdate() {
        handleStorefrontChange()
    }

}

// MARK: Private funcs

private extension PurchasesOrchestrator {

    /// - Returns: whether the callback was added
    @discardableResult
    func addPurchaseCompletedCallback(
        productIdentifier: String,
        completion: @escaping PurchaseCompletedBlock
    ) -> Bool {
        return self.purchaseCompleteCallbacksByProductID.modify { callbacks in
            guard callbacks[productIdentifier] == nil else {
                completion(nil, nil, ErrorUtils.operationAlreadyInProgressError(), false)
                return false
            }

            callbacks[productIdentifier] = completion
            return true
        }
    }

    func getAndRemovePurchaseCompletedCallback(
        forTransaction transaction: StoreTransaction
    ) -> PurchaseCompletedBlock? {
        return self.purchaseCompleteCallbacksByProductID.modify {
            $0.removeValue(forKey: transaction.productIdentifier)
        }
    }

    func fetchProductsAndPostReceipt(
        withTransaction transaction: StoreTransaction,
        receiptData: Data,
        storefront: StorefrontType?
    ) {
        if let productIdentifier = transaction.productIdentifier.notEmpty {
            self.products(withIdentifiers: [productIdentifier]) { products in
                self.postReceipt(withTransaction: transaction,
                                 receiptData: receiptData,
                                 products: Set(products),
                                 storefront: storefront)
            }
        } else {
            self.handleReceiptPost(withTransaction: transaction,
                                   result: .failure(.missingTransactionProductIdentifier()),
                                   subscriberAttributes: nil)

        }
    }

    func postReceipt(withTransaction transaction: StoreTransaction,
                     receiptData: Data,
                     products: Set<StoreProduct>,
                     storefront: StorefrontType?) {
        var productData: ProductRequestData?
        var presentedOfferingID: String?
        if let product = products.first {
            let receivedProductData = ProductRequestData(with: product, storefront: storefront)
            productData = receivedProductData

            let productID = receivedProductData.productIdentifier
            let foundPresentedOfferingID = self.presentedOfferingIDsByProductID.value[productID]
            presentedOfferingID = foundPresentedOfferingID

            self.presentedOfferingIDsByProductID.modify { $0.removeValue(forKey: productID) }
        }
        let unsyncedAttributes = self.unsyncedAttributes

        self.backend.post(receiptData: receiptData,
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

    func handleReceiptPost(withTransaction transaction: StoreTransaction,
                           result: Result<CustomerInfo, BackendError>,
                           subscriberAttributes: SubscriberAttributeDict?) {
        func finishTransactionIfNeeded() {
            if self.finishTransactions, let sk1Transaction = transaction.sk1Transaction {
                self.storeKitWrapper.finishTransaction(sk1Transaction)
            }
        }

        self.operationDispatcher.dispatchOnMainThread {
            let appUserID = self.appUserID
            self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                    appUserID: appUserID,
                                    error: result.error)

            let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: transaction)
            let error = result.error
            let finishable = error?.finishable ?? false

            switch result {
            case let .success(customerInfo):
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: appUserID)
                completion?(transaction, customerInfo, nil, false)

                finishTransactionIfNeeded()

            case let .failure(error):
                let purchasesError = error.asPurchasesError

                completion?(transaction, nil, purchasesError, false)

                if finishable {
                    finishTransactionIfNeeded()
                }
            }
        }
    }

    func markSyncedIfNeeded(subscriberAttributes: SubscriberAttributeDict?, appUserID: String, error: BackendError?) {
        if let error = error {
            guard error.successfullySynced else { return }

            Logger.error(Strings.attribution.subscriber_attributes_error(
                errors: (error as NSError).subscriberAttributesErrors)
            )
        }

        self.attribution.markAttributesAsSynced(subscriberAttributes, appUserID: appUserID)
    }

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       completion: ((Result<CustomerInfo, Error>) -> Void)?) {
        if !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.restore.restorepurchases_called_with_allow_sharing_appstore_account_false_warning)
        }

        let currentAppUserID = self.appUserID
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

    func handleReceiptPost(result: Result<CustomerInfo, BackendError>,
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
                    completion(result.mapError { $0.asPurchasesError })
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

    func handleStorefrontChange() {
        self.productsManager.clearCachedProducts()
        self.deviceCache.clearCachedOfferings()
    }

}

private extension PurchasesOrchestrator {

    static func logPurchase(product: StoreProduct, package: Package?) {
        if let package = package {
            Logger.purchase(
                Strings.purchase.purchasing_product_from_package(
                    productIdentifier: product.productIdentifier,
                    offeringIdentifier: package.offeringIdentifier
                )
            )
        } else {
            Logger.purchase(Strings.purchase.purchasing_product(productIdentifier: product.productIdentifier))
        }
    }

}

private extension Error {

    var isCancelledError: Bool {
        switch self {
        case let error as ErrorCode:
            switch error {
            case .purchaseCancelledError: return true
            default: return false
            }

        case let error as NSError:
            switch (error.domain, error.code) {
            case (SKErrorDomain, SKError.paymentCancelled.rawValue): return true
            default: return false
            }

        default: return false
        }
    }

}

// MARK: - Async extensions

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension PurchasesOrchestrator {

    private func handlePurchasedTransaction(_ transaction: StoreTransaction) async throws -> CustomerInfo {
        let storefront = await Storefront.currentStorefront

        return try await withCheckedThrowingContinuation { continuation in
            self.addPurchaseCompletedCallback(
                productIdentifier: transaction.productIdentifier,
                completion: { _, customerInfo, error, _ in
                    continuation.resume(with: Result(customerInfo, error))
                }
            )

            self.handlePurchasedTransaction(transaction, storefront: storefront)
        }
    }

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool) async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            syncPurchases(receiptRefreshPolicy: receiptRefreshPolicy, isRestore: isRestore) { result in
                continuation.resume(with: result)
            }
        }
    }

}
