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
    private let presentedOfferingContextsByProductID: Atomic<[String: PresentedOfferingContext]> = .init([:])
    private let presentedPaywall: Atomic<PaywallEvent?> = nil
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
    private let transactionFetcher: StoreKit2TransactionFetcherType
    private let customerInfoManager: CustomerInfoManager
    private let backend: Backend
    private let transactionPoster: TransactionPosterType
    private let currentUserProvider: CurrentUserProvider
    private let transactionsManager: TransactionsManager
    private let deviceCache: DeviceCache
    private let offeringsManager: OfferingsManager
    private let manageSubscriptionsHelper: ManageSubscriptionsHelper
    private let beginRefundRequestHelper: BeginRefundRequestHelper
    private let storeMessagesHelper: StoreMessagesHelperType?
    private let winBackOfferEligibilityCalculator: WinBackOfferEligibilityCalculatorType?
    private let paywallEventsManager: PaywallEventsManagerType?
    private let webPurchaseRedemptionHelper: WebPurchaseRedemptionHelperType
    private let dateProvider: DateProvider

    // Can't have these properties with `@available`.
    // swiftlint:disable identifier_name
    var _storeKit2TransactionListener: Any?
    var _storeKit2PurchaseIntentListener: Any?
    var _storeKit2StorefrontListener: Any?
    var _diagnosticsSynchronizer: Any?
    var _diagnosticsTracker: Any?
    var _storeKit2ObserverModePurchaseDetector: Any?
    // swiftlint:enable identifier_name

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var storeKit2TransactionListener: StoreKit2TransactionListenerType {
        // swiftlint:disable:next force_cast force_unwrapping
        return self._storeKit2TransactionListener! as! StoreKit2TransactionListenerType
    }

    @available(iOS 16.4, macOS 14.4, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    var storeKit2PurchaseIntentListener: StoreKit2PurchaseIntentListenerType {
        // swiftlint:disable:next force_cast force_unwrapping
        return self._storeKit2PurchaseIntentListener! as! StoreKit2PurchaseIntentListenerType
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var storeKit2StorefrontListener: StoreKit2StorefrontListener {
        // swiftlint:disable:next force_cast force_unwrapping
        return self._storeKit2StorefrontListener! as! StoreKit2StorefrontListener
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var diagnosticsSynchronizer: DiagnosticsSynchronizerType? {
        return self._diagnosticsSynchronizer as? DiagnosticsSynchronizerType
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var diagnosticsTracker: DiagnosticsTrackerType? {
        return self._diagnosticsTracker as? DiagnosticsTrackerType
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var storeKit2ObserverModePurchaseDetector: StoreKit2ObserverModePurchaseDetectorType? {
        return self._storeKit2ObserverModePurchaseDetector as? StoreKit2ObserverModePurchaseDetectorType
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    convenience init(productsManager: ProductsManagerType,
                     paymentQueueWrapper: EitherPaymentQueueWrapper,
                     systemInfo: SystemInfo,
                     subscriberAttributes: Attribution,
                     operationDispatcher: OperationDispatcher,
                     receiptFetcher: ReceiptFetcher,
                     receiptParser: PurchasesReceiptParser,
                     transactionFetcher: StoreKit2TransactionFetcherType,
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
                     storeKit2ObserverModePurchaseDetector: StoreKit2ObserverModePurchaseDetectorType,
                     storeMessagesHelper: StoreMessagesHelperType?,
                     diagnosticsSynchronizer: DiagnosticsSynchronizerType?,
                     diagnosticsTracker: DiagnosticsTrackerType?,
                     winBackOfferEligibilityCalculator: WinBackOfferEligibilityCalculatorType?,
                     paywallEventsManager: PaywallEventsManagerType?,
                     webPurchaseRedemptionHelper: WebPurchaseRedemptionHelperType,
                     dateProvider: DateProvider = DateProvider()
    ) {
        self.init(
            productsManager: productsManager,
            paymentQueueWrapper: paymentQueueWrapper,
            systemInfo: systemInfo,
            subscriberAttributes: subscriberAttributes,
            operationDispatcher: operationDispatcher,
            receiptFetcher: receiptFetcher,
            receiptParser: receiptParser,
            transactionFetcher: transactionFetcher,
            customerInfoManager: customerInfoManager,
            backend: backend,
            transactionPoster: transactionPoster,
            currentUserProvider: currentUserProvider,
            transactionsManager: transactionsManager,
            deviceCache: deviceCache,
            offeringsManager: offeringsManager,
            manageSubscriptionsHelper: manageSubscriptionsHelper,
            beginRefundRequestHelper: beginRefundRequestHelper,
            storeMessagesHelper: storeMessagesHelper,
            diagnosticsTracker: diagnosticsTracker,
            winBackOfferEligibilityCalculator: winBackOfferEligibilityCalculator,
            paywallEventsManager: paywallEventsManager,
            webPurchaseRedemptionHelper: webPurchaseRedemptionHelper,
            dateProvider: dateProvider
        )

        self._diagnosticsSynchronizer = diagnosticsSynchronizer

        self._storeKit2TransactionListener = storeKit2TransactionListener
        self._storeKit2StorefrontListener = storeKit2StorefrontListener
        self._storeKit2ObserverModePurchaseDetector = storeKit2ObserverModePurchaseDetector

        storeKit2StorefrontListener.delegate = self
        if systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable {
            storeKit2StorefrontListener.listenForStorefrontChanges()
        }

        #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
        if #available(iOS 16.0, *), let helper = storeMessagesHelper {
            Task {
                do {
                    try await helper.deferMessagesIfNeeded()
                } catch {
                    Logger.error(Strings.storeKit.could_not_defer_store_messages(error))
                }
            }
        }
        #endif

        Task {
            await setSK2DelegateAndStartListening()
        }

        Task {
            await syncDiagnosticsIfNeeded()
        }
    }

    init(productsManager: ProductsManagerType,
         paymentQueueWrapper: EitherPaymentQueueWrapper,
         systemInfo: SystemInfo,
         subscriberAttributes: Attribution,
         operationDispatcher: OperationDispatcher,
         receiptFetcher: ReceiptFetcher,
         receiptParser: PurchasesReceiptParser,
         transactionFetcher: StoreKit2TransactionFetcherType,
         customerInfoManager: CustomerInfoManager,
         backend: Backend,
         transactionPoster: TransactionPoster,
         currentUserProvider: CurrentUserProvider,
         transactionsManager: TransactionsManager,
         deviceCache: DeviceCache,
         offeringsManager: OfferingsManager,
         manageSubscriptionsHelper: ManageSubscriptionsHelper,
         beginRefundRequestHelper: BeginRefundRequestHelper,
         storeMessagesHelper: StoreMessagesHelperType?,
         diagnosticsTracker: DiagnosticsTrackerType?,
         winBackOfferEligibilityCalculator: WinBackOfferEligibilityCalculatorType?,
         paywallEventsManager: PaywallEventsManagerType?,
         webPurchaseRedemptionHelper: WebPurchaseRedemptionHelperType,
         dateProvider: DateProvider = DateProvider()
    ) {
        self.productsManager = productsManager
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.attribution = subscriberAttributes
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.receiptParser = receiptParser
        self.transactionFetcher = transactionFetcher
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
        self._diagnosticsTracker = diagnosticsTracker
        self.winBackOfferEligibilityCalculator = winBackOfferEligibilityCalculator
        self.paywallEventsManager = paywallEventsManager
        self.webPurchaseRedemptionHelper = webPurchaseRedemptionHelper
        self.dateProvider = dateProvider

        Logger.verbose(Strings.purchase.purchases_orchestrator_init(self))
    }

    deinit {
        Logger.verbose(Strings.purchase.purchases_orchestrator_deinit(self))
    }

    func redeemWebPurchase(_ webPurchaseRedemption: WebPurchaseRedemption) async -> WebPurchaseRedemptionResult {
        return await self.webPurchaseRedemptionHelper.handleRedeemWebPurchase(
            redemptionToken: webPurchaseRedemption.redemptionToken
        )
    }

    func redeemWebPurchase(
        webPurchaseRedemption: WebPurchaseRedemption,
        completion: @escaping (CustomerInfo?, PublicError?) -> Void
    ) {
        Task {
            let result = await self.redeemWebPurchase(webPurchaseRedemption)
            switch result {

            case let .success(customerInfo):
                completion(customerInfo, nil)
            case let .error(error):
                completion(nil, error)
            case .invalidToken:
                let userInfo: [String: Any] = [:]
                let error = PurchasesError(error: .invalidWebPurchaseToken, userInfo: userInfo)
                completion(nil, error.asPublicError)
            case .purchaseBelongsToOtherUser:
                let userInfo: [String: Any] = [:]
                let error = PurchasesError(error: .purchaseBelongsToOtherUser, userInfo: userInfo)
                completion(nil, error.asPublicError)
            case let .expired(obfuscatedEmail):
                let userInfo: [NSError.UserInfoKey: Any] = [
                    .obfuscatedEmail: obfuscatedEmail
                ]
                let error = PurchasesError(error: .expiredWebPurchaseToken, userInfo: userInfo)
                completion(nil, error.asPublicError)
            }
        }
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
        self.trackProductsStartedIfNeeded(requestedProductIds: productIdentifiersSet)
        let startTime = self.dateProvider.now()
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        self.productsManager.products(withIdentifiers: productIdentifiersSet) { products in
            let notFoundProductIds = productIdentifiersSet.subtracting(
                products.map { $0.map(\.productIdentifier) }.value.map { Set($0) } ?? []
            )
            let error = products.error
            self.trackProductsResultIfNeeded(requestedProductIds: productIdentifiersSet,
                                             notFoundProductIds: notFoundProductIds,
                                             error: error,
                                             startTime: startTime)
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

    func promotionalOffer(forProductDiscount productDiscount: StoreProductDiscountType,
                          product: StoreProductType,
                          completion: @escaping @Sendable (Result<PromotionalOffer, PurchasesError>) -> Void) {
        guard let discountIdentifier = productDiscount.offerIdentifier else {
            self.operationDispatcher.dispatchOnMainActor {
                completion(.failure(ErrorUtils.productDiscountMissingIdentifierError()))
            }
            return
        }

        guard let subscriptionGroupIdentifier = product.subscriptionGroupIdentifier else {
            self.operationDispatcher.dispatchOnMainActor {
                completion(.failure(ErrorUtils.productDiscountMissingSubscriptionGroupIdentifierError()))
            }
            return
        }

        if self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable,
            #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self.sk2PromotionalOffer(forProductDiscount: productDiscount,
                                     discountIdentifier: discountIdentifier,
                                     product: product,
                                     subscriptionGroupIdentifier: subscriptionGroupIdentifier) { result in
                self.operationDispatcher.dispatchOnMainActor {
                    completion(result)
                }
            }
        } else {
                self.sk1PromotionalOffer(forProductDiscount: productDiscount,
                                         discountIdentifier: discountIdentifier,
                                         product: product,
                                         subscriptionGroupIdentifier: subscriptionGroupIdentifier) { result in
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(result)
                    }
                }

        }
    }

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func purchase(params: PurchaseParams, completion: @escaping PurchaseCompletedBlock) {
        var product = params.product
        if product == nil {
            product = params.package?.storeProduct
        }
        guard let product = product else {
            // Should never happen since PurchaseParams.Builder initializer requires a product or a package
            fatalError("Missing product in PurchaseParams")
        }

        purchase(product: product,
                 package: params.package,
                 promotionalOffer: params.promotionalOffer?.signedData,
                 winBackOffer: params.winBackOffer,
                 metadata: params.metadata,
                 completion: completion)
    }
    #endif

    func purchase(product: StoreProduct,
                  package: Package?,
                  promotionalOffer: PromotionalOffer.SignedData? = nil,
                  winBackOffer: WinBackOffer? = nil,
                  metadata: [String: String]? = nil,
                  completion: @escaping PurchaseCompletedBlock) {
        Self.logPurchase(product: product, package: package, offer: promotionalOffer)

        if let sk1Product = product.sk1Product {
            guard let storeKit1Wrapper = self.storeKit1Wrapper(orFailWith: completion) else { return }
            let payment = storeKit1Wrapper.payment(with: sk1Product, discount: promotionalOffer?.sk1PromotionalOffer)
            self.purchase(sk1Product: sk1Product,
                          payment: payment,
                          package: package,
                          wrapper: storeKit1Wrapper,
                          completion: completion)
        } else if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
                  let sk2Product = product.sk2Product {
            self.purchase(sk2Product: sk2Product,
                          package: package,
                          promotionalOffer: promotionalOffer,
                          winBackOffer: winBackOffer,
                          metadata: metadata,
                          completion: completion)
        } else if product.isTestProduct {
            self.handleTestProduct(completion)
        } else {
            fatalError("Unrecognized product: \(product)")
        }
    }

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
                completion(nil,
                           nil,
                           ErrorUtils.storeProblemError(
                            withMessage: Strings.purchase.could_not_purchase_product_id_not_found.description
                           ).asPublicError,
                           false)
            }
            return
        }

        if !self.finishTransactions {
            Logger.warn(Strings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning)
        }

        payment.applicationUsername = self.appUserID

        self.cachePresentedOfferingContext(package: package, productIdentifier: productIdentifier)

        self.productsManager.cache(StoreProduct(sk1Product: sk1Product))

        let startTime = self.dateProvider.now()
        let promotionalOfferID = payment.paymentDiscount?.identifier

        let addPayment: Bool = self.addPurchaseCompletedCallback(
            productIdentifier: productIdentifier,
            completion: { [weak self] transaction, customerInfo, error, cancelled in
                guard let self = self else { return }

                self.trackPurchaseEventIfNeeded(startTime,
                                                successful: !cancelled && error == nil,
                                                productId: productIdentifier,
                                                promotionalOfferId: promotionalOfferID,
                                                winBackOfferApplied: false, // SK2 only
                                                storeKitVersion: .storeKit1,
                                                purchaseResult: nil, // SK2 only
                                                error: error)
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

                        self.postPaywallEventsIfNeeded()
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
                  winBackOffer: WinBackOffer?,
                  metadata: [String: String]? = nil,
                  completion: @escaping PurchaseCompletedBlock) {
        _ = Task<Void, Never> {
            do {
                let result: PurchaseResultData = try await self.purchase(
                    sk2Product: product,
                    package: package,
                    promotionalOffer: promotionalOffer,
                    winBackOffer: winBackOffer?.discount.sk2Discount,
                    metadata: metadata
                )

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
    // swiftlint:disable:next function_body_length
    func purchase(sk2Product: SK2Product,
                  package: Package?,
                  promotionalOffer: PromotionalOffer.SignedData? = nil,
                  winBackOffer: Product.SubscriptionOffer? = nil,
                  metadata: [String: String]? = nil) async throws -> PurchaseResultData {
        let result: Product.PurchaseResult
        var options: Set<Product.PurchaseOption> = [.simulatesAskToBuyInSandbox(Purchases.simulatesAskToBuyInSandbox)]

        if let uuid = UUID(uuidString: self.appUserID) {
            Logger.debug(Strings.storeKit.sk2_purchasing_added_uuid_option(uuid))
            options.insert(.appAccountToken(uuid))
        }

        let startTime = self.dateProvider.now()
        var winBackOfferApplied: Bool = false

        do {
            if let signedData = promotionalOffer {
                Logger.debug(Strings.storeKit.sk2_purchasing_added_promotional_offer_option(signedData.identifier))
                options.insert(try signedData.sk2PurchaseOption)
            }

            if let winBackOffer, #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                // Win-back offers weren't introduced until iOS 18 and Xcode 16, which shipped with
                // version 6.0 of the Swift compiler. The win-back symbols won't be found if compiled on
                // Xcode < 16.0, so we need to ensure that the Swift compiler 6.0 or higher is available.
#if compiler(>=6.0)
                Logger.debug(
                    Strings.storeKit.sk2_purchasing_added_winback_offer_option(winBackOffer.id ?? "unknown ID")
                )
                options.insert(.winBackOffer(winBackOffer))
                winBackOfferApplied = true
#endif
            }

            self.cachePresentedOfferingContext(package: package, productIdentifier: sk2Product.id)

            result = try await self.purchase(sk2Product, options)

            // The `purchase(sk2Product)` call can throw a `StoreKitError.userCancelled` error.
            // This detects if `Product.PurchaseResult.userCancelled` is true.
            let (userCancelled, transaction) = try await self.storeKit2TransactionListener
                .handle(purchaseResult: result, fromTransactionUpdate: false)

            if userCancelled, self.systemInfo.dangerousSettings.customEntitlementComputation {
                throw ErrorUtils.purchaseCancelledError()
            }

            let customerInfo: CustomerInfo

            if let transaction = transaction {
                customerInfo = try await self.handlePurchasedTransaction(transaction, .purchase, metadata)
                self.postPaywallEventsIfNeeded()
            } else {
                // `transaction` would be `nil` for `Product.PurchaseResult.pending` and
                // `Product.PurchaseResult.userCancelled`.
                customerInfo = try await self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                                               fetchPolicy: .cachedOrFetched)
            }

            self.trackPurchaseEventIfNeeded(startTime,
                                            successful: !userCancelled,
                                            productId: sk2Product.id,
                                            promotionalOfferId: promotionalOffer?.identifier,
                                            winBackOfferApplied: winBackOfferApplied,
                                            storeKitVersion: .storeKit2,
                                            purchaseResult: .init(purchaseResult: result),
                                            error: nil)
            return (transaction, customerInfo, userCancelled)
        } catch {
            return try await self.handleSK2ProductPurchaseError(error,
                                                                startTime: startTime,
                                                                productId: sk2Product.id,
                                                                promotionalOfferId: promotionalOffer?.identifier,
                                                                winBackOfferApplied: winBackOfferApplied)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func handleSK2ProductPurchaseError(
        _ error: Error,
        startTime: Date,
        productId: String,
        promotionalOfferId: String?,
        winBackOfferApplied: Bool
    ) async throws -> PurchaseResultData {

        if case StoreKitError.userCancelled = error {
            guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
                throw ErrorUtils.purchaseCancelledError()
            }

            self.trackPurchaseEventIfNeeded(startTime,
                                            successful: false,
                                            productId: productId,
                                            promotionalOfferId: promotionalOfferId,
                                            winBackOfferApplied: winBackOfferApplied,
                                            storeKitVersion: .storeKit2,
                                            purchaseResult: .userCancelled,
                                            error: StoreKitError.userCancelled.asPublicError)

            let customerInfo = try await self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                                                               fetchPolicy: .cachedOrFetched)
            return (transaction: nil, customerInfo: customerInfo, userCancelled: true)
        } else {
            guard !self.systemInfo.dangerousSettings.customEntitlementComputation else {
                throw error
            }

            let purchasesError: PurchasesError
            switch error {
            case let pError as PurchasesError:
                purchasesError = pError
            case let signedDataError as PromotionalOffer.SignedData.Error:
                purchasesError = ErrorUtils.invalidPromotionalOfferError(error: signedDataError,
                                                                         message: signedDataError.localizedDescription)
            case let backendError as BackendError:
                purchasesError = backendError.asPurchasesError
            default:
                purchasesError = ErrorUtils.purchasesError(withStoreKitError: error)
            }

            self.trackPurchaseEventIfNeeded(startTime,
                                            successful: false,
                                            productId: productId,
                                            promotionalOfferId: promotionalOfferId,
                                            winBackOfferApplied: winBackOfferApplied,
                                            storeKitVersion: .storeKit2,
                                            purchaseResult: nil,
                                            error: purchasesError.asPublicError)

            throw purchasesError
        }
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

    func cachePresentedOfferingContext(_ context: PresentedOfferingContext, productIdentifier: String) {
        self.presentedOfferingContextsByProductID.modify { $0[productIdentifier] = context }
    }

    func track(paywallEvent: PaywallEvent) {
        switch paywallEvent {
        case .impression:
            self.cachePresentedPaywall(paywallEvent)

        case .close:
            self.clearPresentedPaywall()

        case .cancel:
            break
        }
    }

    func postPaywallEventsIfNeeded(delayed: Bool = false) {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *),
              let manager = self.paywallEventsManager else { return }

        let delay: JitterableDelay
        if delayed {
            delay = .long
        } else {
            // When backgrounding, the app only has about 5 seconds to perform work
            delay = .none
        }
        self.operationDispatcher.dispatchOnWorkerThread(jitterableDelay: delay) {
            _ = try? await manager.flushEvents(count: PaywallEventsManager.defaultEventFlushCount)
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

    @available(iOS 16.4, macOS 14.4, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    internal func setSK2PurchaseIntentListener(
        _ storeKit2PurchaseIntentListener: StoreKit2PurchaseIntentListenerType
    ) {
        // We can't inject StoreKit2PurchaseIntentListener in the constructor since
        // it has different availability requirements than the constructor.

        if systemInfo.storeKitVersion == .storeKit2 {
            self._storeKit2PurchaseIntentListener = storeKit2PurchaseIntentListener
            Task {
                await self.storeKit2PurchaseIntentListener.set(delegate: self)
                await self.storeKit2PurchaseIntentListener.listenForPurchaseIntents()
            }
        }
    }

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

            if let discount = payment.paymentDiscount.map(PromotionalOffer.SignedData.init) {
                startPurchase = { completion in
                    self.purchase(product: product,
                                  package: nil,
                                  promotionalOffer: discount,
                                  metadata: nil) { transaction, customerInfo, error, cancelled in
                        completion(transaction, customerInfo, error, cancelled)
                    }
                }
            } else {
                startPurchase = { completion in
                    self.purchase(product: product,
                                  package: nil,
                                  promotionalOffer: nil,
                                  metadata: nil) { transaction, customerInfo, error, cancelled in
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

    // swiftlint:disable:next function_parameter_count
    func trackPurchaseEventIfNeeded(_ startTime: Date,
                                    successful: Bool,
                                    productId: String,
                                    promotionalOfferId: String?,
                                    winBackOfferApplied: Bool,
                                    storeKitVersion: StoreKitVersion,
                                    purchaseResult: DiagnosticsEvent.PurchaseResult?,
                                    error: PublicError?) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
        let diagnosticsTracker = self.diagnosticsTracker {
            let responseTime = self.dateProvider.now().timeIntervalSince(startTime)
            let errorMessage = (error?.userInfo[NSUnderlyingErrorKey] as? Error)?.localizedDescription
                ?? error?.localizedDescription
            let errorCode = error?.code
            let storeKitErrorDescription = StoreKitErrorUtils.extractStoreKitErrorDescription(from: error)
            diagnosticsTracker.trackPurchaseRequest(wasSuccessful: successful,
                                                    storeKitVersion: storeKitVersion,
                                                    errorMessage: errorMessage,
                                                    errorCode: errorCode,
                                                    storeKitErrorDescription: storeKitErrorDescription,
                                                    productId: productId,
                                                    promotionalOfferId: promotionalOfferId,
                                                    winBackOfferApplied: winBackOfferApplied,
                                                    purchaseResult: purchaseResult,
                                                    responseTime: responseTime)
        }
    }

    func trackProductsStartedIfNeeded(requestedProductIds: Set<String>) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           let diagnosticsTracker = self.diagnosticsTracker {
            diagnosticsTracker.trackProductsStarted(requestedProductIds: requestedProductIds)
        }
    }

    func trackProductsResultIfNeeded(requestedProductIds: Set<String>,
                                     notFoundProductIds: Set<String>?,
                                     error: PurchasesError?,
                                     startTime: Date) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           let diagnosticsTracker = self.diagnosticsTracker {
            let responseTime = self.dateProvider.now().timeIntervalSince(startTime)
            diagnosticsTracker.trackProductsResult(requestedProductIds: requestedProductIds,
                                                   notFoundProductIds: notFoundProductIds,
                                                   errorMessage: error?.localizedDescription,
                                                   errorCode: error?.errorCode,
                                                   responseTime: responseTime)
        }
    }

    func trackSyncOrRestorePurchasesStartedIfNeeded(_ receiptRefreshPolicy: ReceiptRefreshPolicy) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           let diagnosticsTracker = self.diagnosticsTracker {
            let isRestore = receiptRefreshPolicy == .always
            if isRestore {
                diagnosticsTracker.trackRestorePurchasesStarted()
            } else {
                diagnosticsTracker.trackSyncPurchasesStarted()
            }
        }
    }

    func trackSyncOrRestorePurchasesResultIfNeeded(_ receiptRefreshPolicy: ReceiptRefreshPolicy,
                                                   startTime: Date,
                                                   error: PurchasesError?) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           let diagnosticsTracker = self.diagnosticsTracker {
            let responseTime = self.dateProvider.now().timeIntervalSince(startTime)
            let isRestore = receiptRefreshPolicy == .always
            if isRestore {
                diagnosticsTracker.trackRestorePurchasesResult(errorMessage: error?.localizedDescription,
                                                               errorCode: error?.errorCode,
                                                               responseTime: responseTime)
            } else {
                diagnosticsTracker.trackSyncPurchasesResult(errorMessage: error?.localizedDescription,
                                                            errorCode: error?.errorCode,
                                                            responseTime: responseTime)
            }
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
        let adServicesToken = await self.attribution.unsyncedAdServicesToken
        let transactionData: PurchasedTransactionData = .init(
            appUserID: self.appUserID,
            presentedOfferingContext: nil,
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

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension PurchasesOrchestrator: StoreKit2PurchaseIntentListenerDelegate {

    // swiftlint:disable:next function_body_length
    func storeKit2PurchaseIntentListener(
        _ listener: any StoreKit2PurchaseIntentListenerType,
        purchaseIntent: StorePurchaseIntent
    ) async {
        // Making the extension unavailable on tvOS & watchOS doesn't
        // stop the compiler from checking availability in the functions.
        // We also need to ensure that we're on Xcode >= 15.3, since that is when
        // PurchaseIntents were first made available on macOS.
        #if !os(tvOS) && !os(watchOS) && compiler(>=5.10)

        guard let purchaseIntent = purchaseIntent.purchaseIntent else { return }
        let storeProduct = StoreProduct(sk2Product: purchaseIntent.product)

        delegate?.readyForPromotedProduct(storeProduct) { completion in

            var attemptedToPurchaseWithASubscriptionOffer = false

            if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                #if compiler(>=6.0)
                if let offer = purchaseIntent.offer {
                    switch offer.type {

                    // The `OfferType.winBack` case was added in iOS 18.0, but
                    // it's not recognized by Xcode versions <16.0
                    case .winBack:
                        Task {
                            do {
                                attemptedToPurchaseWithASubscriptionOffer = true

                                let result = try await self.purchase(
                                    sk2Product: purchaseIntent.product,
                                    package: nil,
                                    promotionalOffer: nil,
                                    winBackOffer: offer
                                )

                                self.operationDispatcher.dispatchOnMainActor {
                                    completion(result.transaction, result.customerInfo, nil, result.userCancelled)
                                }
                            } catch {
                                self.operationDispatcher.dispatchOnMainActor {
                                    completion(
                                        nil,
                                        nil,
                                        ErrorUtils.purchasesError(withUntypedError: error).asPublicError,
                                        false
                                    )
                                }
                            }
                        }
                    default:
                        // PurchaseIntents are only supported for promoted purchases on the App Store
                        // and win-back offers, so we don't want to handle any other offers here.
                        break
                    }
                }
                #endif
            }

            if !attemptedToPurchaseWithASubscriptionOffer {
                self.purchase(
                    product: storeProduct,
                    package: nil
                ) { transaction, customerInfo, publicError, userCancelled in
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(transaction, customerInfo, publicError, userCancelled)
                    }
                }
            }
        }

        #endif
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

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       initiationSource: ProductRequestData.InitiationSource,
                       completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        self.trackSyncOrRestorePurchasesStartedIfNeeded(receiptRefreshPolicy)
        let startTime = self.dateProvider.now()
        // Don't log anything unless the flag was explicitly set.
        let allowSharingAppStoreAccountSet = self._allowSharingAppStoreAccount.value != nil
        if allowSharingAppStoreAccountSet, !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.purchase.restorepurchases_called_with_allow_sharing_appstore_account_false)
        }

        let completionWithTracking: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void) = { [weak self] result in
            self?.trackSyncOrRestorePurchasesResultIfNeeded(receiptRefreshPolicy,
                                                            startTime: startTime,
                                                            error: result.error)
            completion?(result)
        }

        if self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable,
           #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self.syncPurchasesSK2(isRestore: isRestore,
                                  initiationSource: initiationSource,
                                  completion: completionWithTracking)
        } else {
            self.syncPurchasesSK1(receiptRefreshPolicy: receiptRefreshPolicy,
                                  isRestore: isRestore,
                                  initiationSource: initiationSource,
                                  completion: completionWithTracking)
        }
    }

    func syncPurchasesSK1(receiptRefreshPolicy: ReceiptRefreshPolicy,
                          isRestore: Bool,
                          initiationSource: ProductRequestData.InitiationSource,
                          completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        let currentAppUserID = self.appUserID
        let unsyncedAttributes = self.unsyncedAttributes

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
                let cachedCustomerInfo = try? self.customerInfoManager.cachedCustomerInfo(appUserID: currentAppUserID)

                if !hasTransactions,
                    let customerInfo = cachedCustomerInfo,
                    customerInfo.originalPurchaseDate != nil {
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
                        presentedOfferingContext: nil,
                        unsyncedAttributes: unsyncedAttributes,
                        storefront: productRequestData?.storefront,
                        source: .init(isRestore: isRestore, initiationSource: initiationSource)
                    )

                    self.backend.post(receipt: .receipt(receiptData),
                                      productData: productRequestData,
                                      transactionData: transactionData,
                                      observerMode: self.observerMode) { result in
                        self.handleReceiptPost(result: result,
                                               transactionData: transactionData,
                                               subscriberAttributes: unsyncedAttributes,
                                               adServicesToken: nil,
                                               completion: completion)
                    }
                }
            }
        }
    }

    // swiftlint:disable function_body_length
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func syncPurchasesSK2(isRestore: Bool,
                                  initiationSource: ProductRequestData.InitiationSource,
                                  completion: (@Sendable (Result<CustomerInfo, PurchasesError>) -> Void)?) {
        let currentAppUserID = self.appUserID
        let unsyncedAttributes = self.unsyncedAttributes

        _ = Task<Void, Never> {
            let transaction = await self.transactionFetcher.firstVerifiedTransaction
            let appTransactionJWS = await self.transactionFetcher.appTransactionJWS

            guard let transaction = transaction, let jwsRepresentation = transaction.jwsRepresentation else {
                // No transactions are present. If we have the originalPurchaseDate and originalApplicationVersion
                // in the cached CustomerInfo, return it. Otherwise, post the AppTransaction.
                let cachedCustomerInfo = try? self.customerInfoManager.cachedCustomerInfo(appUserID: currentAppUserID)

                if let cachedCustomerInfo,
                   cachedCustomerInfo.originalPurchaseDate != nil,
                   cachedCustomerInfo.originalApplicationVersion != nil {
                    self.operationDispatcher.dispatchOnMainActor {
                        completion?(.success(cachedCustomerInfo))
                    }
                    return
                }

                let transactionData: PurchasedTransactionData = .init(
                    appUserID: currentAppUserID,
                    presentedOfferingContext: nil,
                    unsyncedAttributes: unsyncedAttributes,
                    source: .init(
                        isRestore: isRestore,
                        initiationSource: initiationSource
                    )
                )

                self.backend.post(receipt: .empty,
                                  productData: nil,
                                  transactionData: transactionData,
                                  observerMode: self.observerMode,
                                  appTransaction: appTransactionJWS) { result in

                    self.handleReceiptPost(result: result,
                                           transactionData: transactionData,
                                           subscriberAttributes: unsyncedAttributes,
                                           adServicesToken: nil,
                                           completion: completion)
                }
                return
            }

            let receipt = await self.encodedReceipt(transaction: transaction, jwsRepresentation: jwsRepresentation)

            self.createProductRequestData(with: transaction.productIdentifier) { productRequestData in
                let transactionData: PurchasedTransactionData = .init(
                    appUserID: currentAppUserID,
                    presentedOfferingContext: nil,
                    unsyncedAttributes: unsyncedAttributes,
                    storefront: transaction.storefront,
                    source: .init(isRestore: isRestore, initiationSource: initiationSource)
                )

                self.backend.post(receipt: receipt,
                                  productData: productRequestData,
                                  transactionData: transactionData,
                                  observerMode: self.observerMode,
                                  appTransaction: appTransactionJWS) { result in
                    self.handleReceiptPost(result: result,
                                           transactionData: transactionData,
                                           subscriberAttributes: unsyncedAttributes,
                                           adServicesToken: nil,
                                           completion: completion)
                }
            }
        }
    }

    func handleReceiptPost(result: Result<CustomerInfo, BackendError>,
                           transactionData: PurchasedTransactionData?,
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
                                 transactionData: PurchasedTransactionData?,
                                 subscriberAttributes: SubscriberAttribute.Dictionary,
                                 adServicesToken: String?) {
        switch result {
        case let .success(customerInfo):
            self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: self.appUserID)

        case .failure:
            // Cache paywall again in case purchase is retried.
            if let paywall = transactionData?.presentedPaywall {
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
        let offeringContext = self.getAndRemovePresentedOfferingContext(for: purchasedTransaction)
        let paywall = self.getAndRemovePresentedPaywall()
        let unsyncedAttributes = self.unsyncedAttributes
        self.attribution.unsyncedAdServicesToken { adServicesToken in
            let transactionData: PurchasedTransactionData = .init(
                appUserID: self.appUserID,
                presentedOfferingContext: offeringContext,
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

    func cachePresentedOfferingContext(package: Package?, productIdentifier: String) {
        if let package = package {
            self.cachePresentedOfferingContext(package.presentedOfferingContext,
                                               productIdentifier: productIdentifier)
        }
    }

    func cachePresentedPaywall(_ paywall: PaywallEvent) {
        Logger.verbose(Strings.paywalls.caching_presented_paywall)
        self.presentedPaywall.value = paywall
    }

    func clearPresentedPaywall() {
        Logger.verbose(Strings.paywalls.clearing_presented_paywall)
        self.presentedPaywall.value = nil
    }

    func getAndRemovePresentedOfferingContext(for productIdentifier: String) -> PresentedOfferingContext? {
        return self.presentedOfferingContextsByProductID.modify {
            $0.removeValue(forKey: productIdentifier)
        }
    }

    func getAndRemovePresentedOfferingContext(for transaction: StoreTransaction) -> PresentedOfferingContext? {
        return self.getAndRemovePresentedOfferingContext(for: transaction.productIdentifier)
    }

    func getAndRemovePresentedPaywall() -> PaywallEvent? {
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

        self.createProductRequestData(with: productIdentifier, completion: completion)
    }

    func createProductRequestData(
        with productIdentifier: String,
        completion: @escaping (ProductRequestData?) -> Void
    ) {
        self.productsManager.products(withIdentifiers: [productIdentifier]) { products in
            let result = products.value?.first.map {
                ProductRequestData(with: $0, storefront: self.systemInfo.storefront)
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

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2PromotionalOffer(forProductDiscount productDiscount: StoreProductDiscountType,
                             discountIdentifier: String,
                             product: StoreProductType,
                             subscriptionGroupIdentifier: String,
                             completion: @escaping @Sendable (Result<PromotionalOffer, PurchasesError>) -> Void) {

        _ = Task<Void, Never> {
            let transaction = await self.transactionFetcher.firstVerifiedAutoRenewableTransaction
            guard let transaction = transaction, let jwsRepresentation = transaction.jwsRepresentation  else {
                // Promotional offers require an existing or expired subscription to redeem a promotional offer.
                // Fail early if there are no transactions.
                completion(.failure(ErrorUtils.ineligibleError()))
                return
            }

            let receipt = await self.encodedReceipt(transaction: transaction, jwsRepresentation: jwsRepresentation)

            self.handlePromotionalOffer(forProductDiscount: productDiscount,
                                        discountIdentifier: discountIdentifier,
                                        product: product,
                                        subscriptionGroupIdentifier: subscriptionGroupIdentifier,
                                        receipt: receipt) { result in
                completion(result)
            }
        }
    }

    func sk1PromotionalOffer(forProductDiscount productDiscount: StoreProductDiscountType,
                             discountIdentifier: String,
                             product: StoreProductType,
                             subscriptionGroupIdentifier: String,
                             completion: @escaping @Sendable (Result<PromotionalOffer, PurchasesError>) -> Void) {
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
                self.handlePromotionalOffer(forProductDiscount: productDiscount,
                                            discountIdentifier: discountIdentifier,
                                            product: product,
                                            subscriptionGroupIdentifier: subscriptionGroupIdentifier,
                                            receipt: .receipt(receiptData)) { result in
                    completion(result)
                }
            }
        }
    }

    // swiftlint:disable:next function_parameter_count
    func handlePromotionalOffer(forProductDiscount productDiscount: StoreProductDiscountType,
                                discountIdentifier: String,
                                product: StoreProductType,
                                subscriptionGroupIdentifier: String,
                                receipt: EncodedAppleReceipt,
                                completion: @escaping @Sendable (Result<PromotionalOffer, PurchasesError>) -> Void) {
        self.backend.offerings.post(offerIdForSigning: discountIdentifier,
                                    productIdentifier: product.productIdentifier,
                                    subscriptionGroup: subscriptionGroupIdentifier,
                                    receipt: receipt,
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

private extension PurchasesOrchestrator {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func encodedReceipt(transaction: StoreTransactionType, jwsRepresentation: String) async -> EncodedAppleReceipt {
        if transaction.environment == .xcode {
            return .sk2receipt(await self.transactionFetcher.fetchReceipt(containing: transaction))
        } else {
            return .jws(jwsRepresentation)
        }
    }

    static func logPurchase(product: StoreProduct,
                            package: Package?,
                            offer: PromotionalOffer.SignedData? = nil,
                            metadata: [String: String]? = nil) {
        let string: PurchaseStrings = .purchasing_product(product, package, offer, metadata)
        Logger.purchase(string)
    }

}

// MARK: - Async extensions

extension PurchasesOrchestrator {

    private func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        _ initiationSource: ProductRequestData.InitiationSource,
        _ metadata: [String: String]?
    ) async throws -> CustomerInfo {
        let storefront = await Storefront.currentStorefront
        let offeringContext = self.getAndRemovePresentedOfferingContext(for: transaction)
        let paywall = self.getAndRemovePresentedPaywall()
        let unsyncedAttributes = self.unsyncedAttributes
        let adServicesToken = await self.attribution.unsyncedAdServicesToken
        let transactionData: PurchasedTransactionData = .init(
            appUserID: self.appUserID,
            presentedOfferingContext: offeringContext,
            presentedPaywall: paywall,
            unsyncedAttributes: unsyncedAttributes,
            metadata: metadata,
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchasesOrchestrator {

    private func syncDiagnosticsIfNeeded() async {
        do {
            try await diagnosticsSynchronizer?.syncDiagnosticsIfNeeded()
        } catch {
            Logger.error(Strings.diagnostics.could_not_synchronize_diagnostics(error: error))
        }
    }

    private func setSK2DelegateAndStartListening() async {
        await storeKit2TransactionListener.set(delegate: self)
        if systemInfo.storeKitVersion == .storeKit2 {
            await storeKit2TransactionListener.listenForTransactions()
        }
    }

    @available(iOS 16.4, macOS 14.4, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    private func setSK2PurchaseIntentDelegateAndStartListening() async {
        await storeKit2TransactionListener.set(delegate: self)
        if systemInfo.storeKitVersion == .storeKit2 {
            await storeKit2TransactionListener.listenForTransactions()
        }
    }
}

// MARK: - Win-Back Offer Fetching
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension PurchasesOrchestrator {
    func eligibleWinBackOffers(
        forProduct product: StoreProduct
    ) async throws -> [WinBackOffer] {

        // winBackOfferEligibilityCalculator is only nil when running in SK1 mode
        guard let winBackOfferEligibilityCalculator = self.winBackOfferEligibilityCalculator,
                self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable
        else {
            throw ErrorUtils.featureNotSupportedWithStoreKit1Error()
        }

        return try await winBackOfferEligibilityCalculator.eligibleWinBackOffers(forProduct: product)
    }
}

// MARK: - Application Lifecycle
extension PurchasesOrchestrator {
    func handleApplicationDidBecomeActive() {

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           self.observerMode && self.systemInfo.storeKitVersion == .storeKit2 {
            Task(priority: .utility) {
                await self.storeKit2ObserverModePurchaseDetector?.detectUnobservedTransactions(delegate: self)
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchasesOrchestrator: StoreKit2ObserverModePurchaseDetectorDelegate {

    func handleSK2ObserverModeTransaction(verifiedTransaction: StoreKit.Transaction,
                                          jwsRepresentation: String) async throws {
        try await self.storeKit2TransactionListener.handleSK2ObserverModeTransaction(
            verifiedTransaction: verifiedTransaction,
            jwsRepresentation: jwsRepresentation
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
fileprivate extension DiagnosticsEvent.PurchaseResult {

    init?(purchaseResult: Product.PurchaseResult) {
        switch purchaseResult {
        case .success(.verified):
            self = .verified
        case .success(.unverified):
            self = .unverified
        case .userCancelled:
            self = .userCancelled
        case .pending:
            self = .pending
        @unknown default:
            Logger.appleWarning(Strings.storeKit.skunknown_purchase_result(String(describing: purchaseResult)))
            return nil
        }
    }

}
