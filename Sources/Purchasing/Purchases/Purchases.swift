//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases.swift
//
//  Created by Joshua Liebowitz on 8/18/21.
//

// swiftlint:disable file_length type_body_length

// Docs are inherited from `PurchasesType` and `PurchasesSwiftType`:
// swiftlint:disable missing_docs

import Foundation
import StoreKit

// MARK: Block definitions

/**
 Result for ``Purchases/purchase(product:)``.
 Counterpart of `PurchaseCompletedBlock` for `async` APIs.
 */
public typealias PurchaseResultData = (transaction: StoreTransaction?,
                                       customerInfo: CustomerInfo,
                                       userCancelled: Bool)

/**
 Completion block for ``Purchases/purchase(product:completion:)``
 */
public typealias PurchaseCompletedBlock = @MainActor @Sendable (StoreTransaction?,
                                                                CustomerInfo?,
                                                                PublicError?,
                                                                Bool) -> Void

/**
 Block for starting purchases in ``PurchasesDelegate/purchases(_:readyForPromotedProduct:purchase:)``
 */
public typealias StartPurchaseBlock = (@escaping PurchaseCompletedBlock) -> Void

/**
 * ``Purchases`` is the entry point for RevenueCat.framework. It should be instantiated as soon as your app has a unique
 * user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random
 * user identifier.
 *  - Warning: Only one instance of Purchases should be instantiated at a time! Use a configure method to let the
 *  framework handle the singleton instance for you.
 */
@objc(RCPurchases) public final class Purchases: NSObject, PurchasesType, PurchasesSwiftType {

    /// Returns the already configured instance of ``Purchases``.
    /// - Warning: this method will crash with `fatalError` if ``Purchases`` has not been initialized through
    /// ``configure(withAPIKey:)`` or one of its overloads. If there's a chance that may have not happened yet,
    /// you can use ``isConfigured`` to check if it's safe to call.
    /// ### Related symbols
    /// - ``isConfigured``
    @objc(sharedPurchases)
    public static var shared: Purchases {
        guard let purchases = Self.purchases.value else {
            fatalError(Strings.purchase.purchases_nil.description)
        }

        return purchases
    }

    private static let purchases: Atomic<Purchases?> = nil

    /// Returns `true` if RevenueCat has already been initialized through ``configure(withAPIKey:)``
    /// or one of is overloads.
    @objc public static var isConfigured: Bool { Self.purchases.value != nil }

    @objc public var delegate: PurchasesDelegate? {
        get { self.privateDelegate }
        set {
            guard newValue !== self.privateDelegate else {
                Logger.warn(Strings.purchase.purchases_delegate_set_multiple_times)
                return
            }

            if newValue == nil {
                Logger.info(Strings.purchase.purchases_delegate_set_to_nil)
            }

            self.privateDelegate = newValue
            Logger.debug(Strings.configure.delegate_set)

            // Sends cached customer info (if exists) to delegate as latest
            // customer info may have already been observed and sent by the monitor
            self.sendCachedCustomerInfoToDelegateIfExists()
        }
    }

    private weak var privateDelegate: PurchasesDelegate?
    private let operationDispatcher: OperationDispatcher

    /**
     * Used to set the log level. Useful for debugging issues with the lovely team @RevenueCat.
     *
     * #### Related Symbols
     * - ``logHandler``
     * - ``verboseLogHandler``
     */
    @objc public static var logLevel: LogLevel {
        get { Logger.logLevel }
        set { Logger.logLevel = newValue }
    }

    /**
     * Set this property to your proxy URL before configuring ``Purchases`` *only* if you've received a proxy key value
     * from your RevenueCat contact.
     */
    @objc public static var proxyURL: URL? {
        get { SystemInfo.proxyURL }
        set { SystemInfo.proxyURL = newValue }
    }

    /**
     * Set this property to true *only* if you're transitioning an existing Mac app from the Legacy
     * Mac App Store into the Universal Store, and you've configured your RevenueCat app accordingly.
     * Contact RevenueCat support before using this.
     */
    @objc public static var forceUniversalAppStore: Bool {
        get { SystemInfo.forceUniversalAppStore }
        set { SystemInfo.forceUniversalAppStore = newValue }
    }

    /**
     * Set this property to true *only* when testing the ask-to-buy / SCA purchases flow.
     * More information [available here](https://rev.cat/ask-to-buy).
     * #### Related Articles
     * -  [Approve what kids buy with Ask to Buy](https://rev.cat/approve-kids-purchases-apple)
     */
    @available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *)
    @objc public static var simulatesAskToBuyInSandbox: Bool {
        get { StoreKit1Wrapper.simulatesAskToBuyInSandbox }
        set { StoreKit1Wrapper.simulatesAskToBuyInSandbox = newValue }
    }

    /**
     * Indicates whether the user is allowed to make payments.
     * [More information on when this might be `false` here](https://rev.cat/can-make-payments-apple)
     */
    @objc public static func canMakePayments() -> Bool { StoreKit1Wrapper.canMakePayments() }

    /**
     * Set a custom log handler for redirecting logs to your own logging system.
     *
     * By default, this sends ``LogLevel/info``, ``LogLevel/warn``, and ``LogLevel/error`` messages.
     * If you wish to receive Debug level messages, set the log level to ``LogLevel/debug``.
     *
     * - Note:``verboseLogHandler`` provides additional information.
     *
     * #### Related Symbols
     * - ``verboseLogHandler``
     * - ``logLevel``
     */
    @objc public static var logHandler: LogHandler {
        get {
            return { level, message in
                self.verboseLogHandler(level, message, nil, nil, 0)
            }
        }

        set {
            self.verboseLogHandler = { level, message, _, _, _ in
                newValue(level, message)
            }
        }
    }

    /**
     * Set a custom log handler for redirecting logs to your own logging system.
     *
     * By default, this sends ``LogLevel/info``, ``LogLevel/warn``, and ``LogLevel/error`` messages.
     * If you wish to receive Debug level messages, set the log level to ``LogLevel/debug``.
     *
     * - Note: you can use ``logHandler`` if you don't need filename information.
     *
     * #### Related Symbols
     * - ``logHandler``
     * - ``logLevel``
     */
    @objc public static var verboseLogHandler: VerboseLogHandler {
        get { Logger.logHandler }
        set { Logger.logHandler = newValue }
    }

    /**
     * Setting this to `true` adds additional information to the default log handler:
     *  Filename, line, and method data.
     * You can also access that information for your own logging system by using ``verboseLogHandler``.
     *
     * #### Related Symbols
     * - ``verboseLogHandler``
     * - ``logLevel``
     */
    @objc public static var verboseLogs: Bool {
        get { return Logger.verbose }
        set { Logger.verbose = newValue }
    }

    /// Current version of the ``Purchases`` framework.
    @objc public static var frameworkVersion: String { SystemInfo.frameworkVersion }

    @objc public let attribution: Attribution

    @objc public var finishTransactions: Bool {
        get { self.systemInfo.finishTransactions }
        set { self.systemInfo.finishTransactions = newValue }
    }

    private let attributionFetcher: AttributionFetcher
    private let attributionPoster: AttributionPoster
    private let backend: Backend
    private let deviceCache: DeviceCache
    private let identityManager: IdentityManager
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let offeringsFactory: OfferingsFactory
    private let offeringsManager: OfferingsManager
    private let productsManager: ProductsManagerType
    private let customerInfoManager: CustomerInfoManager
    private let trialOrIntroPriceEligibilityChecker: CachingTrialOrIntroPriceEligibilityChecker
    private let purchasesOrchestrator: PurchasesOrchestrator
    private let receiptFetcher: ReceiptFetcher
    private let requestFetcher: StoreKitRequestFetcher
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private var customerInfoObservationDisposable: (() -> Void)?

    // swiftlint:disable:next function_body_length
    convenience init(apiKey: String,
                     appUserID: String?,
                     userDefaults: UserDefaults? = nil,
                     observerMode: Bool = false,
                     platformInfo: PlatformInfo? = Purchases.platformInfo,
                     responseVerificationLevel: Signing.ResponseVerificationLevel,
                     storeKit2Setting: StoreKit2Setting = .default,
                     storeKitTimeout: TimeInterval = Configuration.storeKitRequestTimeoutDefault,
                     networkTimeout: TimeInterval = Configuration.networkTimeoutDefault,
                     dangerousSettings: DangerousSettings? = nil) {
        if userDefaults != nil {
            Logger.debug(Strings.configure.using_custom_user_defaults)
        }

        let operationDispatcher: OperationDispatcher = .default
        let receiptRefreshRequestFactory = ReceiptRefreshRequestFactory()
        let fetcher = StoreKitRequestFetcher(requestFactory: receiptRefreshRequestFactory,
                                             operationDispatcher: operationDispatcher)
        let systemInfo: SystemInfo
        do {
            systemInfo = try SystemInfo(platformInfo: platformInfo,
                                        finishTransactions: !observerMode,
                                        operationDispatcher: operationDispatcher,
                                        storeKit2Setting: storeKit2Setting,
                                        responseVerificationLevel: responseVerificationLevel,
                                        dangerousSettings: dangerousSettings)
        } catch {
            fatalError(error.localizedDescription)
        }

        let receiptFetcher = ReceiptFetcher(requestFetcher: fetcher, systemInfo: systemInfo)
        let eTagManager = ETagManager()
        let attributionTypeFactory = AttributionTypeFactory()
        let attributionFetcher = AttributionFetcher(attributionFactory: attributionTypeFactory, systemInfo: systemInfo)
        let backend = Backend(apiKey: apiKey,
                              systemInfo: systemInfo,
                              httpClientTimeout: networkTimeout,
                              eTagManager: eTagManager,
                              operationDispatcher: operationDispatcher,
                              attributionFetcher: attributionFetcher)

        let paymentQueueWrapper: EitherPaymentQueueWrapper = systemInfo.storeKit2Setting.shouldOnlyUseStoreKit2
            ? .right(.init())
            : .left(.init(operationDispatcher: operationDispatcher, sandboxEnvironmentDetector: systemInfo))

        let offeringsFactory = OfferingsFactory()
        let userDefaults = userDefaults ?? UserDefaults.computeDefault()
        let deviceCache = DeviceCache(sandboxEnvironmentDetector: systemInfo, userDefaults: userDefaults)
        let receiptParser = PurchasesReceiptParser.default
        let transactionsManager = TransactionsManager(receiptParser: receiptParser)
        let customerInfoManager = CustomerInfoManager(operationDispatcher: operationDispatcher,
                                                      deviceCache: deviceCache,
                                                      backend: backend,
                                                      systemInfo: systemInfo)
        let attributionDataMigrator = AttributionDataMigrator()
        let subscriberAttributesManager = SubscriberAttributesManager(backend: backend,
                                                                      deviceCache: deviceCache,
                                                                      operationDispatcher: operationDispatcher,
                                                                      attributionFetcher: attributionFetcher,
                                                                      attributionDataMigrator: attributionDataMigrator)
        let identityManager = IdentityManager(deviceCache: deviceCache,
                                              backend: backend,
                                              customerInfoManager: customerInfoManager,
                                              attributeSyncing: subscriberAttributesManager,
                                              appUserID: appUserID)
        let attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                                  currentUserProvider: identityManager,
                                                  backend: backend,
                                                  attributionFetcher: attributionFetcher,
                                                  subscriberAttributesManager: subscriberAttributesManager)
        let subscriberAttributes = Attribution(subscriberAttributesManager: subscriberAttributesManager,
                                               currentUserProvider: identityManager,
                                               attributionPoster: attributionPoster)
        let productsRequestFactory = ProductsRequestFactory()
        let productsManager = CachingProductsManager(
            manager: ProductsManager(productsRequestFactory: productsRequestFactory,
                                     systemInfo: systemInfo,
                                     requestTimeout: storeKitTimeout)
        )
        let introCalculator = IntroEligibilityCalculator(productsManager: productsManager, receiptParser: receiptParser)
        let offeringsManager = OfferingsManager(deviceCache: deviceCache,
                                                operationDispatcher: operationDispatcher,
                                                systemInfo: systemInfo,
                                                backend: backend,
                                                offeringsFactory: offeringsFactory,
                                                productsManager: productsManager)
        let manageSubsHelper = ManageSubscriptionsHelper(systemInfo: systemInfo,
                                                         customerInfoManager: customerInfoManager,
                                                         currentUserProvider: identityManager)
        let beginRefundRequestHelper = BeginRefundRequestHelper(systemInfo: systemInfo,
                                                                customerInfoManager: customerInfoManager,
                                                                currentUserProvider: identityManager)
        let purchasesOrchestrator: PurchasesOrchestrator = {
            if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
                return .init(
                    productsManager: productsManager,
                    paymentQueueWrapper: paymentQueueWrapper,
                    systemInfo: systemInfo,
                    subscriberAttributes: subscriberAttributes,
                    operationDispatcher: operationDispatcher,
                    receiptFetcher: receiptFetcher,
                    receiptParser: receiptParser,
                    customerInfoManager: customerInfoManager,
                    backend: backend,
                    currentUserProvider: identityManager,
                    transactionsManager: transactionsManager,
                    deviceCache: deviceCache,
                    offeringsManager: offeringsManager,
                    manageSubscriptionsHelper: manageSubsHelper,
                    beginRefundRequestHelper: beginRefundRequestHelper,
                    storeKit2TransactionListener: StoreKit2TransactionListener(delegate: nil),
                    storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil)
                )
            } else {
                return .init(
                    productsManager: productsManager,
                    paymentQueueWrapper: paymentQueueWrapper,
                    systemInfo: systemInfo,
                    subscriberAttributes: subscriberAttributes,
                    operationDispatcher: operationDispatcher,
                    receiptFetcher: receiptFetcher,
                    receiptParser: receiptParser,
                    customerInfoManager: customerInfoManager,
                    backend: backend,
                    currentUserProvider: identityManager,
                    transactionsManager: transactionsManager,
                    deviceCache: deviceCache,
                    offeringsManager: offeringsManager,
                    manageSubscriptionsHelper: manageSubsHelper,
                    beginRefundRequestHelper: beginRefundRequestHelper
                )
            }
        }()

        let trialOrIntroPriceChecker = TrialOrIntroPriceEligibilityChecker(systemInfo: systemInfo,
                                                                           receiptFetcher: receiptFetcher,
                                                                           introEligibilityCalculator: introCalculator,
                                                                           backend: backend,
                                                                           currentUserProvider: identityManager,
                                                                           operationDispatcher: operationDispatcher,
                                                                           productsManager: productsManager)

        self.init(appUserID: appUserID,
                  requestFetcher: fetcher,
                  receiptFetcher: receiptFetcher,
                  attributionFetcher: attributionFetcher,
                  attributionPoster: attributionPoster,
                  backend: backend,
                  paymentQueueWrapper: paymentQueueWrapper,
                  userDefaults: userDefaults,
                  notificationCenter: .default,
                  systemInfo: systemInfo,
                  offeringsFactory: offeringsFactory,
                  deviceCache: deviceCache,
                  identityManager: identityManager,
                  subscriberAttributes: subscriberAttributes,
                  operationDispatcher: operationDispatcher,
                  customerInfoManager: customerInfoManager,
                  productsManager: productsManager,
                  offeringsManager: offeringsManager,
                  purchasesOrchestrator: purchasesOrchestrator,
                  trialOrIntroPriceEligibilityChecker: trialOrIntroPriceChecker)
    }

    init(appUserID: String?,
         requestFetcher: StoreKitRequestFetcher,
         receiptFetcher: ReceiptFetcher,
         attributionFetcher: AttributionFetcher,
         attributionPoster: AttributionPoster,
         backend: Backend,
         paymentQueueWrapper: EitherPaymentQueueWrapper,
         userDefaults: UserDefaults,
         notificationCenter: NotificationCenter,
         systemInfo: SystemInfo,
         offeringsFactory: OfferingsFactory,
         deviceCache: DeviceCache,
         identityManager: IdentityManager,
         subscriberAttributes: Attribution,
         operationDispatcher: OperationDispatcher,
         customerInfoManager: CustomerInfoManager,
         productsManager: ProductsManagerType,
         offeringsManager: OfferingsManager,
         purchasesOrchestrator: PurchasesOrchestrator,
         trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType
    ) {
        Logger.debug(Strings.configure.debug_enabled, fileName: nil)
        if systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
            Logger.info(Strings.configure.store_kit_2_enabled, fileName: nil)
        }
        if systemInfo.observerMode {
            Logger.debug(Strings.configure.observer_mode_enabled, fileName: nil)
        }
        Logger.debug(Strings.configure.sdk_version(Self.frameworkVersion), fileName: nil)
        Logger.debug(Strings.configure.bundle_id(SystemInfo.bundleIdentifier), fileName: nil)
        Logger.debug(Strings.configure.system_version(SystemInfo.systemVersion), fileName: nil)
        Logger.debug(Strings.configure.is_simulator(SystemInfo.isRunningInSimulator), fileName: nil)
        Logger.user(Strings.configure.initial_app_user_id(isSet: appUserID != nil), fileName: nil)

        self.requestFetcher = requestFetcher
        self.receiptFetcher = receiptFetcher
        self.attributionFetcher = attributionFetcher
        self.attributionPoster = attributionPoster
        self.backend = backend
        self.paymentQueueWrapper = paymentQueueWrapper
        self.offeringsFactory = offeringsFactory
        self.deviceCache = deviceCache
        self.identityManager = identityManager
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.systemInfo = systemInfo
        self.attribution = subscriberAttributes
        self.operationDispatcher = operationDispatcher
        self.customerInfoManager = customerInfoManager
        self.productsManager = productsManager
        self.offeringsManager = offeringsManager
        self.purchasesOrchestrator = purchasesOrchestrator
        self.trialOrIntroPriceEligibilityChecker = .create(with: trialOrIntroPriceEligibilityChecker)

        super.init()

        Logger.verbose(Strings.configure.purchases_init(self, paymentQueueWrapper))

        self.purchasesOrchestrator.delegate = self

        // Don't update caches in the background to potentially avoid apps being launched through a notification
        // all at the same time by too many users concurrently.
        self.updateCachesIfInForeground()

        if self.systemInfo.dangerousSettings.autoSyncPurchases {
            self.paymentQueueWrapper.sk1Wrapper?.delegate = purchasesOrchestrator
        } else {
            Logger.warn(Strings.configure.autoSyncPurchasesDisabled)
        }

        /// If SK1 is not enabled, `PaymentQueueWrapper` needs to handle transactions
        /// for promotional offers to work.
        self.paymentQueueWrapper.sk2Wrapper?.delegate = purchasesOrchestrator

        self.subscribeToAppStateNotifications()
        self.attributionPoster.postPostponedAttributionDataIfNeeded()

        (self as DeprecatedSearchAdsAttribution).postAppleSearchAddsAttributionCollectionIfNeeded()

        self.customerInfoObservationDisposable = customerInfoManager.monitorChanges { [weak self] customerInfo in
            guard let self = self else { return }
            self.handleCustomerInfoChanged(customerInfo)
        }
    }

    deinit {
        Logger.verbose(Strings.configure.purchases_deinit(self))

        self.notificationCenter.removeObserver(self)
        self.paymentQueueWrapper.sk1Wrapper?.delegate = nil
        self.paymentQueueWrapper.sk2Wrapper?.delegate = nil
        self.customerInfoObservationDisposable?()
        self.privateDelegate = nil
        Self.proxyURL = nil
    }

    static func clearSingleton() {
        Self.purchases.value = nil
    }

    /// - Parameter purchases: this is an `@autoclosure` to be able to clear the previous instance
    /// from memory before creating the new one.
    @discardableResult
    static func setDefaultInstance(_ purchases: @autoclosure () -> Purchases) -> Purchases {
        return self.purchases.modify { currentInstance in
            if currentInstance != nil {
                #if DEBUG
                if ProcessInfo.isRunningRevenueCatTests {
                    preconditionFailure(Strings.configure.purchase_instance_already_set.description)
                }
                #endif
                Logger.info(Strings.configure.purchase_instance_already_set)

                // Clear existing instance to avoid multiple concurrent instances in memory.
                currentInstance = nil
            }

            let newInstance = purchases()
            currentInstance = newInstance
            return newInstance
        }
    }

}

// MARK: Attribution

extension Purchases {

    private func post(attributionData data: [String: Any],
                      fromNetwork network: AttributionNetwork,
                      forNetworkUserId networkUserId: String?) {
        attributionPoster.post(attributionData: data, fromNetwork: network, networkUserId: networkUserId)
    }

    @available(*, deprecated)
    fileprivate func postAppleSearchAddsAttributionCollectionIfNeeded() {
        guard Self.automaticAppleSearchAdsAttributionCollection else {
            return
        }
        attributionPoster.postAppleSearchAdsAttributionIfNeeded()
    }

}

// MARK: Identity

public extension Purchases {

    @objc var appUserID: String { self.identityManager.currentAppUserID }

    @objc var isAnonymous: Bool { self.identityManager.currentUserIsAnonymous }

    func logIn(_ appUserID: StaticString, completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        Logger.warn(Strings.identity.logging_in_with_static_string)

        self.logIn("\(appUserID)", completion: completion)
    }

    @_disfavoredOverload // Favor `StaticString` overload (`String` is not convertible to `StaticString`).
    @objc(logIn:completion:)
    func logIn(_ appUserID: String, completion: @escaping (CustomerInfo?, Bool, PublicError?) -> Void) {
        self.identityManager.logIn(appUserID: appUserID) { result in
            self.operationDispatcher.dispatchOnMainThread {
                completion(result.value?.info, result.value?.created ?? false, result.error?.asPublicError)
            }

            guard case .success = result else {
                return
            }

            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.offeringsManager.updateOfferingsCache(appUserID: self.appUserID,
                                                           isAppBackgrounded:
                                                            isAppBackgrounded,
                                                           completion: nil)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logIn(_ appUserID: StaticString) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        Logger.warn(Strings.identity.logging_in_with_static_string)

        return try await self.logIn("\(appUserID)")
    }

    @_disfavoredOverload // Favor `StaticString` overload (`String` is not convertible to `StaticString`).
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logIn(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await self.logInAsync(appUserID)
    }

    @objc func logOut(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.identityManager.logOut { error in
            guard error == nil else {
                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(nil, error?.asPublicError)
                    }
                }
                return
            }

            self.updateAllCaches {
                completion?($0.value, $0.error)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logOut() async throws -> CustomerInfo {
        return try await logOutAsync()
    }

    @objc func getOfferings(completion: @escaping (Offerings?, PublicError?) -> Void) {
        self.getOfferings(fetchPolicy: .default, completion: completion)
    }

    internal func getOfferings(
        fetchPolicy: OfferingsManager.FetchPolicy,
        completion: @escaping (Offerings?, PublicError?) -> Void
    ) {
        self.offeringsManager.offerings(appUserID: self.appUserID, fetchPolicy: fetchPolicy) { @Sendable result in
            completion(result.value, result.error?.asPublicError)
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func offerings() async throws -> Offerings {
        return try await self.offerings(fetchPolicy: .default)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    internal func offerings(fetchPolicy: OfferingsManager.FetchPolicy) async throws -> Offerings {
        return try await self.offeringsAsync(fetchPolicy: fetchPolicy)
    }

}

// MARK: Purchasing

public extension Purchases {

    @objc func getCustomerInfo(completion: @escaping (CustomerInfo?, PublicError?) -> Void) {
        self.getCustomerInfo(fetchPolicy: .default, completion: completion)
    }

    @objc func getCustomerInfo(
        fetchPolicy: CacheFetchPolicy,
        completion: @escaping (CustomerInfo?, PublicError?) -> Void
    ) {
        self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                              fetchPolicy: fetchPolicy) { @Sendable result in
            completion(result.value, result.error?.asPublicError)
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfo() async throws -> CustomerInfo {
        return try await self.customerInfo(fetchPolicy: .default)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
        return try await self.customerInfoAsync(fetchPolicy: fetchPolicy)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    var customerInfoStream: AsyncStream<CustomerInfo> {
        return self.customerInfoManager.customerInfoStream
    }

    @objc(getProductsWithIdentifiers:completion:)
    func getProducts(_ productIdentifiers: [String], completion: @escaping ([StoreProduct]) -> Void) {
        purchasesOrchestrator.products(withIdentifiers: productIdentifiers, completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        return await productsAsync(productIdentifiers)
    }

    @objc(purchaseProduct:withCompletion:)
    func purchase(product: StoreProduct, completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: product, package: nil, completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(product: StoreProduct) async throws -> PurchaseResultData {
        return try await purchaseAsync(product: product)
    }

    @objc(purchasePackage:withCompletion:)
    func purchase(package: Package, completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: package.storeProduct, package: package, completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(package: Package) async throws -> PurchaseResultData {
        return try await purchaseAsync(package: package)
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc(purchaseProduct:withPromotionalOffer:completion:)
    func purchase(product: StoreProduct,
                  promotionalOffer: PromotionalOffer,
                  completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: product,
                                       package: nil,
                                       promotionalOffer: promotionalOffer.signedData,
                                       completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(product: StoreProduct, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await purchaseAsync(product: product, promotionalOffer: promotionalOffer)
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc(purchasePackage:withPromotionalOffer:completion:)
    func purchase(package: Package, promotionalOffer: PromotionalOffer, completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: package.storeProduct,
                                       package: package,
                                       promotionalOffer: promotionalOffer.signedData,
                                       completion: completion)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(package: Package, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await purchaseAsync(package: package, promotionalOffer: promotionalOffer)
    }

    @objc func syncPurchases(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.purchasesOrchestrator.syncPurchases { @Sendable in
            completion?($0.value, $0.error?.asPublicError)
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func syncPurchases() async throws -> CustomerInfo {
        return try await syncPurchasesAsync()
    }

    @objc func restorePurchases(completion: ((CustomerInfo?, PublicError?) -> Void)? = nil) {
        purchasesOrchestrator.restorePurchases { @Sendable in
            completion?($0.value, $0.error?.asPublicError)
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func restorePurchases() async throws -> CustomerInfo {
        return try await restorePurchasesAsync()
    }

    @objc(checkTrialOrIntroDiscountEligibility:completion:)
    func checkTrialOrIntroDiscountEligibility(productIdentifiers: [String],
                                              completion: @escaping ([String: IntroEligibility]) -> Void) {
        trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: productIdentifiers,
                                                             completion: completion)
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func checkTrialOrIntroDiscountEligibility(productIdentifiers: [String]) async -> [String: IntroEligibility] {
        return await checkTrialOrIntroductoryDiscountEligibilityAsync(productIdentifiers)
    }

    @objc(checkTrialOrIntroDiscountEligibilityForProduct:completion:)
    func checkTrialOrIntroDiscountEligibility(product: StoreProduct,
                                              completion: @escaping (IntroEligibilityStatus) -> Void) {
        trialOrIntroPriceEligibilityChecker.checkEligibility(product: product, completion: completion)
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func checkTrialOrIntroDiscountEligibility(product: StoreProduct) async -> IntroEligibilityStatus {
        return await checkTrialOrIntroductoryDiscountEligibilityAsync(product)
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    @objc func showPriceConsentIfNeeded() {
        self.paymentQueueWrapper.paymentQueueWrapperType.showPriceConsentIfNeeded()
    }
#endif

    @objc func invalidateCustomerInfoCache() {
        self.customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)
    }

#if os(iOS)

    @available(iOS 14.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @objc func presentCodeRedemptionSheet() {
        self.paymentQueueWrapper.paymentQueueWrapperType.presentCodeRedemptionSheet()
    }
#endif

    @available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
    @objc(getPromotionalOfferForProductDiscount:withProduct:withCompletion:)
    func getPromotionalOffer(forProductDiscount discount: StoreProductDiscount,
                             product: StoreProduct,
                             completion: @escaping (PromotionalOffer?, PublicError?) -> Void) {
        self.purchasesOrchestrator.promotionalOffer(forProductDiscount: discount,
                                                    product: product) { result in
            completion(result.value, result.error?.asPublicError)
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer {
        return try await promotionalOfferAsync(forProductDiscount: discount, product: product)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func eligiblePromotionalOffers(forProduct product: StoreProduct) async -> [PromotionalOffer] {
        return await eligiblePromotionalOffersAsync(forProduct: product)
    }

#if os(iOS) || os(macOS)

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 13.0, macOS 10.15, *)
    @objc func showManageSubscriptions(completion: @escaping (PublicError?) -> Void) {
        self.purchasesOrchestrator.showManageSubscription { error in
            completion(error?.asPublicError)
        }
    }

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 13.0, macOS 10.15, *)
    func showManageSubscriptions() async throws {
        return try await showManageSubscriptionsAsync()
    }

#endif

#if os(iOS)

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(beginRefundRequestForProduct:completion:)
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        return try await purchasesOrchestrator.beginRefundRequest(forProduct: productID)
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(beginRefundRequestForEntitlement:completion:)
    func beginRefundRequest(forEntitlement entitlementID: String) async throws -> RefundRequestStatus {
        return try await purchasesOrchestrator.beginRefundRequest(forEntitlement: entitlementID)
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(beginRefundRequestForActiveEntitlementWithCompletion:)
    func beginRefundRequestForActiveEntitlement() async throws -> RefundRequestStatus {
        return try await purchasesOrchestrator.beginRefundRequestForActiveEntitlement()
    }

#endif

}

// swiftlint:enable missing_docs

// MARK: Configuring Purchases

public extension Purchases {

    /**
     * Configures an instance of the Purchases SDK with a specified ``Configuration``.
     *
     * The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Parameter configuration: The ``Configuration`` object you wish to use to configure ``Purchases``
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     *
     * - Important: See ``Configuration/Builder`` for more information about configurable properties.
     *
     * ### Example
     *
     * ```swift
     *  Purchases.configure(
     *      with: Configuration.Builder(withAPIKey: Constants.apiKey)
     *               .with(usesStoreKit2IfAvailable: true)
     *               .with(observerMode: false)
     *               .with(appUserID: "<app_user_id>")
     *               .build()
     *      )
     * ```
     *
     */
    @objc(configureWithConfiguration:)
    @discardableResult static func configure(with configuration: Configuration) -> Purchases {
        configure(withAPIKey: configuration.apiKey,
                  appUserID: configuration.appUserID,
                  observerMode: configuration.observerMode,
                  userDefaults: configuration.userDefaults,
                  platformInfo: configuration.platformInfo,
                  responseVerificationLevel: configuration.responseVerificationLevel,
                  storeKit2Setting: configuration.storeKit2Setting,
                  storeKitTimeout: configuration.storeKit1Timeout,
                  networkTimeout: configuration.networkTimeout,
                  dangerousSettings: configuration.dangerousSettings)
    }

    /**
     * Configures an instance of the Purchases SDK with a specified ``Configuration/Builder``.
     *
     * The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Parameter builder: The ``Configuration/Builder`` object you wish to use to configure ``Purchases``
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     *
     * - Important: See ``Configuration/Builder`` for more information about configurable properties.
     *
     * ### Example
     *
     * ```swift
     *  Purchases.configure(
     *      with: .init(withAPIKey: Constants.apiKey)
     *               .with(usesStoreKit2IfAvailable: true)
     *               .with(observerMode: false)
     *               .with(appUserID: "<app_user_id>")
     *      )
     * ```
     *
     */
    @objc(configureWithConfigurationBuilder:)
    @discardableResult static func configure(with builder: Configuration.Builder) -> Purchases {
        return Self.configure(with: builder.build())
    }

    /**
     * Configures an instance of the Purchases SDK with a specified API key.
     *
     * The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Note: Use this initializer if your app does not have an account system.
     * ``Purchases`` will generate a unique identifier for the current device and persist it to `NSUserDefaults`.
     * This also affects the behavior of ``Purchases/restorePurchases(completion:)``.
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:)
    @discardableResult static func configure(withAPIKey apiKey: String) -> Purchases {
        Self.configure(withAPIKey: apiKey, appUserID: nil)
    }

    /**
     * Configures an instance of the Purchases SDK with a specified API key and app user ID.
     *
     * The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Note: Best practice is to use a salted hash of your unique app user ids.
     *
     * - Warning: Use this initializer if you have your own user identifiers that you manage.
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass `nil` or an empty string if you want ``Purchases``
     * to generate this for you.
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:)
    @discardableResult static func configure(withAPIKey apiKey: String, appUserID: String?) -> Purchases {
        Self.configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: false)
    }

    /**
     * Configures an instance of the Purchases SDK with a custom `UserDefaults`.
     *
     * Use this constructor if you want to
     * sync status across a shared container, such as between a host app and an extension. The instance of the
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass `nil` or an empty string if you want ``Purchases``
     * to generate this for you.
     *
     * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
     * RevenueCat's backend. Default is `false`.
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool) -> Purchases {
        Self.configure(
            with: Configuration
                .builder(withAPIKey: apiKey)
                .with(appUserID: appUserID)
                .with(observerMode: observerMode)
                .build()
        )
    }

    // swiftlint:disable:next function_parameter_count
    @discardableResult internal static func configure(
        withAPIKey apiKey: String,
        appUserID: String?,
        observerMode: Bool,
        userDefaults: UserDefaults?,
        platformInfo: PlatformInfo?,
        responseVerificationLevel: Signing.ResponseVerificationLevel,
        storeKit2Setting: StoreKit2Setting,
        storeKitTimeout: TimeInterval,
        networkTimeout: TimeInterval,
        dangerousSettings: DangerousSettings?
    ) -> Purchases {
        return self.setDefaultInstance(
            .init(apiKey: apiKey,
                  appUserID: appUserID,
                  userDefaults: userDefaults,
                  observerMode: observerMode,
                  platformInfo: platformInfo,
                  responseVerificationLevel: responseVerificationLevel,
                  storeKit2Setting: storeKit2Setting,
                  storeKitTimeout: storeKitTimeout,
                  networkTimeout: networkTimeout,
                  dangerousSettings: dangerousSettings)
        )
    }

}

// MARK: Delegate implementation

extension Purchases: PurchasesOrchestratorDelegate {

    /**
     * Called when a user initiates a promoted in-app purchase from the App Store.
     *
     * If your app is able to handle a purchase at the current time, run the `startPurchase` block.
     *
     * If the app is not in a state to make a purchase: cache the `startPurchase` block, then call it
     * when the app is ready to make the promoted purchase.
     *
     * If the purchase should never be made, you don't need to ever call the `startPurchase` block
     * and ``Purchases`` will not proceed with promoted purchases.
     *
     * - Parameter product: ``StoreProduct`` the product that was selected from the app store.
     * - Parameter startPurchase: Method that begins the purchase flow for the promoted purchase.
     * If the app is ready to start the purchase flow when this delegate method is called, then this method
     * should be called right away. Otherwise, the method should be stored as a property in memory, and then called
     * once the app is ready to start the purchase flow.
     * When the purchase completes, the result will be part of the callback parameters.
     */
    func readyForPromotedProduct(_ product: StoreProduct,
                                 purchase startPurchase: @escaping StartPurchaseBlock) {
        self.delegate?.purchases?(self, readyForPromotedProduct: product, purchase: startPurchase)
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    var shouldShowPriceConsent: Bool {
        self.delegate?.shouldShowPriceConsent ?? true
    }
#endif

}

// MARK: Deprecated

public extension Purchases {

    /**
     * Enable debug logging. Useful for debugging issues with the lovely team @RevenueCat.
     */
    @available(*, deprecated, message: "use Purchases.logLevel instead")
    @objc static var debugLogsEnabled: Bool {
        get { logLevel == .debug }
        set { logLevel = newValue ? .debug : .info }
    }

    /**
     * Deprecated
     */
    @available(*, deprecated, message: "Configure behavior through the RevenueCat dashboard instead")
    @objc var allowSharingAppStoreAccount: Bool {
        get { purchasesOrchestrator.allowSharingAppStoreAccount }
        set { purchasesOrchestrator.allowSharingAppStoreAccount = newValue }
    }

    /**
     * Deprecated
     */
    @available(*, deprecated, message: "Use the set<NetworkId> functions instead")
    @objc static func addAttributionData(_ data: [String: Any], fromNetwork network: AttributionNetwork) {
        addAttributionData(data, from: network, forNetworkUserId: nil)
    }

    /**
     * Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.
     *
     * - Parameter data: Dictionary provided by the network.
     * - Parameter network: Enum for the network the data is coming from, see ``AttributionNetwork`` for supported
     * networks.
     * - Parameter networkUserId: User Id that should be sent to the network. Default is the current App User Id.
     *
     * #### Related articles
     * - [Attribution](https://docs.revenuecat.com/docs/attribution)
     */
    @available(*, deprecated, message: "Use the set<NetworkId> functions instead")
    @objc(addAttributionData:fromNetwork:forNetworkUserId:)
    static func addAttributionData(_ data: [String: Any],
                                   from network: AttributionNetwork,
                                   forNetworkUserId networkUserId: String?) {
        if Self.isConfigured {
            Self.shared.post(attributionData: data, fromNetwork: network, forNetworkUserId: networkUserId)
        } else {
            AttributionPoster.store(postponedAttributionData: data,
                                    fromNetwork: network,
                                    forNetworkUserId: networkUserId)
        }
    }

}

// @unchecked because:
// - It contains `NotificationCenter`, which isn't thread-safe as of Swift 5.7.
// - It has a mutable `privateDelegate` (this isn't actually thread-safe!)
// - It has a mutable `customerInfoObservationDisposable` because it's late-initialized in the constructor
//
// One could argue this warrants making this class non-Sendable, but the annotation allows its usage in
// async contexts in a much more simple way without errors like:
// "Capture of 'self' with non-sendable type 'Purchases' in a `@Sendable` closure"
extension Purchases: @unchecked Sendable {}

// MARK: Internal

extension Purchases: InternalPurchasesType {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    internal func healthRequest() async throws {
        do {
            try await self.backend.healthRequest()
        } catch {
            throw NewErrorUtils.purchasesError(withUntypedError: error)
        }
    }

}

/// Necessary because `ErrorUtils` inside of `Purchases` finds the obsoleted type.
private typealias NewErrorUtils = ErrorUtils

internal extension Purchases {

    var isStoreKit1Configured: Bool {
        return self.paymentQueueWrapper.sk1Wrapper != nil
    }

    #if DEBUG

    /// - Returns: the parsed `AppleReceipt`
    ///
    /// - Warning: this is only meant for integration tests, as a way to debug purchase failures.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func fetchReceipt(_ policy: ReceiptRefreshPolicy) async throws -> AppleReceipt? {
        let receipt = await self.receiptFetcher.receiptData(refreshPolicy: policy)

        return try receipt.map { try PurchasesReceiptParser.default.parse(from: $0) }
    }

    #endif

    /// - Parameter syncedAttribute: will be called for every attribute that is updated
    /// - Parameter completion: will be called once all attributes have completed syncing
    /// - Returns: the number of attributes that will be synced
    @discardableResult
    func syncSubscriberAttributes(
        syncedAttribute: (@Sendable (PublicError?) -> Void)? = nil,
        completion: (@Sendable () -> Void)? = nil
    ) -> Int {
        return self.attribution.syncAttributesForAllUsers(
            currentAppUserID: self.appUserID,
            syncedAttribute: { @Sendable in syncedAttribute?($0?.asPublicError) },
            completion: completion
        )
    }

}

#if DEBUG

// MARK: - Exposed data for testing only

internal extension Purchases {

    var networkTimeout: TimeInterval {
        return self.backend.networkTimeout
    }

    var storeKitTimeout: TimeInterval {
        return self.productsManager.requestTimeout
    }

    var isSandbox: Bool {
        return self.systemInfo.isSandbox
    }

    var configuredUserDefaults: UserDefaults {
        return self.userDefaults
    }

    var publicKey: Signing.PublicKey? {
        return self.systemInfo.responseVerificationLevel.publicKey
    }

}

#endif

// MARK: Private

private extension Purchases {

    func handleCustomerInfoChanged(_ customerInfo: CustomerInfo) {
        self.trialOrIntroPriceEligibilityChecker.clearCache()
        self.delegate?.purchases?(self, receivedUpdated: customerInfo)
    }

    @objc func applicationDidBecomeActive(notification: Notification) {
        Logger.debug(Strings.configure.application_active)
        self.updateAllCachesIfNeeded()
        self.dispatchSyncSubscriberAttributes()

        (self as DeprecatedSearchAdsAttribution).postAppleSearchAddsAttributionCollectionIfNeeded()

#if os(iOS) || os(macOS)
        if #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) {
            self.attribution.postAdServicesTokenIfNeeded()
        }
#endif
    }

    @objc func applicationWillResignActive(notification: Notification) {
        self.dispatchSyncSubscriberAttributes()
    }

    func subscribeToAppStateNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidBecomeActive(notification:)),
                                       name: SystemInfo.applicationDidBecomeActiveNotification, object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillResignActive(notification:)),
                                       name: SystemInfo.applicationWillResignActiveNotification, object: nil)
    }

    func dispatchSyncSubscriberAttributes() {
        operationDispatcher.dispatchOnWorkerThread {
            self.syncSubscriberAttributes()
        }
    }

    func updateCachesIfInForeground() {
        self.systemInfo.isApplicationBackgrounded { isBackgrounded in
            if !isBackgrounded {
                self.operationDispatcher.dispatchOnWorkerThread {
                    self.updateAllCaches(isAppBackgrounded: isBackgrounded, completion: nil)
                }
            }
        }
    }

    func updateAllCachesIfNeeded() {
        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: self.appUserID,
                                                                      isAppBackgrounded: isAppBackgrounded,
                                                                      completion: nil)
            guard self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded) else {
                return
            }

            Logger.debug("Offerings cache is stale, updating caches")
            self.offeringsManager.updateOfferingsCache(appUserID: self.appUserID,
                                                       isAppBackgrounded: isAppBackgrounded,
                                                       completion: nil)
        }
    }

    func updateAllCaches(completion: ((Result<CustomerInfo, PublicError>) -> Void)?) {
        self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.updateAllCaches(isAppBackgrounded: isAppBackgrounded,
                                 completion: completion)
        }
    }

    func updateAllCaches(
        isAppBackgrounded: Bool,
        completion: ((Result<CustomerInfo, PublicError>) -> Void)?
    ) {
        self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: self.appUserID,
                                                           isAppBackgrounded: isAppBackgrounded) { @Sendable in
            completion?($0.mapError { $0.asPublicError })
        }

        self.offeringsManager.updateOfferingsCache(appUserID: self.appUserID,
                                                   isAppBackgrounded: isAppBackgrounded,
                                                   completion: nil)
    }

    // Used when delegate is being set
    func sendCachedCustomerInfoToDelegateIfExists() {
        guard let info = self.customerInfoManager.cachedCustomerInfo(appUserID: self.appUserID) else {
            return
        }

        self.delegate?.purchases?(self, receivedUpdated: info)
    }

}

// MARK: - Deprecations

/// Protocol to be able to call `Purchases.postAppleSearchAddsAttributionCollectionIfNeeded` without warnings
private protocol DeprecatedSearchAdsAttribution {

    func postAppleSearchAddsAttributionCollectionIfNeeded()

}

extension Purchases: DeprecatedSearchAdsAttribution {}
