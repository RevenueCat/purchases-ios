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
final class PurchasesOrchestrator {

    var finishTransactions: Bool { self.systemInfo.finishTransactions }
    var observerMode: Bool { self.systemInfo.observerMode }

    var allowSharingAppStoreAccount: Bool {
        get { self._allowSharingAppStoreAccount.value ?? self.currentUserProvider.currentUserIsAnonymous }
        set { self._allowSharingAppStoreAccount.value = newValue }
    }

    /// - Note: this is not thread-safe
    @objc weak var delegate: PurchasesOrchestratorDelegate?

    private let _allowSharingAppStoreAccount: Atomic<Bool?> = nil
    private let presentedOfferingIDsByProductID: Atomic<[String: String]> = .init([:])
    private let purchaseCompleteCallbacksByProductID: Atomic<[String: PurchaseCompletedBlock]> = .init([:])

    private var appUserID: String { self.currentUserProvider.currentAppUserID }
    private var unsyncedAttributes: SubscriberAttribute.Dictionary {
        self.attribution.unsyncedAttributesByKey(appUserID: self.appUserID)
    }

    static let receiptRetryCount: Int = 3
    static let receiptRetrySleepDuration: DispatchTimeInterval = .seconds(5)

    private let productsManager: ProductsManagerType
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let attribution: Attribution
    private let operationDispatcher: OperationDispatcher
    private let receiptFetcher: ReceiptFetcher
    private let receiptParser: PurchasesReceiptParser
    private let customerInfoManager: CustomerInfoManager
    private let backend: Backend
    private let currentUserProvider: CurrentUserProvider
    private let transactionsManager: TransactionsManager
    private let deviceCache: DeviceCache
    private let offeringsManager: OfferingsManager
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
    convenience init(productsManager: ProductsManagerType,
                     paymentQueueWrapper: EitherPaymentQueueWrapper,
                     systemInfo: SystemInfo,
                     subscriberAttributes: Attribution,
                     operationDispatcher: OperationDispatcher,
                     receiptFetcher: ReceiptFetcher,
                     receiptParser: PurchasesReceiptParser,
                     customerInfoManager: CustomerInfoManager,
                     backend: Backend,
                     currentUserProvider: CurrentUserProvider,
                     transactionsManager: TransactionsManager,
                     deviceCache: DeviceCache,
                     offeringsManager: OfferingsManager,
                     manageSubscriptionsHelper: ManageSubscriptionsHelper,
                     beginRefundRequestHelper: BeginRefundRequestHelper,
                     storeKit2TransactionListener: StoreKit2TransactionListener,
                     storeKit2StorefrontListener: StoreKit2StorefrontListener
    ) {
        self.init(
            productsManager: productsManager,
            paymentQueueWrapper: paymentQueueWrapper,
            systemInfo: systemInfo,
            subscriberAttributes: subscriberAttributes,
            operationDispatcher: operationDispatcher,
            receiptFetcher: receiptFetcher,
            receiptParser: receiptParser,
            customerInfoManager: customerInfoManager,
            backend: backend,
            currentUserProvider: currentUserProvider,
            transactionsManager: transactionsManager,
            deviceCache: deviceCache,
            offeringsManager: offeringsManager,
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

    init(productsManager: ProductsManagerType,
         paymentQueueWrapper: EitherPaymentQueueWrapper,
         systemInfo: SystemInfo,
         subscriberAttributes: Attribution,
         operationDispatcher: OperationDispatcher,
         receiptFetcher: ReceiptFetcher,
         receiptParser: PurchasesReceiptParser,
         customerInfoManager: CustomerInfoManager,
         backend: Backend,
         currentUserProvider: CurrentUserProvider,
         transactionsManager: TransactionsManager,
         deviceCache: DeviceCache,
         offeringsManager: OfferingsManager,
         manageSubscriptionsHelper: ManageSubscriptionsHelper,
         beginRefundRequestHelper: BeginRefundRequestHelper) {
        self.productsManager = productsManager
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.attribution = subscriberAttributes
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.receiptParser = receiptParser
        self.customerInfoManager = customerInfoManager
        self.backend = backend
        self.currentUserProvider = currentUserProvider
        self.transactionsManager = transactionsManager
        self.deviceCache = deviceCache
        self.offeringsManager = offeringsManager
        self.manageSubscriptionsHelper = manageSubscriptionsHelper
        self.beginRefundRequestHelper = beginRefundRequestHelper
    }

    func restorePurchases(completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        self.syncPurchases(receiptRefreshPolicy: .always,
                           isRestore: true,
                           initiationSource: .restore,
                           completion: completion)
    }

    func syncPurchases(completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)? = nil) {
        self.syncPurchases(receiptRefreshPolicy: .never,
                           isRestore: allowSharingAppStoreAccount,
                           initiationSource: .restore,
                           completion: completion)
    }

    func products(withIdentifiers identifiers: [String], completion: @escaping ([StoreProduct]) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        self.productsManager.products(withIdentifiers: productIdentifiersSet) { products in
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
                          completion: @escaping (Result<PromotionalOffer, PurchasesError>) -> Void) {
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

            self.backend.offerings.post(offerIdForSigning: discountIdentifier,
                                        productIdentifier: product.productIdentifier,
                                        subscriptionGroup: subscriptionGroupIdentifier,
                                        receiptData: receiptData,
                                        appUserID: self.appUserID) { result in
                let result: Result<PromotionalOffer, PurchasesError> = result
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
            guard let storeKit1Wrapper = self.storeKit1Wrapper(orFailWith: completion) else { return }

            let payment = storeKit1Wrapper.payment(with: sk1Product)

            self.purchase(sk1Product: sk1Product,
                          payment: payment,
                          package: package,
                          wrapper: storeKit1Wrapper,
                          completion: completion)
        } else if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
                  let sk2Product = product.sk2Product {
            self.purchase(sk2Product: sk2Product,
                          package: package,
                          promotionalOffer: nil,
                          completion: completion)
        } else {
            fatalError("Unrecognized product: \(product)")
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func purchase(product: StoreProduct,
                  package: Package?,
                  promotionalOffer: PromotionalOffer.SignedData,
                  completion: @escaping PurchaseCompletedBlock) {
        Self.logPurchase(product: product, package: package, offer: promotionalOffer)

        if let sk1Product = product.sk1Product {
            guard let storeKit1Wrapper = self.storeKit1Wrapper(orFailWith: completion) else { return }

            self.purchase(sk1Product: sk1Product,
                          promotionalOffer: promotionalOffer,
                          package: package,
                          wrapper: storeKit1Wrapper,
                          completion: completion)
        } else if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
                  let sk2Product = product.sk2Product {
            self.purchase(sk2Product: sk2Product,
                          package: package,
                          promotionalOffer: promotionalOffer,
                          completion: completion)
        } else {
            fatalError("Unrecognized product: \(product)")
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func purchase(sk1Product: SK1Product,
                  promotionalOffer: PromotionalOffer.SignedData,
                  package: Package?,
                  wrapper: StoreKit1Wrapper,
                  completion: @escaping PurchaseCompletedBlock) {
        let discount = promotionalOffer.sk1PromotionalOffer
        let payment = wrapper.payment(with: sk1Product, discount: discount)
        self.purchase(sk1Product: sk1Product,
                      payment: payment,
                      package: package,
                      wrapper: wrapper,
                      completion: completion)
    }

    func purchase(sk1Product: SK1Product,
                  payment: SKMutablePayment,
                  package: Package?,
                  wrapper: StoreKit1Wrapper,
                  completion: @escaping PurchaseCompletedBlock) {
        /**
         * Note: this only extracts the product identifier from `SKPayment`, ignoring the `SK1Product.identifier`
         * because `storeKit1Wrapper(_:, updatedTransaction:)` only has a transaction and not the product.
         * If the transaction is mising a product id, then we wouldn't be able to find the callback
         * in `purchaseCompleteCallbacksByProductID`, and therefore
         * we wouldn't be able to notify of the purchase result.
         */

        guard let productIdentifier = payment.extractProductIdentifier() else {
            self.operationDispatcher.dispatchOnMainActor {
                completion(
                    nil,
                    nil,
                    ErrorUtils.storeProblemError(
                        withMessage: Strings.purchase.could_not_purchase_product_id_not_found.description
                    ).asPublicError,
                    false
                )
            }
            return
        }

        if !self.finishTransactions {
            Logger.warn(Strings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning)
        }

        payment.applicationUsername = self.appUserID
        self.preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: self.appUserID)

        self.cachePresentedOfferingIdentifier(package: package, productIdentifier: productIdentifier)

        self.productsManager.cache(StoreProduct(sk1Product: sk1Product))

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
            wrapper.add(payment)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(sk2Product product: SK2Product,
                  package: Package?,
                  promotionalOffer: PromotionalOffer.SignedData?,
                  completion: @escaping PurchaseCompletedBlock) {
        _ = Task<Void, Never> {
            do {
                let result: PurchaseResultData = try await self.purchase(sk2Product: product,
                                                                         package: package,
                                                                         promotionalOffer: promotionalOffer)

                if !result.userCancelled {
                    Logger.rcPurchaseSuccess(Strings.purchase.purchased_product(
                        productIdentifier: product.id
                    ))
                }

                DispatchQueue.main.async {
                    completion(result.transaction,
                               result.customerInfo,
                               // Forward an error if purchase was cancelled to match SK1 behavior.
                               result.userCancelled ? ErrorUtils.purchaseCancelledError().asPublicError : nil,
                               result.userCancelled)
                }
            } catch let error {
                Logger.rcPurchaseError(Strings.purchase.product_purchase_failed(
                    productIdentifier: product.id,
                    error: error
                ))

                DispatchQueue.main.async {
                    completion(nil, nil, ErrorUtils.purchasesError(withUntypedError: error).asPublicError, false)
                }
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(
        sk2Product: SK2Product,
        package: Package?,
        promotionalOffer: PromotionalOffer.SignedData?
    ) async throws -> PurchaseResultData {
        let result: Product.PurchaseResult

        do {
            result = try await TimingUtil.measureAndLogIfTooSlow(
                threshold: .purchase,
                message: Strings.purchase.sk2_purchase_too_slow.description) {
                    var options: Set<Product.PurchaseOption> = [
                        .simulatesAskToBuyInSandbox(Purchases.simulatesAskToBuyInSandbox)
                    ]

                    if let signedData = promotionalOffer {
                        Logger.debug(
                            Strings.storeKit.sk2_purchasing_added_promotional_offer_option(signedData.identifier)
                        )
                        options.insert(try signedData.sk2PurchaseOption)
                    }

                    self.cachePresentedOfferingIdentifier(package: package, productIdentifier: sk2Product.id)

                    return try await sk2Product.purchase(options: options)
                }
        } catch StoreKitError.userCancelled {
            return (
                transaction: nil,
                customerInfo: try await self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                                              fetchPolicy: .cachedOrFetched),
                userCancelled: true
            )
        } catch let error as PromotionalOffer.SignedData.Error {
            throw ErrorUtils.invalidPromotionalOfferError(error: error,
                                                          message: error.localizedDescription)
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
        return try await Async.call { completion in
            self.promotionalOffer(forProductDiscount: discount,
                                  product: product,
                                  completion: completion)
        }
    }

#if os(iOS) || os(macOS)

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscription(completion: @escaping (PurchasesError?) -> Void) {
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

// MARK: - Private

extension PurchasesOrchestrator {

    /// - Returns: `StoreKit1Wrapper` if it's set, otherwise forwards an error to `completion` and returns `nil`
    private func storeKit1Wrapper(orFailWith completion: @escaping PurchaseCompletedBlock) -> StoreKit1Wrapper? {
        guard let storeKit1Wrapper = self.paymentQueueWrapper.sk1Wrapper else {
            self.operationDispatcher.dispatchOnMainActor {
                completion(nil,
                           nil,
                           ErrorUtils.configurationError(
                            message: Strings.storeKit.sk1_product_with_sk2_enabled.description
                           ).asPublicError,
                           false)
            }
            return nil
        }

        return storeKit1Wrapper
    }

}

// MARK: - StoreKit1WrapperDelegate

extension PurchasesOrchestrator: StoreKit1WrapperDelegate {

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper, updatedTransaction transaction: SKPaymentTransaction) {
        let storeTransaction = StoreTransaction(sk1Transaction: transaction)

        switch transaction.transactionState {
        case .restored, // for observer mode
             .purchased:
            self.handlePurchasedTransaction(storeTransaction, storefront: storeKit1Wrapper.currentStorefront)
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

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper,
                          removedTransaction transaction: SKPaymentTransaction) {
        // unused for now
    }

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper,
                          shouldAddStorePayment payment: SKPayment,
                          for product: SK1Product) -> Bool {
        self.productsManager.cache(StoreProduct(sk1Product: product))
        guard let delegate = self.delegate else { return false }

        guard let productIdentifier = payment.extractProductIdentifier() else {
            return false
        }

        let storeProduct = StoreProduct(sk1Product: product)
        delegate.readyForPromotedProduct(storeProduct) { completion in
            self.purchaseCompleteCallbacksByProductID.modify { $0[productIdentifier] = completion }
            storeKit1Wrapper.add(payment)
        }

        // See `SKPaymentTransactionObserver.paymentQueue(_:shouldAddStorePayment:for:)`
        // Returns `false` to indicate that the app will defer the purchase and be handled
        // when the user calls the purchase callback.
        return false
    }

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper,
                          didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(Strings.purchase.entitlements_revoked_syncing_purchases(productIdentifiers: productIdentifiers))
        syncPurchases { @Sendable _ in
            Logger.debug(Strings.purchase.purchases_synced)
        }
    }

    @available(iOS 13.4, macCatalyst 13.4, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    var storeKit1WrapperShouldShowPriceConsent: Bool {
        return self.delegate?.shouldShowPriceConsent ?? true
    }

    func storeKit1WrapperDidChangeStorefront(_ storeKit1Wrapper: StoreKit1Wrapper) {
        handleStorefrontChange()
    }

}

extension PurchasesOrchestrator: PaymentQueueWrapperDelegate {

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    var paymentQueueWrapperShouldShowPriceConsent: Bool {
        return self.storeKit1WrapperShouldShowPriceConsent
    }
    #endif

    func paymentQueueWrapper(
        _ wrapper: PaymentQueueWrapper,
        shouldAddStorePayment payment: SKPayment,
        for product: SK1Product
    ) -> Bool {
        // `PurchasesOrchestrator` becomes `PaymentQueueWrapperDelegate` only
        // when `StoreKit1Wrapper` is not initialized, which means that promoted purchases
        // need to be handled as a SK2 purchase.
        // This method converts the `SKPayment` into an SK2 purchase by fetching the product again.
        if self.paymentQueueWrapper.sk1Wrapper != nil {
            Logger.warn("Unexpectedly received PaymentQueueWrapperDelegate call with SK1 enabled")
            assertionFailure("This method should not be invoked if SK1 is enabled")
        }

        guard let delegate = self.delegate else { return false }

        let productIdentifier = product.productIdentifier

        self.productsManager.products(withIdentifiers: [productIdentifier]) { result in
            guard let product = result.value?.first(where: { $0.productIdentifier == productIdentifier }) else {
                Logger.warn(Strings.purchase.promo_purchase_product_not_found(productIdentifier: productIdentifier))
                return
            }

            let startPurchase: StartPurchaseBlock

            if #available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *),
               let discount = payment.paymentDiscount.map(PromotionalOffer.SignedData.init) {
                startPurchase = { completion in
                    self.purchase(product: product,
                                  package: nil,
                                  promotionalOffer: discount) { transaction, customerInfo, error, cancelled in
                        completion(transaction, customerInfo, error, cancelled)
                    }
                }
            } else {
                startPurchase = { completion in
                    self.purchase(product: product,
                                  package: nil) { transaction, customerInfo, error, cancelled in
                        completion(transaction, customerInfo, error, cancelled)
                    }
                }
            }

            delegate.readyForPromotedProduct(product, purchase: startPurchase)
        }

        // See `SKPaymentTransactionObserver.paymentQueue(_:shouldAddStorePayment:for:)`
        // Returns `false` to indicate that the app will defer the purchase and be handled
        // when the user calls the purchase callback.
        return false
    }

}

// @unchecked because:
// - It has a mutable `delegate` because it needs to be, as `weak`.
// - It has mutable `_storeKit2TransactionListener` and `_storeKit2StorefrontListener`, which are necessary
// due to the availability annotations
extension PurchasesOrchestrator: @unchecked Sendable {}

// MARK: Transaction state updates.

private extension PurchasesOrchestrator {

    func handlePurchasedTransaction(_ transaction: StoreTransaction,
                                    storefront: StorefrontType?) {
        self.receiptFetcher.receiptData(
            refreshPolicy: self.refreshRequestPolicy(forProductIdentifier: transaction.productIdentifier)
        ) { receiptData in
            if let receiptData = receiptData, !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(withTransaction: transaction,
                                                 receiptData: receiptData,
                                                 initiationSource: .purchase,
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

            let isCancelled = purchasesError.isCancelledError

            if isCancelled {
                self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                      fetchPolicy: .cachedOrFetched) { @Sendable customerInfo in
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(storeTransaction,
                                   customerInfo.value,
                                   purchasesError.asPublicError,
                                   true)
                    }
                }
            } else {
                self.operationDispatcher.dispatchOnMainActor {
                    completion(storeTransaction,
                               nil,
                               purchasesError.asPublicError,
                               false)
                }
            }
        }

        self.finishTransactionIfNeeded(storeTransaction, completion: {})
    }

    func handleDeferredTransaction(_ transaction: SKPaymentTransaction) {
        let userCancelled = transaction.error?.isCancelledError ?? false
        let storeTransaction = StoreTransaction(sk1Transaction: transaction)

        guard let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: storeTransaction) else {
            return
        }

        self.operationDispatcher.dispatchOnMainActor {
            completion(
                storeTransaction,
                nil,
                ErrorUtils.paymentDeferredError().asPublicError,
                userCancelled
            )
        }
    }

    private func refreshRequestPolicy(forProductIdentifier productIdentifier: String) -> ReceiptRefreshPolicy {
        if self.systemInfo.dangerousSettings.internalSettings.enableReceiptFetchRetry {
            return .retryUntilProductIsFound(productIdentifier: productIdentifier,
                                             maximumRetries: Self.receiptRetryCount,
                                             sleepDuration: Self.receiptRetrySleepDuration)
        } else {
            // See https://github.com/RevenueCat/purchases-ios/pull/2245 and
            // https://github.com/RevenueCat/purchases-ios/issues/2260
            // - Release or production builds:
            //      We don't _want_ to always refresh receipts to avoid throttling errors
            //      We don't _need_ to because the receipt will be refreshed by the backend using /verifyReceipt
            // - Debug and sandbox builds (potentially using StoreKit config files):
            //      We need to always refresh the receipt because the backend does not use /verifyReceipt
            //          when it was generated locally with SK config files.

            #if DEBUG
            return self.systemInfo.isSandbox
            ? .always
            : .onlyIfEmpty
            #else
            return .onlyIfEmpty
            #endif
        }
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesOrchestrator: StoreKit2TransactionListenerDelegate {

    func storeKit2TransactionListener(
        _ listener: StoreKit2TransactionListener,
        updatedTransaction transaction: StoreTransactionType
    ) async throws {
        let isRestore = self.systemInfo.observerMode

        _ = try await self.syncPurchases(receiptRefreshPolicy: .always,
                                         isRestore: isRestore,
                                         initiationSource: .queue)

        await Async.call { completion in
            self.finishTransactionIfNeeded(transaction) { @MainActor in
                completion(())
            }
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesOrchestrator: StoreKit2StorefrontListenerDelegate {

    func storefrontDidUpdate(with storefront: StorefrontType) {
        self.handleStorefrontChange()
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
        guard !productIdentifier.trimmingWhitespacesAndNewLines.isEmpty else {
            self.operationDispatcher.dispatchOnMainActor {
                completion(
                    nil,
                    nil,
                    ErrorUtils.storeProblemError(
                        withMessage: Strings.purchase.could_not_purchase_product_id_not_found.description
                    ).asPublicError,
                    false
                )
            }
            return false
        }

        return self.purchaseCompleteCallbacksByProductID.modify { callbacks in
            guard callbacks[productIdentifier] == nil else {
                self.operationDispatcher.dispatchOnMainActor {
                    completion(nil, nil, ErrorUtils.operationAlreadyInProgressError().asPublicError, false)
                }
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

    /// Called as a result a purchase.
    func fetchProductsAndPostReceipt(
        withTransaction transaction: StoreTransaction,
        receiptData: Data,
        initiationSource: ProductRequestData.InitiationSource,
        storefront: StorefrontType?
    ) {
        if let productIdentifier = transaction.productIdentifier.notEmpty {
            self.products(withIdentifiers: [productIdentifier]) { products in
                self.postReceipt(withTransaction: transaction,
                                 receiptData: receiptData,
                                 products: Set(products),
                                 initiationSource: initiationSource,
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
                     initiationSource: ProductRequestData.InitiationSource,
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
                          observerMode: self.observerMode,
                          initiationSource: initiationSource,
                          subscriberAttributes: unsyncedAttributes) { result in
            self.handleReceiptPost(withTransaction: transaction,
                                   result: result,
                                   subscriberAttributes: unsyncedAttributes)
        }
    }

    func handleReceiptPost(withTransaction transaction: StoreTransaction,
                           result: Result<CustomerInfo, BackendError>,
                           subscriberAttributes: SubscriberAttribute.Dictionary?) {
        self.operationDispatcher.dispatchOnMainActor {
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

                self.finishTransactionIfNeeded(transaction) {
                    completion?(transaction, customerInfo, nil, false)
                }

            case let .failure(error):
                let purchasesError = error.asPublicError

                if finishable {
                    self.finishTransactionIfNeeded(transaction) {
                        completion?(transaction, nil, purchasesError, false)
                    }
                } else {
                    completion?(transaction, nil, purchasesError, false)
                }
            }
        }
    }

    func markSyncedIfNeeded(
        subscriberAttributes: SubscriberAttribute.Dictionary?,
        appUserID: String,
        error: BackendError?
    ) {
        if let error = error {
            guard error.successfullySynced else { return }

            if let attributeErrors = (error as NSError).subscriberAttributesErrors, !attributeErrors.isEmpty {
                Logger.error(Strings.attribution.subscriber_attributes_error(
                    errors: attributeErrors
                ))
            }
        }

        self.attribution.markAttributesAsSynced(subscriberAttributes, appUserID: appUserID)
    }

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       initiationSource: ProductRequestData.InitiationSource,
                       completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        // Don't log anything unless the flag was explicitly set.
        let allowSharingAppStoreAccountSet = self._allowSharingAppStoreAccount.value != nil
        if allowSharingAppStoreAccountSet, !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.restore.restorepurchases_called_with_allow_sharing_appstore_account_false_warning)
        }

        let currentAppUserID = self.appUserID
        let unsyncedAttributes = self.unsyncedAttributes
        // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
        // https://rev.cat/apple-restoring-purchased-products
        self.receiptFetcher.receiptData(refreshPolicy: receiptRefreshPolicy) { receiptData in
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

            self.operationDispatcher.dispatchOnWorkerThread {
                let hasTransactions = self.transactionsManager.customerHasTransactions(receiptData: receiptData)
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

                self.createProductRequestData(with: receiptData) { productRequestData in
                    self.backend.post(receiptData: receiptData,
                                      appUserID: currentAppUserID,
                                      isRestore: isRestore,
                                      productData: productRequestData,
                                      presentedOfferingIdentifier: nil,
                                      observerMode: self.observerMode,
                                      initiationSource: initiationSource,
                                      subscriberAttributes: unsyncedAttributes) { result in
                        self.handleReceiptPost(result: result,
                                               subscriberAttributes: unsyncedAttributes,
                                               completion: completion)
                    }
                }
            }
        }
    }

    func handleReceiptPost(result: Result<CustomerInfo, BackendError>,
                           subscriberAttributes: SubscriberAttribute.Dictionary,
                           completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
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

    func purchase(
        sk1Product: SK1Product,
        package: Package,
        wrapper: StoreKit1Wrapper,
        completion: @escaping PurchaseCompletedBlock
    ) {
        let payment = wrapper.payment(with: sk1Product)
        purchase(sk1Product: sk1Product,
                 payment: payment,
                 package: package,
                 wrapper: wrapper,
                 completion: completion)
    }

    func handleStorefrontChange() {
        self.productsManager.clearCache()
        self.offeringsManager.invalidateAndReFetchCachedOfferingsIfAppropiate(appUserID: self.appUserID)
    }

    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @Sendable @MainActor () -> Void
    ) {
        @Sendable
        func complete() {
            self.operationDispatcher.dispatchOnMainActor(completion)
        }

        guard self.finishTransactions else {
            complete()
            return
        }

        Logger.purchase(Strings.purchase.finishing_transaction(transaction))

        transaction.finish(self.paymentQueueWrapper.paymentQueueWrapperType, completion: complete)
    }

    func cachePresentedOfferingIdentifier(package: Package?, productIdentifier: String) {
        if let package = package {
            self.presentedOfferingIDsByProductID.modify { $0[productIdentifier] = package.offeringIdentifier }
        }
    }

    /// Computes a `ProductRequestData` for an active subscription found in the receipt,
    /// or `nil` if there is any issue fetching it.
    func createProductRequestData(
        with receiptData: Data,
        completion: @escaping (ProductRequestData?) -> Void
    ) {
        guard let receipt = try? self.receiptParser.parse(from: receiptData),
        let productIdentifier = receipt.mostRecentActiveSubscription?.productId else {
            completion(nil)
            return
        }

        self.productsManager.products(withIdentifiers: [productIdentifier]) { products in
            let result = products.value?.first.map {
                ProductRequestData(with: $0, storefront: self.paymentQueueWrapper.currentStorefront)
            }

            completion(result)
        }
    }

}

private extension PurchasesOrchestrator {

    static func logPurchase(product: StoreProduct, package: Package?, offer: PromotionalOffer.SignedData? = nil) {
        let string: PurchaseStrings = {
            switch (package, offer) {
            case (nil, nil): return .purchasing_product(product)
            case let (package?, nil): return .purchasing_product_from_package(product, package)
            case let (nil, offer?): return .purchasing_product_with_offer(product, offer)
            case let (package?, offer?): return .purchasing_product_from_package_with_offer(product,
                                                                                            package,
                                                                                            offer)
            }
        }()

        Logger.purchase(string)
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
                       isRestore: Bool,
                       initiationSource: ProductRequestData.InitiationSource) async throws -> CustomerInfo {
        return try await Async.call { completion in
            self.syncPurchases(receiptRefreshPolicy: receiptRefreshPolicy,
                               isRestore: isRestore,
                               initiationSource: initiationSource,
                               completion: completion)
        }
    }

}
