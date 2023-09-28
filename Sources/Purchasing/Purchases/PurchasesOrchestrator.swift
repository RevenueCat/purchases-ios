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
    private let presentedPaywall: Atomic<PaywallEvent.Data?> = nil
    private let purchaseCompleteCallbacksByProductID: Atomic<[String: PurchaseCompletedBlock]> = .init([:])

    private var appUserID: String { self.currentUserProvider.currentAppUserID }
    private var unsyncedAttributes: SubscriberAttribute.Dictionary {
        self.attribution.unsyncedAttributesByKey(appUserID: self.appUserID)
    }

    private let productsManager: ProductsManagerType
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let attribution: Attribution
    private let operationDispatcher: OperationDispatcher
    private let receiptFetcher: ReceiptFetcher
    private let receiptParser: PurchasesReceiptParser
    private let customerInfoManager: CustomerInfoManager
    private let backend: Backend
    private let transactionPoster: TransactionPosterType
    private let currentUserProvider: CurrentUserProvider
    private let transactionsManager: TransactionsManager
    private let deviceCache: DeviceCache
    private let offeringsManager: OfferingsManager
    private let manageSubscriptionsHelper: ManageSubscriptionsHelper
    private let beginRefundRequestHelper: BeginRefundRequestHelper
    private let storeMessagesHelper: StoreMessagesHelper

    // Can't have these properties with `@available`.
    // swiftlint:disable identifier_name
    var _storeKit2TransactionListener: Any?
    var _storeKit2StorefrontListener: Any?
    // swiftlint:enable identifier_name

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var storeKit2TransactionListener: StoreKit2TransactionListenerType {
        // swiftlint:disable:next force_cast
        return self._storeKit2TransactionListener! as! StoreKit2TransactionListenerType
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
                     transactionPoster: TransactionPoster,
                     currentUserProvider: CurrentUserProvider,
                     transactionsManager: TransactionsManager,
                     deviceCache: DeviceCache,
                     offeringsManager: OfferingsManager,
                     manageSubscriptionsHelper: ManageSubscriptionsHelper,
                     beginRefundRequestHelper: BeginRefundRequestHelper,
                     storeKit2TransactionListener: StoreKit2TransactionListenerType,
                     storeKit2StorefrontListener: StoreKit2StorefrontListener,
                     storeMessagesHelper: StoreMessagesHelper
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
            transactionPoster: transactionPoster,
            currentUserProvider: currentUserProvider,
            transactionsManager: transactionsManager,
            deviceCache: deviceCache,
            offeringsManager: offeringsManager,
            manageSubscriptionsHelper: manageSubscriptionsHelper,
            beginRefundRequestHelper: beginRefundRequestHelper,
            storeMessagesHelper: storeMessagesHelper
        )

        self._storeKit2TransactionListener = storeKit2TransactionListener
        self._storeKit2StorefrontListener = storeKit2StorefrontListener

        storeKit2StorefrontListener.delegate = self
        if systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
            storeKit2StorefrontListener.listenForStorefrontChanges()
        }

        Task {
            #if os(iOS)

            if #available(iOS 16.4, *) {
                await storeMessagesHelper.deferMessagesIfNeeded()
            }

            #endif

            await storeKit2TransactionListener.set(delegate: self)
            if systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
                await storeKit2TransactionListener.listenForTransactions()
            }
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
         transactionPoster: TransactionPoster,
         currentUserProvider: CurrentUserProvider,
         transactionsManager: TransactionsManager,
         deviceCache: DeviceCache,
         offeringsManager: OfferingsManager,
         manageSubscriptionsHelper: ManageSubscriptionsHelper,
         beginRefundRequestHelper: BeginRefundRequestHelper,
         storeMessagesHelper: StoreMessagesHelper
    ) {
        self.productsManager = productsManager
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.attribution = subscriberAttributes
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.receiptParser = receiptParser
        self.customerInfoManager = customerInfoManager
        self.backend = backend
        self.transactionPoster = transactionPoster
        self.currentUserProvider = currentUserProvider
        self.transactionsManager = transactionsManager
        self.deviceCache = deviceCache
        self.offeringsManager = offeringsManager
        self.manageSubscriptionsHelper = manageSubscriptionsHelper
        self.beginRefundRequestHelper = beginRefundRequestHelper
        self.storeMessagesHelper = storeMessagesHelper

        Logger.verbose(Strings.purchase.purchases_orchestrator_init(self))
    }

    deinit {
        Logger.verbose(Strings.purchase.purchases_orchestrator_deinit(self))
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
                          completion: @escaping @Sendable (Result<PromotionalOffer, PurchasesError>) -> Void) {
        guard let discountIdentifier = productDiscount.offerIdentifier else {
            completion(.failure(ErrorUtils.productDiscountMissingIdentifierError()))
            return
        }

        guard let subscriptionGroupIdentifier = product.subscriptionGroupIdentifier else {
            completion(.failure(ErrorUtils.productDiscountMissingSubscriptionGroupIdentifierError()))
            return
        }

        self.receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { receiptData, receiptURL in
            guard let receiptData = receiptData, !receiptData.isEmpty else {
                let underlyingError = ErrorUtils.missingReceiptFileError(receiptURL)

                // Promotional offers require existing purchases.
                // If no receipt is found, this is most likely in sandbox with no purchases,
                // so producing an "ineligible" error is better.
                completion(.failure(ErrorUtils.ineligibleError(error: underlyingError)))

                return
            }

            self.operationDispatcher.dispatchOnWorkerThread {
                if !self.receiptParser.receiptHasTransactions(receiptData: receiptData) {
                  // Promotional offers require existing purchases.
                  // Fail early if receipt has no transactions.
                  completion(.failure(ErrorUtils.ineligibleError()))
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
        } else if product.isTestProduct {
            self.handleTestProduct(completion)
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
        } else if product.isTestProduct {
            self.handleTestProduct(completion)
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
                let publicError = ErrorUtils.purchasesError(withUntypedError: error).asPublicError
                let userCancelled = publicError.isCancelledError

                DispatchQueue.main.async {
                    completion(nil, nil, publicError, userCancelled)
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

            result = try await self.purchase(sk2Product, options)
        } catch StoreKitError.userCancelled {
            guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
                throw ErrorUtils.purchaseCancelledError()
            }

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

        if userCancelled, self.systemInfo.dangerousSettings.customEntitlementComputation {
            throw ErrorUtils.purchaseCancelledError()
        }

        let transaction = sk2Transaction.map(StoreTransaction.init(sk2Transaction:))
        let customerInfo: CustomerInfo

        if let transaction = transaction {
            customerInfo = try await self.handlePurchasedTransaction(transaction, .purchase)
        } else {
            // `transaction` would be `nil` for `Product.PurchaseResult.pending` and
            // `Product.PurchaseResult.userCancelled`.
            customerInfo = try await self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                                           fetchPolicy: .cachedOrFetched)
        }

        return (transaction, customerInfo, userCancelled)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func purchase(
        _ product: SK2Product,
        _ options: Set<Product.PurchaseOption>
    ) async throws -> Product.PurchaseResult {
        #if VISION_OS
        return try await product.purchase(confirmIn: try self.systemInfo.currentWindowScene,
                                          options: options)
        #else
        return try await product.purchase(options: options)
        #endif
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

    func cachePresentedOfferingIdentifier(_ identifier: String, productIdentifier: String) {
        self.presentedOfferingIDsByProductID.modify { $0[productIdentifier] = identifier }
    }

    func track(paywallEvent: PaywallEvent) {
        switch paywallEvent {
        case let .impression(data):
            self.cachePresentedPaywall(data)

        case .close:
            self.clearPresentedPaywall()

        case .cancel:
            break
        }
    }

#if os(iOS) || os(macOS) || VISION_OS

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

#if os(iOS) || VISION_OS

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
        // For observer mode. Should only come from calls to `restoreCompletedTransactions`,
        // which the SDK does not currently use.
        case .restored:
            self.handlePurchasedTransaction(storeTransaction,
                                            storefront: storeKit1Wrapper.currentStorefront,
                                            restored: true)
        case .purchased:
            self.handlePurchasedTransaction(storeTransaction,
                                            storefront: storeKit1Wrapper.currentStorefront,
                                            restored: false)
        case .purchasing:
            break
        case .failed:
            self.handleFailedTransaction(transaction)
        case .deferred:
            self.handleDeferredTransaction(transaction)
        @unknown default:
            Logger.appleWarning(Strings.storeKit.sk1_unknown_transaction_state(transaction.transactionState))
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
            let addPayment = self.addPurchaseCompletedCallback(
                productIdentifier: productIdentifier,
                completion: completion
            )
            if addPayment {
                storeKit1Wrapper.add(payment)
            }
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

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
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
            Logger.warn(Strings.purchase.payment_queue_wrapper_delegate_call_sk1_enabled)
            assertionFailure(Strings.purchase.payment_queue_wrapper_delegate_call_sk1_enabled.description)
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

    func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        let storeTransaction = StoreTransaction(sk1Transaction: transaction)

        if let error = transaction.error,
           let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: storeTransaction) {
            let purchasesError = ErrorUtils.purchasesError(withSKError: error)

            let isCancelled = purchasesError.isCancelledError

            if isCancelled {
                if self.systemInfo.dangerousSettings.customEntitlementComputation {
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(storeTransaction,
                                   nil,
                                   purchasesError.asPublicError,
                                   true)
                    }
                } else {
                    self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                          fetchPolicy: .cachedOrFetched) { @Sendable customerInfo in
                        self.operationDispatcher.dispatchOnMainActor {
                            completion(storeTransaction,
                                       customerInfo.value,
                                       purchasesError.asPublicError,
                                       true)
                        }
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

        self.transactionPoster.finishTransactionIfNeeded(storeTransaction, completion: {})
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

    /// - Parameter restored: whether the transaction state was `.restored` instead of `.purchased`.
    private func purchaseSource(
        for productIdentifier: String,
        restored: Bool
    ) -> PurchaseSource {
        let initiationSource: ProductRequestData.InitiationSource = {
            // Having a purchase completed callback implies that the transation comes from an explicit call
            // to `purchase()` instead of a StoreKit transaction notification.
            let hasPurchaseCallback = self.purchaseCompleteCallbacksByProductID.value.keys.contains(productIdentifier)

            switch (hasPurchaseCallback, restored) {
            case (true, false): return .purchase
                // Note that restores initiated through the SDK with `restorePurchases`
                // won't use this method since those set the initiation source explicitly.
            case (true, true): return .restore
            case (false, _): return .queue
            }
        }()

        return .init(isRestore: self.allowSharingAppStoreAccount,
                     initiationSource: initiationSource)
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesOrchestrator: StoreKit2TransactionListenerDelegate {

    func storeKit2TransactionListener(
        _ listener: StoreKit2TransactionListenerType,
        updatedTransaction transaction: StoreTransactionType
    ) async throws {
        let storefront = await self.storefront(from: transaction)
        let subscriberAttributes = self.unsyncedAttributes
        let adServicesToken = self.attribution.unsyncedAdServicesToken
        let transactionData: PurchasedTransactionData = .init(
            appUserID: self.appUserID,
            presentedOfferingID: nil,
            unsyncedAttributes: subscriberAttributes,
            aadAttributionToken: adServicesToken,
            storefront: storefront,
            source: .init(
                isRestore: self.allowSharingAppStoreAccount,
                initiationSource: .queue
            )
        )

        let result: Result<CustomerInfo, BackendError> = await Async.call { completed in
            self.transactionPoster.handlePurchasedTransaction(
                StoreTransaction.from(transaction: transaction),
                data: transactionData
            ) { result in
                completed(result)
            }
        }

        self.handlePostReceiptResult(result,
                                     transactionData: transactionData,
                                     subscriberAttributes: subscriberAttributes,
                                     adServicesToken: adServicesToken)

        if let error = result.error {
            throw error
        }
    }

    private func storefront(from transaction: StoreTransactionType) async -> StorefrontType? {
        return await transaction.storefrontOrCurrent
        // If we couldn't determine storefront from SK2, try SK1:
        ?? self.paymentQueueWrapper.sk1Wrapper?.currentStorefront
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
            return $0.removeValue(forKey: transaction.productIdentifier)
        }
    }

    func markSyncedIfNeeded(
        subscriberAttributes: SubscriberAttribute.Dictionary?,
        adServicesToken: String?,
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

        self.attribution.markAttributesAsSynced(subscriberAttributes, appUserID: self.appUserID)
        if let adServicesToken = adServicesToken {
            self.attribution.markAdServicesTokenAsSynced(adServicesToken, appUserID: self.appUserID)
        }
    }

    // swiftlint:disable:next function_body_length
    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       initiationSource: ProductRequestData.InitiationSource,
                       completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        // Don't log anything unless the flag was explicitly set.
        let allowSharingAppStoreAccountSet = self._allowSharingAppStoreAccount.value != nil
        if allowSharingAppStoreAccountSet, !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.purchase.restorepurchases_called_with_allow_sharing_appstore_account_false)
        }

        let currentAppUserID = self.appUserID
        let unsyncedAttributes = self.unsyncedAttributes
        let adServicesToken = self.attribution.unsyncedAdServicesToken

        // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
        // https://rev.cat/apple-restoring-purchased-products
        self.receiptFetcher.receiptData(refreshPolicy: receiptRefreshPolicy) { receiptData, receiptURL in
            guard let receiptData = receiptData,
                  !receiptData.isEmpty else {
                      if self.systemInfo.isSandbox {
                          Logger.appleWarning(Strings.receipt.no_sandbox_receipt_restore)
                      }

                      if let completion = completion {
                          self.operationDispatcher.dispatchOnMainThread {
                              completion(.failure(ErrorUtils.missingReceiptFileError(receiptURL)))
                          }
                      }
                      return
                  }

            self.operationDispatcher.dispatchOnWorkerThread {
                let hasTransactions = self.transactionsManager.customerHasTransactions(receiptData: receiptData)
                let cachedCustomerInfo = self.customerInfoManager.cachedCustomerInfo(appUserID: currentAppUserID)

                if !hasTransactions, let customerInfo = cachedCustomerInfo, customerInfo.originalPurchaseDate != nil {
                    if let completion = completion {
                        self.operationDispatcher.dispatchOnMainThread {
                            completion(.success(customerInfo))
                        }
                    }

                    return
                }

                self.createProductRequestData(with: receiptData) { productRequestData in
                    let transactionData: PurchasedTransactionData = .init(
                        appUserID: currentAppUserID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: unsyncedAttributes,
                        storefront: productRequestData?.storefront,
                        source: .init(isRestore: isRestore, initiationSource: initiationSource)
                    )

                    self.backend.post(receiptData: receiptData,
                                      productData: productRequestData,
                                      transactionData: transactionData,
                                      observerMode: self.observerMode) { result in
                        self.handleReceiptPost(result: result,
                                               transactionData: transactionData,
                                               subscriberAttributes: unsyncedAttributes,
                                               adServicesToken: adServicesToken,
                                               completion: completion)
                    }
                }
            }
        }
    }

    func handleReceiptPost(result: Result<CustomerInfo, BackendError>,
                           transactionData: PurchasedTransactionData,
                           subscriberAttributes: SubscriberAttribute.Dictionary,
                           adServicesToken: String?,
                           completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        self.handlePostReceiptResult(
            result,
            transactionData: transactionData,
            subscriberAttributes: subscriberAttributes,
            adServicesToken: adServicesToken
        )

        if let completion = completion {
            self.operationDispatcher.dispatchOnMainThread {
                completion(result.mapError { $0.asPurchasesError })
            }
        }
    }

    func handlePostReceiptResult(_ result: Result<CustomerInfo, BackendError>,
                                 transactionData: PurchasedTransactionData,
                                 subscriberAttributes: SubscriberAttribute.Dictionary,
                                 adServicesToken: String?) {
        switch result {
        case let .success(customerInfo):
            self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: self.appUserID)

        case .failure:
            // Cache paywall again in case purchase is retried.
            if let paywall = transactionData.presentedPaywall {
                self.cachePresentedPaywall(paywall)
            }
        }

        self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                adServicesToken: adServicesToken,
                                error: result.error)
    }

    func handlePurchasedTransaction(_ purchasedTransaction: StoreTransaction,
                                    storefront: StorefrontType?,
                                    restored: Bool) {
        let offeringID = self.getAndRemovePresentedOfferingIdentifier(for: purchasedTransaction)
        let paywall = self.getAndRemovePresentedPaywall()
        let unsyncedAttributes = self.unsyncedAttributes
        let adServicesToken = self.attribution.unsyncedAdServicesToken
        let transactionData: PurchasedTransactionData = .init(
            appUserID: self.appUserID,
            presentedOfferingID: offeringID,
            presentedPaywall: paywall,
            unsyncedAttributes: unsyncedAttributes,
            aadAttributionToken: adServicesToken,
            storefront: storefront,
            source: self.purchaseSource(for: purchasedTransaction.productIdentifier,
                                        restored: restored)
        )

        self.transactionPoster.handlePurchasedTransaction(
            purchasedTransaction,
            data: transactionData
        ) { result in
            self.handlePostReceiptResult(result,
                                         transactionData: transactionData,
                                         subscriberAttributes: unsyncedAttributes,
                                         adServicesToken: adServicesToken)

            if let completion = self.getAndRemovePurchaseCompletedCallback(forTransaction: purchasedTransaction) {
                self.operationDispatcher.dispatchOnMainActor {
                    completion(purchasedTransaction,
                               result.value,
                               result.error?.asPublicError,
                               result.error?.isCancelledError ?? false
                    )
                }
            }
        }
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

    func cachePresentedOfferingIdentifier(package: Package?, productIdentifier: String) {
        if let package = package {
            self.cachePresentedOfferingIdentifier(package.offeringIdentifier, productIdentifier: productIdentifier)
        }
    }

    func cachePresentedPaywall(_ paywall: PaywallEvent.Data) {
        Logger.verbose(Strings.paywalls.caching_presented_paywall)
        self.presentedPaywall.value = paywall
    }

    func clearPresentedPaywall() {
        Logger.verbose(Strings.paywalls.clearing_presented_paywall)
        self.presentedPaywall.value = nil
    }

    func getAndRemovePresentedOfferingIdentifier(for productIdentifier: String) -> String? {
        return self.presentedOfferingIDsByProductID.modify {
            $0.removeValue(forKey: productIdentifier)
        }
    }

    func getAndRemovePresentedOfferingIdentifier(for transaction: StoreTransaction) -> String? {
        return self.getAndRemovePresentedOfferingIdentifier(for: transaction.productIdentifier)
    }

    func getAndRemovePresentedPaywall() -> PaywallEvent.Data? {
        return self.presentedPaywall.getAndSet(nil)
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

    func handleTestProduct(_ completion: @escaping PurchaseCompletedBlock) {
        self.operationDispatcher.dispatchOnMainActor {
            completion(
                nil,
                nil,
                ErrorUtils.productNotAvailableForPurchaseError().asPublicError,
                false
            )
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

    private func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        _ initiationSource: ProductRequestData.InitiationSource
    ) async throws -> CustomerInfo {
        let storefront = await Storefront.currentStorefront
        let offeringID = self.getAndRemovePresentedOfferingIdentifier(for: transaction)
        let paywall = self.getAndRemovePresentedPaywall()
        let unsyncedAttributes = self.unsyncedAttributes
        let adServicesToken = self.attribution.unsyncedAdServicesToken
        let transactionData: PurchasedTransactionData = .init(
            appUserID: self.appUserID,
            presentedOfferingID: offeringID,
            presentedPaywall: paywall,
            unsyncedAttributes: unsyncedAttributes,
            aadAttributionToken: adServicesToken,
            storefront: storefront,
            source: .init(isRestore: self.allowSharingAppStoreAccount,
                          initiationSource: initiationSource)
        )

        let result = await self.transactionPoster.handlePurchasedTransaction(
            transaction,
            data: transactionData
        )

        self.handlePostReceiptResult(result,
                                     transactionData: transactionData,
                                     subscriberAttributes: unsyncedAttributes,
                                     adServicesToken: adServicesToken)

        return try result
            .mapError(\.asPurchasesError)
            .get()
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
