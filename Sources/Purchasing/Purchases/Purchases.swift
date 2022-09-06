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
@objc(RCPurchases) public final class Purchases: NSObject {

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

    /**
     * Delegate for ``Purchases`` instance. The delegate is responsible for handling promotional product purchases and
     * changes to customer information.
     * - Note: this is not thread-safe.
     */
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

    /**
     * ``Attribution`` object that is responsible for all explicit attribution APIs
     * as well as subscriber attributes that RevenueCat offers.
     *
     * #### Example:
     *
     * ```swift
     * Purchases.shared.attribution.setEmail(“nobody@example.com”)
     * ```
     *
     * #### Related Articles
     * - [Subscriber Attribution](https://docs.revenuecat.com/docs/subscriber-attributes)
     * - ``Attribution``
     */
    @objc public let attribution: Attribution

    /** Whether transactions should be finished automatically. `true` by default.
     * - Warning: Setting this value to `false` will prevent the SDK from finishing transactions.
     * In this case, you *must* finish transactions in your app, otherwise they will remain in the queue and
     * will turn up every time the app is opened.
     * More information on finishing transactions manually [is available here](https://rev.cat/finish-transactions).
     */
    @objc public var finishTransactions: Bool {
        get { self.systemInfo.finishTransactions }
        set { self.systemInfo.finishTransactions = newValue }
    }

    private let attributionFetcher: AttributionFetcher
    private let attributionPoster: AttributionPoster
    private let backend: Backend
    private let deviceCache: DeviceCache
    private let identityManager: IdentityManager
    private let notificationCenter: NotificationCenter
    private let offeringsFactory: OfferingsFactory
    private let offeringsManager: OfferingsManager
    private let productsManager: ProductsManager
    private let customerInfoManager: CustomerInfoManager
    private let trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker
    private let purchasesOrchestrator: PurchasesOrchestrator
    private let receiptFetcher: ReceiptFetcher
    private let requestFetcher: StoreKitRequestFetcher
    private let storeKit1Wrapper: StoreKit1Wrapper?
    private let paymentQueueWrapper: PaymentQueueWrapper
    private let systemInfo: SystemInfo
    private var customerInfoObservationDisposable: (() -> Void)?

    // swiftlint:disable:next function_body_length
    convenience init(apiKey: String,
                     appUserID: String?,
                     userDefaults: UserDefaults? = nil,
                     observerMode: Bool = false,
                     platformInfo: PlatformInfo? = Purchases.platformInfo,
                     storeKit2Setting: StoreKit2Setting = .default,
                     storeKitTimeout: TimeInterval = Configuration.storeKitRequestTimeoutDefault,
                     networkTimeout: TimeInterval = Configuration.networkTimeoutDefault,
                     dangerousSettings: DangerousSettings? = nil) {
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
        let storeKit1Wrapper: StoreKit1Wrapper? = systemInfo.storeKit2Setting.shouldOnlyUseStoreKit2
        ? nil
        : StoreKit1Wrapper()
        let paymentQueueWrapper = storeKit1Wrapper?.createPaymentQueueWrapper() ?? .init()

        let offeringsFactory = OfferingsFactory()
        let userDefaults = userDefaults ?? UserDefaults.standard
        let deviceCache = DeviceCache(sandboxEnvironmentDetector: systemInfo, userDefaults: userDefaults)
        let receiptParser = ReceiptParser()
        let transactionsManager = TransactionsManager(storeKit2Setting: systemInfo.storeKit2Setting,
                                                      receiptParser: receiptParser)
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
        let productsManager = ProductsManager(productsRequestFactory: productsRequestFactory,
                                              systemInfo: systemInfo,
                                              requestTimeout: storeKitTimeout)
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
                    storeKit1Wrapper: storeKit1Wrapper,
                    systemInfo: systemInfo,
                    subscriberAttributes: subscriberAttributes,
                    operationDispatcher: operationDispatcher,
                    receiptFetcher: receiptFetcher,
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
                    storeKit1Wrapper: storeKit1Wrapper,
                    systemInfo: systemInfo,
                    subscriberAttributes: subscriberAttributes,
                    operationDispatcher: operationDispatcher,
                    receiptFetcher: receiptFetcher,
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
                  storeKit1Wrapper: storeKit1Wrapper,
                  paymentQueueWrapper: paymentQueueWrapper,
                  notificationCenter: NotificationCenter.default,
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

    // swiftlint:disable:next function_body_length
    init(appUserID: String?,
         requestFetcher: StoreKitRequestFetcher,
         receiptFetcher: ReceiptFetcher,
         attributionFetcher: AttributionFetcher,
         attributionPoster: AttributionPoster,
         backend: Backend,
         storeKit1Wrapper: StoreKit1Wrapper?,
         paymentQueueWrapper: PaymentQueueWrapper,
         notificationCenter: NotificationCenter,
         systemInfo: SystemInfo,
         offeringsFactory: OfferingsFactory,
         deviceCache: DeviceCache,
         identityManager: IdentityManager,
         subscriberAttributes: Attribution,
         operationDispatcher: OperationDispatcher,
         customerInfoManager: CustomerInfoManager,
         productsManager: ProductsManager,
         offeringsManager: OfferingsManager,
         purchasesOrchestrator: PurchasesOrchestrator,
         trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker
    ) {

        Logger.debug(Strings.configure.debug_enabled, fileName: nil)
        if systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
            Logger.info(Strings.configure.store_kit_2_enabled, fileName: nil)
        }
        Logger.debug(Strings.configure.sdk_version(Self.frameworkVersion), fileName: nil)
        Logger.debug(Strings.configure.bundle_id(SystemInfo.bundleIdentifier), fileName: nil)
        Logger.user(Strings.configure.initial_app_user_id(isSet: appUserID != nil), fileName: nil)

        self.requestFetcher = requestFetcher
        self.receiptFetcher = receiptFetcher
        self.attributionFetcher = attributionFetcher
        self.attributionPoster = attributionPoster
        self.backend = backend
        self.storeKit1Wrapper = storeKit1Wrapper
        self.paymentQueueWrapper = paymentQueueWrapper
        self.offeringsFactory = offeringsFactory
        self.deviceCache = deviceCache
        self.identityManager = identityManager
        self.notificationCenter = notificationCenter
        self.systemInfo = systemInfo
        self.attribution = subscriberAttributes
        self.operationDispatcher = operationDispatcher
        self.customerInfoManager = customerInfoManager
        self.productsManager = productsManager
        self.offeringsManager = offeringsManager
        self.purchasesOrchestrator = purchasesOrchestrator
        self.trialOrIntroPriceEligibilityChecker = trialOrIntroPriceEligibilityChecker

        super.init()

        self.purchasesOrchestrator.delegate = self

        systemInfo.isApplicationBackgrounded { isBackgrounded in
            if isBackgrounded {
                self.customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: self.appUserID)
            } else {
                self.operationDispatcher.dispatchOnWorkerThread {
                    self.updateAllCaches(completion: nil)
                }
            }
        }

        if self.systemInfo.dangerousSettings.autoSyncPurchases {
            storeKit1Wrapper?.delegate = purchasesOrchestrator
        } else {
            Logger.warn(Strings.configure.autoSyncPurchasesDisabled)
        }

        self.subscribeToAppStateNotifications()
        self.attributionPoster.postPostponedAttributionDataIfNeeded()

        (self as DeprecatedSearchAdsAttribution).postAppleSearchAddsAttributionCollectionIfNeeded()

        self.customerInfoObservationDisposable = customerInfoManager.monitorChanges { [weak self] customerInfo in
            guard let self = self else { return }
            self.delegate?.purchases?(self, receivedUpdated: customerInfo)
        }
    }

    deinit {
        self.notificationCenter.removeObserver(self)
        self.storeKit1Wrapper?.delegate = nil
        self.customerInfoObservationDisposable?()
        self.privateDelegate = nil
        Self.proxyURL = nil
    }

    static func clearSingleton() {
        Self.purchases.value = nil
    }

    static func setDefaultInstance(_ purchases: Purchases) {
        self.purchases.modify { currentInstance in
            if currentInstance != nil {
                Logger.info(Strings.configure.purchase_instance_already_set)
            }

            currentInstance = purchases
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

    /**
    * The ``appUserID`` used by ``Purchases``.
    * If not passed on initialization this will be generated and cached by ``Purchases``.
    */
    @objc var appUserID: String { identityManager.currentAppUserID }

    /// Returns `true` if the ``appUserID`` has been generated by RevenueCat, `false` otherwise.
    @objc var isAnonymous: Bool { identityManager.currentUserIsAnonymous }

    /**
     * This function will log in the current user with an ``appUserID``.
     *
     * - Parameter appUserID: The ``appUserID`` that should be linked to the current user.
     *
     * The `completion` block will be called with the latest ``CustomerInfo`` and a `Bool` specifying
     * whether the user was created for the first time in the RevenueCat backend.
     *
     * RevenueCat provides a source of truth for a subscriber's status across different platforms.
     * To do this, each subscriber has an App User ID that uniquely identifies them within your application.
     *
     * User identity is one of the most important components of many mobile applications,
     * and it's extra important to make sure the subscription status RevenueCat is
     * tracking gets associated with the correct user.
     *
     * The Purchases SDK allows you to specify your own user identifiers or use anonymous identifiers
     * generated by RevenueCat. Some apps will use a combination
     * of their own identifiers and RevenueCat anonymous Ids - that's okay!
     *
     * #### Related Articles
     * - [Identifying Users](https://docs.revenuecat.com/docs/user-ids)
     * - ``logOut(completion:)``
     * - ``isAnonymous``
     * - ``Purchases/appUserID``
     */
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

    /**
     * This function will log in the current user with an ``appUserID``.
     *
     * - Parameter appUserID: The ``appUserID`` that should be linked to the current user.
     * - returns: A tuple of: the latest ``CustomerInfo`` and a `Bool` specifying
     * whether the user was created for the first time in the RevenueCat backend.
     *
     * RevenueCat provides a source of truth for a subscriber's status across different platforms.
     * To do this, each subscriber has an App User ID that uniquely identifies them within your application.
     *
     * User identity is one of the most important components of many mobile applications,
     * and it's extra important to make sure the subscription status RevenueCat is
     * tracking gets associated with the correct user.
     *
     * The Purchases SDK allows you to specify your own user identifiers or use anonymous identifiers
     * generated by RevenueCat. Some apps will use a combination
     * of their own identifiers and RevenueCat anonymous Ids - that's okay!
     *
     * #### Related Articles
     * - [Identifying Users](https://docs.revenuecat.com/docs/user-ids)
     * - ``logOut()``
     * - ``isAnonymous``
     * - ``Purchases/appUserID``
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logIn(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await logInAsync(appUserID)
    }

    /**
     * Logs out the ``Purchases`` client, clearing the saved ``appUserID``.
     *
     * This will generate a random user id and save it in the cache.
     * If this method is called and the current user is anonymous, it will return an error.
     *
     * #### Related Articles
     * - [Identifying Users](https://docs.revenuecat.com/docs/user-ids)
     * - ``logIn(_:completion:)``
     * - ``isAnonymous``
     * - ``Purchases/appUserID``
     */
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

    /**
     * Logs out the ``Purchases`` client, clearing the saved ``appUserID``.
     *
     * This will generate a random user id and save it in the cache.
     * If this method is called and the current user is anonymous, it will return an error.
     *
     * #### Related Articles
     * - [Identifying Users](https://docs.revenuecat.com/docs/user-ids)
     * - ``logIn(_:)``
     * - ``isAnonymous``
     * - ``Purchases/appUserID``
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logOut() async throws -> CustomerInfo {
        return try await logOutAsync()
    }

    /**
     * Fetch the configured ``Offerings`` for this user.
     *
     * ``Offerings`` allows you to configure your in-app products
     * via RevenueCat and greatly simplifies management.
     *
     * ``Offerings`` will be fetched and cached on instantiation so that, by the time they are needed,
     * your prices are loaded for your purchase flow. Time is money.
     *
     * - Parameter completion: A completion block called when offerings are available.
     * Called immediately if offerings are cached. ``Offerings`` will be `nil` if an error occurred.
     *
     * #### Related Articles
     * -  [Displaying Products](https://docs.revenuecat.com/docs/displaying-products)
     */
    @objc func getOfferings(completion: @escaping (Offerings?, PublicError?) -> Void) {
        self.offeringsManager.offerings(appUserID: appUserID) { result in
            completion(result.value, result.error?.asPublicError)
        }
    }

    /**
     * Fetch the configured ``Offerings`` for this user.
     *
     * ``Offerings`` allows you to configure your in-app products
     * via RevenueCat and greatly simplifies management.
     *
     * ``Offerings`` will be fetched and cached on instantiation so that, by the time they are needed,
     * your prices are loaded for your purchase flow. Time is money.
     *
     * #### Related Articles
     * -  [Displaying Products](https://docs.revenuecat.com/docs/displaying-products)
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func offerings() async throws -> Offerings {
        return try await offeringsAsync()
    }

}

// MARK: Purchasing

public extension Purchases {

    /**
     * Get latest available customer  info.
     *
     * - Parameter completion: A completion block called when customer info is available and not stale.
     * Called immediately if ``CustomerInfo`` is cached. Customer info can be nil if an error occurred.
     */
    @objc func getCustomerInfo(completion: @escaping (CustomerInfo?, PublicError?) -> Void) {
        self.getCustomerInfo(fetchPolicy: .default, completion: completion)
    }

    /**
     * Get latest available customer  info.
     *
     * - Parameter fetchPolicy: The behavior for what to do regarding caching.
     * - Parameter completion: A completion block called when customer info is available and not stale.
     */
    @objc func getCustomerInfo(
        fetchPolicy: CacheFetchPolicy,
        completion: @escaping (CustomerInfo?, PublicError?) -> Void
    ) {
        self.customerInfoManager.customerInfo(appUserID: self.appUserID,
                                              fetchPolicy: fetchPolicy) { result in
            completion(result.value, result.error?.asPublicError)
        }
    }

    /**
     * Get latest available customer info.
     *
     * - Parameter fetchPolicy: The behavior for what to do regarding caching.
     *
     * #### Related Symbols
     * - ``Purchases/customerInfoStream``
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfo(fetchPolicy: CacheFetchPolicy = .default) async throws -> CustomerInfo {
        return try await self.customerInfoAsync(fetchPolicy: fetchPolicy)
    }

    /// Returns an `AsyncStream` of ``CustomerInfo`` changes, starting from the last known value.
    ///
    /// #### Related Symbols
    /// - ``PurchasesDelegate/purchases(_:receivedUpdated:)``
    /// - ``Purchases/customerInfo(fetchPolicy:)``
    ///
    /// #### Example:
    /// ```swift
    /// for await customerInfo in Purchases.shared.customerInfoStream {
    ///   // this gets called whenever new CustomerInfo is available
    ///   let entitlements = customerInfo.entitlements
    ///   ...
    /// }
    /// ```
    ///
    /// - Note: An alternative way of getting ``CustomerInfo`` updates
    /// is using ``PurchasesDelegate/purchases(_:receivedUpdated:)``.
    /// - Important: this method is not thread-safe.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    var customerInfoStream: AsyncStream<CustomerInfo> {
        return self.customerInfoManager.customerInfoStream
    }

    /**
     * Fetches the ``StoreProduct``s for your IAPs for given `productIdentifiers`.
     *
     * Use this method if you aren't using ``Purchases/getOfferings(completion:)``.
     * You should use ``getOfferings(completion:)`` though.
     *
     * - Note: `completion` may be called without ``StoreProduct``s that you are expecting. This is usually caused by
     * iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect.
     * Also ensure that you have an active developer program subscription and you have signed the latest paid
     * application agreements.
     * If you're having trouble, see:
     *  [App Store Connect In-App Purchase Configuration](https://rev.cat/how-to-configure-products)
     *
     * - Parameter productIdentifiers: A set of product identifiers for in-app purchases setup via
     * [AppStoreConnect](https://appstoreconnect.apple.com/)
     * This should be either hard coded in your application, from a file, or from a custom endpoint if you want
     * to be able to deploy new IAPs without an app update.
     * - Parameter completion: An `@escaping` callback that is called with the loaded products.
     * If the fetch fails for any reason it will return an empty array.
     */
    @objc(getProductsWithIdentifiers:completion:)
    func getProducts(_ productIdentifiers: [String], completion: @escaping ([StoreProduct]) -> Void) {
        purchasesOrchestrator.products(withIdentifiers: productIdentifiers, completion: completion)
    }

    /**
     * Fetches the ``StoreProduct``s for your IAPs for given `productIdentifiers`.
     *
     * Use this method if you aren't using ``getOfferings(completion:)``.
     * You should use ``getOfferings(completion:)`` though.
     *
     * - Note: The result might not contain the ``StoreProduct``s that you are expecting. This is usually caused by
     * iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect.
     * Also ensure that you have an active developer program subscription and you have signed the latest paid
     * application agreements.
     * If you're having trouble, see:
     * [App Store Connect In-App Purchase Configuration](https://rev.cat/how-to-configure-products)
     *
     * - Parameter productIdentifiers: A set of product identifiers for in-app purchases setup via
     * [AppStoreConnect](https://appstoreconnect.apple.com/)
     * This should be either hard coded in your application, from a file, or from a custom endpoint if you want
     * to be able to deploy new IAPs without an app update.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        return await productsAsync(productIdentifiers)
    }

    /**
     * Initiates a purchase of a ``StoreProduct``.
     *
     * Use this function if you are not using the ``Offerings`` system to purchase a ``StoreProduct``.
     * If you are using the ``Offerings`` system, use ``Purchases/purchase(package:completion:)`` instead.
     *
     * - Important: Call this method when a user has decided to purchase a product.
     * Only call this in direct response to user input.
     *
     * From here ``Purchases`` will handle the purchase with `StoreKit` and call the ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will
     * handle this for you.
     *
     * - Parameter product: The ``StoreProduct`` the user intends to purchase.
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a ``StoreTransaction`` and a ``CustomerInfo``.
     *
     * If the purchase was not successful, there will be an `NSError`.
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @objc(purchaseProduct:withCompletion:)
    func purchase(product: StoreProduct, completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: product, package: nil, completion: completion)
    }

    /**
     * Initiates a purchase of a ``StoreProduct``.
     *
     * Use this function if you are not using the ``Offerings`` system to purchase a ``StoreProduct``.
     * If you are using the ``Offerings`` system, use ``Purchases/purchase(package:completion:)`` instead.
     *
     * - Important: Call this method when a user has decided to purchase a product.
     * Only call this in direct response to user input.
     *
     * From here ``Purchases`` will handle the purchase with `StoreKit` and call the ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, ``Purchases`` will
     * handle this for you.
     *
     * - Parameter product: The ``StoreProduct`` the user intends to purchase.
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(product: StoreProduct) async throws -> PurchaseResultData {
        return try await purchaseAsync(product: product)
    }

    /**
     * Initiates a purchase of a ``Package``.
     *
     * - Important: Call this method when a user has decided to purchase a product.
     * Only call this in direct response to user input.

     * From here ``Purchases`` will handle the purchase with `StoreKit` and call the ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will
     * handle this for you.
     *
     * - Parameter package: The ``Package`` the user intends to purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a ``StoreTransaction`` and a ``CustomerInfo``.
     *
     * If the purchase was not successful, there will be an `NSError`.
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @objc(purchasePackage:withCompletion:)
    func purchase(package: Package, completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: package.storeProduct, package: package, completion: completion)
    }

    /**
     * Initiates a purchase of a ``Package``.
     *
     * - Important: Call this method when a user has decided to purchase a product.
     * Only call this in direct response to user input.
     *
     * From here ``Purchases`` will handle the purchase with `StoreKit` and call the ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will
     * handle this for you.
     *
     * - Parameter package: The ``Package`` the user intends to purchase
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(package: Package) async throws -> PurchaseResultData {
        return try await purchaseAsync(package: package)
    }

    /**
     * Initiates a purchase of a ``StoreProduct`` with a ``PromotionalOffer``.
     *
     * Use this function if you are not using the Offerings system to purchase a ``StoreProduct`` with an
     * applied ``PromotionalOffer``.
     * If you are using the Offerings system, use ``Purchases/purchase(package:promotionalOffer:completion:)`` instead.
     *
     * - Important: Call this method when a user has decided to purchase a product with an applied discount.
     * Only call this in direct response to user input.
     *
     * From here ``Purchases`` will handle the purchase with `StoreKit` and call the ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter product: The ``StoreProduct`` the user intends to purchase.
     * - Parameter promotionalOffer: The ``PromotionalOffer`` to apply to the purchase.
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a ``StoreTransaction`` and a ``CustomerInfo``.
     * If the purchase was not successful, there will be an `NSError`.
     * If the user cancelled, `userCancelled` will be `true`.
     *
     * #### Related Symbols
     * - ``StoreProduct/discounts``
     * - ``StoreProduct/eligiblePromotionalOffers()``
     * - ``promotionalOffer(forProductDiscount:product:)``
     */
    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc(purchaseProduct:withPromotionalOffer:completion:)
    func purchase(product: StoreProduct,
                  promotionalOffer: PromotionalOffer,
                  completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: product,
                                       package: nil,
                                       promotionalOffer: promotionalOffer,
                                       completion: completion)
    }

    /**
     * Use this function if you are not using the Offerings system to purchase a ``StoreProduct`` with an
     * applied ``PromotionalOffer``.
     * If you are using the Offerings system, use ``Purchases/purchase(package:promotionalOffer:completion:)`` instead.
     *
     * Call this method when a user has decided to purchase a product with an applied discount.
     * Only call this in direct response to user input.
     *
     * From here ``Purchases`` will handle the purchase with `StoreKit` and call the ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter product: The ``StoreProduct`` the user intends to purchase
     * - Parameter promotionalOffer: The ``PromotionalOffer`` to apply to the purchase
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(product: StoreProduct, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await purchaseAsync(product: product, promotionalOffer: promotionalOffer)
    }

    /**
     * Purchase the passed ``Package``.
     * Call this method when a user has decided to purchase a product with an applied discount. Only call this in
     * direct response to user input. From here ``Purchases`` will handle the purchase with `StoreKit` and call the
     * ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter package: The ``Package`` the user intends to purchase
     * - Parameter promotionalOffer: The ``PromotionalOffer`` to apply to the purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a ``StoreTransaction`` and a ``CustomerInfo``.
     * If the purchase was not successful, there will be an `NSError`.
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc(purchasePackage:withPromotionalOffer:completion:)
    func purchase(package: Package, promotionalOffer: PromotionalOffer, completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: package.storeProduct,
                                       package: package,
                                       promotionalOffer: promotionalOffer,
                                       completion: completion)
    }

    /**
     * Purchase the passed ``Package``.
     * Call this method when a user has decided to purchase a product with an applied discount. Only call this in
     * direct response to user input. From here ``Purchases`` will handle the purchase with `StoreKit` and call the
     * ``PurchaseCompletedBlock``.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter package: The ``Package`` the user intends to purchase
     * - Parameter promotionalOffer: The ``PromotionalOffer`` to apply to the purchase
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchase(package: Package, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await purchaseAsync(package: package, promotionalOffer: promotionalOffer)
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and
     * become associated with the current ``appUserID``.
     *
     * If the receipt is being used by an existing user, the current ``appUserID`` will be aliased together with
     * the ``appUserID`` of the existing user.
     * Going forward, either ``appUserID`` will be able to reference the same user.
     *
     * - Warning: This function should only be called if you're not calling any purchase method.
     *
     * - Note: This method will not trigger a login prompt from App Store. However, if the receipt currently
     * on the device does not contain subscriptions, but the user has made subscription purchases, this method
     * won't be able to restore them. Use ``Purchases/restorePurchases(completion:)`` to cover those cases.
     */
    @objc func syncPurchases(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.purchasesOrchestrator.syncPurchases {
            completion?($0.value, $0.error?.asPublicError)
        }
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and
     * become associated with the current ``appUserID``.
     *
     * If the receipt is being used by an existing user, the current ``appUserID`` will be aliased together with
     * the ``appUserID`` of the existing user.
     * Going forward, either ``appUserID`` will be able to reference the same user.
     *
     * - Warning: This function should only be called if you're not calling any purchase method.
     *
     * - Note: This method will not trigger a login prompt from App Store. However, if the receipt currently
     * on the device does not contain subscriptions, but the user has made subscription purchases, this method
     * won't be able to restore them. Use ``Purchases/restorePurchases(completion:)`` to cover those cases.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func syncPurchases() async throws -> CustomerInfo {
        return try await syncPurchasesAsync()
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and become
     * associated with the current ``appUserID``. If the receipt is being used by an existing user, the current
     * ``appUserID`` will be aliased together with the ``appUserID`` of the existing user.
     *  Going forward, either ``appUserID`` will be able to reference the same user.
     *
     * You shouldn't use this method if you have your own account system. In that case "restoration" is provided
     * by your app passing the same ``appUserID`` used to purchase originally.
     *
     * - Note: This may force your users to enter the App Store password so should only be performed on request of
     * the user. Typically with a button in settings or near your purchase UI. Use
     * ``Purchases/syncPurchases(completion:)`` if you need to restore transactions programmatically.
     */
    @objc func restorePurchases(completion: ((CustomerInfo?, PublicError?) -> Void)? = nil) {
        purchasesOrchestrator.restorePurchases {
            completion?($0.value, $0.error?.asPublicError)
        }
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and become
     * associated with the current ``appUserID``. If the receipt is being used by an existing user, the current
     * ``appUserID`` will be aliased together with the ``appUserID`` of the existing user.
     *  Going forward, either ``appUserID`` will be able to reference the same user.
     *
     * You shouldn't use this method if you have your own account system. In that case "restoration" is provided
     * by your app passing the same ``appUserID`` used to purchase originally.
     *
     * - Note: This may force your users to enter the App Store password so should only be performed on request of
     * the user. Typically with a button in settings or near your purchase UI. Use
     * ``Purchases/syncPurchases(completion:)`` if you need to restore transactions programmatically.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func restorePurchases() async throws -> CustomerInfo {
        return try await restorePurchasesAsync()
    }

    /**
     * Computes whether or not a user is eligible for the introductory pricing period of a given product.
     * You should use this method to determine whether or not you show the user the normal product price or
     * the introductory price. This also applies to trials (trials are considered a type of introductory pricing).
     * [iOS Introductory  Offers](https://docs.revenuecat.com/docs/ios-subscription-offers).
     *
     * - Note: If you're looking to use Promotional Offers instead,
     * use ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``.
     *
     * - Note: Subscription groups are automatically collected for determining eligibility. If RevenueCat can't
     * definitively compute the eligibility, most likely because of missing group information, it will return
     * ``IntroEligibilityStatus/unknown``. The best course of action on unknown status is to display the non-intro
     * pricing, to not create a misleading situation. To avoid this, make sure you are testing with the latest
     * version of iOS so that the subscription group can be collected by the SDK.
     *
     *
     * - Parameter productIdentifiers: Array of product identifiers for which you want to compute eligibility
     * - Parameter completion: A block that receives a dictionary of `product_id` -> ``IntroEligibility``.
     *
     * ### Related symbols
     * - ``checkTrialOrIntroDiscountEligibility(product:completion:)``
     */
    @objc(checkTrialOrIntroDiscountEligibility:completion:)
    func checkTrialOrIntroDiscountEligibility(productIdentifiers: [String],
                                              completion: @escaping ([String: IntroEligibility]) -> Void) {
            trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: productIdentifiers,
                                                                 completion: completion)
    }

    /**
     * Computes whether or not a user is eligible for the introductory pricing period of a given product.
     * You should use this method to determine whether or not you show the user the normal product price or
     * the introductory price. This also applies to trials (trials are considered a type of introductory pricing).
     * [iOS Introductory  Offers](https://docs.revenuecat.com/docs/ios-subscription-offers).
     *
     * - Note: If you're looking to use Promotional Offers instead,
     * use ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``.
     *
     * - Note: Subscription groups are automatically collected for determining eligibility. If RevenueCat can't
     * definitively compute the eligibility, most likely because of missing group information, it will return
     * ``IntroEligibilityStatus/unknown``. The best course of action on unknown status is to display the non-intro
     * pricing, to not create a misleading situation. To avoid this, make sure you are testing with the latest
     * version of iOS so that the subscription group can be collected by the SDK.
     *
     * - Parameter productIdentifiers: Array of product identifiers for which you want to compute eligibility
     *
     * ### Related symbols
     * - ``checkTrialOrIntroDiscountEligibility(product:)``
     */
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func checkTrialOrIntroDiscountEligibility(productIdentifiers: [String]) async -> [String: IntroEligibility] {
        return await checkTrialOrIntroductoryDiscountEligibilityAsync(productIdentifiers)
    }

    /**
     * Computes whether or not a user is eligible for the introductory pricing period of a given product.
     * You should use this method to determine whether or not you show the user the normal product price or
     * the introductory price. This also applies to trials (trials are considered a type of introductory pricing).
     * [iOS Introductory  Offers](https://docs.revenuecat.com/docs/ios-subscription-offers).
     *
     * - Note: If you're looking to use Promotional Offers instead,
     * use ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``.
     *
     * - Note: Subscription groups are automatically collected for determining eligibility. If RevenueCat can't
     * definitively compute the eligibility, most likely because of missing group information, it will return
     * ``IntroEligibilityStatus/unknown``. The best course of action on unknown status is to display the non-intro
     * pricing, to not create a misleading situation. To avoid this, make sure you are testing with the latest
     * version of iOS so that the subscription group can be collected by the SDK.
     *
     *
     * - Parameter product: The ``StoreProduct``  for which you want to compute eligibility.
     * - Parameter completion: A block that receives an ``IntroEligibilityStatus``.
     *
     * ### Related symbols
     * - ``checkTrialOrIntroDiscountEligibility(productIdentifiers:completion:)``
     */
    @objc(checkTrialOrIntroDiscountEligibilityForProduct:completion:)
    func checkTrialOrIntroDiscountEligibility(product: StoreProduct,
                                              completion: @escaping (IntroEligibilityStatus) -> Void) {
        trialOrIntroPriceEligibilityChecker.checkEligibility(product: product, completion: completion)
    }

    /**
     * Computes whether or not a user is eligible for the introductory pricing period of a given product.
     * You should use this method to determine whether or not you show the user the normal product price or
     * the introductory price. This also applies to trials (trials are considered a type of introductory pricing).
     * [iOS Introductory  Offers](https://docs.revenuecat.com/docs/ios-subscription-offers).
     *
     * - Note: If you're looking to use Promotional Offers instead,
     * use ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``.
     *
     * - Note: Subscription groups are automatically collected for determining eligibility. If RevenueCat can't
     * definitively compute the eligibility, most likely because of missing group information, it will return
     * ``IntroEligibilityStatus/unknown``. The best course of action on unknown status is to display the non-intro
     * pricing, to not create a misleading situation. To avoid this, make sure you are testing with the latest
     * version of iOS so that the subscription group can be collected by the SDK.
     *
     *
     * - Parameter product: The ``StoreProduct``  for which you want to compute eligibility.
     * - Parameter completion: A block that receives an ``IntroEligibilityStatus``.
     *
     * ### Related symbols
     * - ``checkTrialOrIntroDiscountEligibility(productIdentifiers:)``
     */
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func checkTrialOrIntroDiscountEligibility(product: StoreProduct) async -> IntroEligibilityStatus {
        return await checkTrialOrIntroductoryDiscountEligibilityAsync(product)
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    /**
     * Displays price consent sheet if needed. You only need to call this manually if you implement
     * ``PurchasesDelegate/shouldShowPriceConsent`` and return false at some point.
     *
     * You may want to delay showing the sheet if it would interrupt your user’s interaction in your app. You can do
     * this by implementing ``PurchasesDelegate/shouldShowPriceConsent``.
     *
     * In most cases, you don't _*typically*_ implement ``PurchasesDelegate/shouldShowPriceConsent``, therefore,
     * you won't need to call this.
     *
     * ### Related Symbols
     * - ``SKPaymentQueue/showPriceConsentIfNeeded()`
     *
     * ### Related Articles
     * - [Apple Documentation](https://rev.cat/testing-promoted-in-app-purchases)
     */
    @available(iOS 13.4, macCatalyst 13.4, *)
    @objc func showPriceConsentIfNeeded() {
        self.paymentQueueWrapper.showPriceConsentIfNeeded()
    }
#endif

    /**
     * Invalidates the cache for customer information.
     *
     * Most apps will not need to use this method; invalidating the cache can leave your app in an invalid state.
     * Refer to
     * [Get User Information](https://docs.revenuecat.com/docs/purchaserinfo#section-get-user-information)
     * for more information on using the cache properly.
     *
     * This is useful for cases where customer information might have been updated outside of the app, like if a
     * promotional subscription is granted through the RevenueCat dashboard.
     */
    @objc func invalidateCustomerInfoCache() {
        self.customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)
    }

#if os(iOS)

    /**
     * Displays a sheet that enables users to redeem subscription offer codes that you generated in App Store Connect.
     *
     * - Important: Even though the docs in `SKPaymentQueue.presentCodeRedemptionSheet`
     * say that it's available on Catalyst 14.0, there is a note:
     * "`This function doesn’t affect Mac apps built with Mac Catalyst.`"
     * when, in fact, it crashes when called both from Catalyst and also when running as "Designed for iPad".
     * This is why RevenueCat's SDK makes it unavailable in mac catalyst.
     */
    @available(iOS 14.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @objc func presentCodeRedemptionSheet() {
        self.paymentQueueWrapper.presentCodeRedemptionSheet()
    }
#endif

    /**
     * Use this method to fetch ``PromotionalOffer``
     *  to use in ``purchase(package:promotionalOffer:)`` or ``purchase(product:promotionalOffer:)``.
     * [iOS Promotional Offers](https://docs.revenuecat.com/docs/ios-subscription-offers#promotional-offers).
     * - Note: If you're looking to use free trials or Introductory Offers instead,
     * use ``Purchases/checkTrialOrIntroDiscountEligibility(productIdentifiers:completion:)``.
     *
     * - Parameter discount: The ``StoreProductDiscount`` to apply to the product.
     * - Parameter product: The ``StoreProduct`` the user intends to purchase.
     * - Parameter completion: A completion block that is called when the ``PromotionalOffer`` is returned.
     * If it was not successful, there will be an `Error`.
     */
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

    /**
     * Use this method to find eligibility for this user for
     * [iOS Promotional Offers](https://docs.revenuecat.com/docs/ios-subscription-offers#promotional-offers).
     * - Note: If you're looking to use free trials or Introductory Offers instead,
     * use ``Purchases/checkTrialOrIntroDiscountEligibility(productIdentifiers:completion:)``.
     *
     * - Parameter discount: The ``StoreProductDiscount`` to apply to the product.
     * - Parameter product: The ``StoreProduct`` the user intends to purchase.
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer {
        return try await promotionalOfferAsync(forProductDiscount: discount, product: product)
    }

    /// Finds the subset of ``StoreProduct/discounts`` that's eligible for the current user.
    ///
    /// - Parameter product: the product to filter discounts from.
    /// - Note: if checking for eligibility for a `StoreProductDiscount` fails (for example, if network is down),
    ///   that discount will fail silently and be considered not eligible.
    /// #### Related Symbols
    /// - ``promotionalOffer(forProductDiscount:product:)``
    /// - ``StoreProduct/eligiblePromotionalOffers()``
    /// - ``StoreProduct/discounts``
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func eligiblePromotionalOffers(forProduct product: StoreProduct) async -> [PromotionalOffer] {
        return await eligiblePromotionalOffersAsync(forProduct: product)
    }

#if os(iOS) || os(macOS)

    /**
     * Use this function to open the manage subscriptions page.
     *
     * - Parameter completion: A completion block that will be called when the modal is opened,
     * not when it's actually closed. This is because of an undocumented change in StoreKit's behavior
     * between iOS 15.0 and 15.2, where 15.0 would return when the modal was closed, and 15.2 returns
     * when the modal is opened.
     *
     * If the manage subscriptions page can't be opened, the ``CustomerInfo/managementURL`` in
     * the ``CustomerInfo`` will be opened. If ``CustomerInfo/managementURL`` is not available,
     * the App Store's subscription management section will be opened.
     *
     * The `completion` block will be called when the modal is opened, not when it's actually closed.
     * This is because of an undocumented change in StoreKit's behavior between iOS 15.0 and 15.2,
     * where 15.0 would return when the modal was closed,
     * and 15.2 returns when the modal is opened.
     */
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 13.0, macOS 10.15, *)
    @objc func showManageSubscriptions(completion: @escaping (PublicError?) -> Void) {
        self.purchasesOrchestrator.showManageSubscription { error in
            completion(error?.asPublicError)
        }
    }

    /**
     * Use this function to open the manage subscriptions modal.
     *
     * - throws: an `Error` will be thrown if the current window scene couldn't be opened,
     * or the ``CustomerInfo/managementURL`` couldn't be obtained.
     * If the manage subscriptions page can't be opened, the ``CustomerInfo/managementURL`` in
     * the ``CustomerInfo`` will be opened. If ``CustomerInfo/managementURL`` is not available,
     * the App Store's subscription management section will be opened.
     */
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 13.0, macOS 10.15, *)
    func showManageSubscriptions() async throws {
        return try await showManageSubscriptionsAsync()
    }

#endif

#if os(iOS)
    /**
     * Presents a refund request sheet in the current window scene for
     * the latest transaction associated with the `productID`
     *
     * - Parameter productID: The `productID` to begin a refund request for.
     * If the request was successful, there will be a ``RefundRequestStatus``.
     * Keep in mind the status could be ``RefundRequestStatus/userCancelled``
     *
     * - throws: If the request was unsuccessful, there will be an `Error` and `RefundRequestStatus.error`.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(beginRefundRequestForProduct:completion:)
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        return try await purchasesOrchestrator.beginRefundRequest(forProduct: productID)
    }

    /**
     * Presents a refund request sheet in the current window scene for
     * the latest transaction associated with the entitlement ID.
     *
     * - Parameter entitlementID: The entitlementID to begin a refund request for.
     * - returns ``RefundRequestStatus``: The status of the refund request.
     * Keep in mind the status could be ``RefundRequestStatus/userCancelled``
     *
     * - throws: If the request was unsuccessful or the entitlement could not be found, an `Error` will be thrown.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(beginRefundRequestForEntitlement:completion:)
    func beginRefundRequest(forEntitlement entitlementID: String) async throws -> RefundRequestStatus {
        return try await purchasesOrchestrator.beginRefundRequest(forEntitlement: entitlementID)
    }

    /**
     * Presents a refund request sheet in the current window scene for
     * the latest transaction associated with the active entitlement.
     *
     * - returns ``RefundRequestStatus``: The status of the refund request.
     * Keep in mind the status could be ``RefundRequestStatus/userCancelled``
     *
     *- throws: If the request was unsuccessful, no active entitlements could be found for the user,
     * or multiple active entitlements were found for the user, an `Error` will be thrown.
     *
     *- important: This method should only be used if your user can only
     * have a single active entitlement at a given time.
     * If a user could have more than one entitlement at a time, use ``beginRefundRequest(forEntitlement:)`` instead.
     */
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
        configure(with: Configuration.builder(withAPIKey: apiKey).build())
    }

    // swiftlint:disable:next function_parameter_count
    @discardableResult internal static func configure(withAPIKey apiKey: String,
                                                      appUserID: String?,
                                                      observerMode: Bool,
                                                      userDefaults: UserDefaults?,
                                                      platformInfo: PlatformInfo?,
                                                      storeKit2Setting: StoreKit2Setting,
                                                      storeKitTimeout: TimeInterval,
                                                      networkTimeout: TimeInterval,
                                                      dangerousSettings: DangerousSettings?) -> Purchases {
        let purchases = Purchases(apiKey: apiKey,
                                  appUserID: appUserID,
                                  userDefaults: userDefaults,
                                  observerMode: observerMode,
                                  platformInfo: platformInfo,
                                  storeKit2Setting: storeKit2Setting,
                                  storeKitTimeout: storeKitTimeout,
                                  networkTimeout: networkTimeout,
                                  dangerousSettings: dangerousSettings)
        setDefaultInstance(purchases)
        return purchases
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
     * Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.
     *
     * - Parameter data: Dictionary provided by the network.
     * - Parameter network: Enum for the network the data is coming from, see ``AttributionNetwork`` for supported
     * networks.
     *
     * #### Related articles
     * - [Attribution](https://docs.revenuecat.com/docs/attribution)
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
            shared.post(attributionData: data, fromNetwork: network, forNetworkUserId: networkUserId)
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

internal extension Purchases {

    /// - Parameter syncedAttribute: will be called for every attribute that is updated
    /// - Parameter completion: will be called once all attributes have completed syncing
    /// - Returns: the number of attributes that will be synced
    @discardableResult
    func syncSubscriberAttributes(
        syncedAttribute: (@Sendable (PublicError?) -> Void)? = nil,
        completion: (@Sendable () -> Void)? = nil
    ) -> Int {
        return self.attribution.syncAttributesForAllUsers(currentAppUserID: self.appUserID,
                                                          syncedAttribute: { syncedAttribute?($0?.asPublicError) },
                                                          completion: completion)
    }

    // Used for testing
    var networkTimeout: TimeInterval {
        return self.backend.networkTimeout
    }

    // Used for testing
    var storeKitTimeout: TimeInterval {
        return self.productsManager.requestTimeout
    }

    var isSandbox: Bool {
        return self.systemInfo.isSandbox
    }

    /// For testing purposes
    var isStoreKit1Configured: Bool {
        return self.storeKit1Wrapper != nil
    }

}

// MARK: Private

private extension Purchases {

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
        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: self.appUserID,
                                                               isAppBackgrounded: isAppBackgrounded) {
                completion?($0.mapError { $0.asPublicError })
            }

            self.offeringsManager.updateOfferingsCache(appUserID: self.appUserID,
                                                       isAppBackgrounded: isAppBackgrounded,
                                                       completion: nil)
        }
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
