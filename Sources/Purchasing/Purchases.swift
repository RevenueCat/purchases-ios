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
public typealias PurchaseCompletedBlock = (StoreTransaction?, CustomerInfo?, Error?, Bool) -> Void

/**
 Deferred block for ``Purchases/shouldPurchasePromoProduct(_:defermentBlock:)``
 */
public typealias DeferredPromotionalPurchaseBlock = (@escaping PurchaseCompletedBlock) -> Void

/**
 * ``Purchases`` is the entry point for RevenueCat.framework. It should be instantiated as soon as your app has a unique
 * user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random
 * user identifier.
 *  - Warning: Only one instance of Purchases should be instantiated at a time! Use a configure method to let the
 *  framework handle the singleton instance for you.
 */
@objc(RCPurchases) public class Purchases: NSObject {

    /// Returns the already configured instance of ``Purchases``.
    /// - Warning: this method will crash with `fatalError` if ``Purchases`` has not been initialized through
    /// ``configure(withAPIKey:)`` or one of its overloads. If there's a chance that may have not happened yet,
    /// you can use ``isConfigured`` to check if it's safe to call.
    /// ### Related symbols
    /// - ``isConfigured``
    @objc(sharedPurchases)
    public static var shared: Purchases {
        guard let purchases = purchases else {
            fatalError(Strings.purchase.purchases_nil.description)
        }

        return purchases
    }
    private static var purchases: Purchases?

    /// Returns `true` if RevenueCat has already been initialized through ``configure(withAPIKey:)``
    /// or one of is overloads.
    @objc public static var isConfigured: Bool { purchases != nil }

    /**
     * Delegate for ``Purchases`` instance. The delegate is responsible for handling promotional product purchases and
     * changes to customer information.
     */
    @objc public var delegate: PurchasesDelegate? {
        get { privateDelegate }
        set {
            guard newValue !== privateDelegate else {
                Logger.warn(Strings.purchase.purchases_delegate_set_multiple_times)
                return
            }

            if newValue == nil {
                Logger.info(Strings.purchase.purchases_delegate_set_to_nil)
            }

            privateDelegate = newValue
            customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)
            Logger.debug(Strings.configure.delegate_set)
        }
    }

    private weak var privateDelegate: PurchasesDelegate?
    private let operationDispatcher: OperationDispatcher

    /**
     * Enable automatic collection of Apple Search Ads attribution. Defaults to `false`.
     */
    @objc public static var automaticAppleSearchAdsAttributionCollection: Bool = false

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
        get { StoreKitWrapper.simulatesAskToBuyInSandbox }
        set { StoreKitWrapper.simulatesAskToBuyInSandbox = newValue }
    }

    /**
     * Indicates whether the user is allowed to make payments.
     * [More information on when this might be `false` here](https://rev.cat/can-make-payments-apple)
     */
    @objc public static func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }

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

    /** Whether transactions should be finished automatically. `true` by default.
     * - Warning: Setting this value to `false` will prevent the SDK from finishing transactions.
     * In this case, you *must* finish transactions in your app, otherwise they will remain in the queue and
     * will turn up every time the app is opened.
     * More information on finishing transactions manually [is available here](https://rev.cat/finish-transactions).
     */
    @objc public var finishTransactions: Bool {
        get { systemInfo.finishTransactions }
        set { systemInfo.finishTransactions = newValue }
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
    private let storeKitWrapper: StoreKitWrapper
    private let subscriberAttributesManager: SubscriberAttributesManager
    private let systemInfo: SystemInfo
    private var customerInfoObservationDisposable: (() -> Void)?

    fileprivate static let initLock = NSLock()

    // swiftlint:disable:next function_body_length
    convenience init(apiKey: String,
                     appUserID: String?,
                     userDefaults: UserDefaults? = nil,
                     observerMode: Bool = false,
                     platformInfo: PlatformInfo? = Purchases.platformInfo,
                     useStoreKit2IfAvailable: Bool = false,
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
                                        useStoreKit2IfAvailable: useStoreKit2IfAvailable,
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
                              eTagManager: eTagManager,
                              attributionFetcher: attributionFetcher)
        let storeKitWrapper = StoreKitWrapper()
        let offeringsFactory = OfferingsFactory()
        let userDefaults = userDefaults ?? UserDefaults.standard
        let deviceCache = DeviceCache(systemInfo: systemInfo, userDefaults: userDefaults)
        let receiptParser = ReceiptParser()
        let transactionsManager = TransactionsManager(receiptParser: receiptParser)
        let customerInfoManager = CustomerInfoManager(operationDispatcher: operationDispatcher,
                                                      deviceCache: deviceCache,
                                                      backend: backend,
                                                      systemInfo: systemInfo)
        let identityManager = IdentityManager(deviceCache: deviceCache,
                                              backend: backend,
                                              customerInfoManager: customerInfoManager,
                                              appUserID: appUserID)
        let attributionDataMigrator = AttributionDataMigrator()
        let subscriberAttributesManager = SubscriberAttributesManager(backend: backend,
                                                                      deviceCache: deviceCache,
                                                                      operationDispatcher: operationDispatcher,
                                                                      attributionFetcher: attributionFetcher,
                                                                      attributionDataMigrator: attributionDataMigrator)
        let attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFetcher: attributionFetcher,
                                                  subscriberAttributesManager: subscriberAttributesManager)
        let productsRequestFactory = ProductsRequestFactory()
        let productsManager = ProductsManager(productsRequestFactory: productsRequestFactory, systemInfo: systemInfo)
        let introCalculator = IntroEligibilityCalculator(productsManager: productsManager, receiptParser: receiptParser)
        let offeringsManager = OfferingsManager(deviceCache: deviceCache,
                                                operationDispatcher: operationDispatcher,
                                                systemInfo: systemInfo,
                                                backend: backend,
                                                offeringsFactory: offeringsFactory,
                                                productsManager: productsManager)
        let manageSubsHelper = ManageSubscriptionsHelper(systemInfo: systemInfo,
                                                         customerInfoManager: customerInfoManager,
                                                         identityManager: identityManager)
        let beginRefundRequestHelper = BeginRefundRequestHelper(systemInfo: systemInfo,
                                                                customerInfoManager: customerInfoManager,
                                                                identityManager: identityManager)
        let purchasesOrchestrator = PurchasesOrchestrator(productsManager: productsManager,
                                                          storeKitWrapper: storeKitWrapper,
                                                          systemInfo: systemInfo,
                                                          subscriberAttributesManager: subscriberAttributesManager,
                                                          operationDispatcher: operationDispatcher,
                                                          receiptFetcher: receiptFetcher,
                                                          customerInfoManager: customerInfoManager,
                                                          backend: backend,
                                                          identityManager: identityManager,
                                                          transactionsManager: transactionsManager,
                                                          deviceCache: deviceCache,
                                                          manageSubscriptionsHelper: manageSubsHelper,
                                                          beginRefundRequestHelper: beginRefundRequestHelper)
        let trialOrIntroPriceChecker = TrialOrIntroPriceEligibilityChecker(receiptFetcher: receiptFetcher,
                                                                           introEligibilityCalculator: introCalculator,
                                                                           backend: backend,
                                                                           identityManager: identityManager,
                                                                           operationDispatcher: operationDispatcher,
                                                                           productsManager: productsManager)
        self.init(appUserID: appUserID,
                  requestFetcher: fetcher,
                  receiptFetcher: receiptFetcher,
                  attributionFetcher: attributionFetcher,
                  attributionPoster: attributionPoster,
                  backend: backend,
                  storeKitWrapper: storeKitWrapper,
                  notificationCenter: NotificationCenter.default,
                  systemInfo: systemInfo,
                  offeringsFactory: offeringsFactory,
                  deviceCache: deviceCache,
                  identityManager: identityManager,
                  subscriberAttributesManager: subscriberAttributesManager,
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
         storeKitWrapper: StoreKitWrapper,
         notificationCenter: NotificationCenter,
         systemInfo: SystemInfo,
         offeringsFactory: OfferingsFactory,
         deviceCache: DeviceCache,
         identityManager: IdentityManager,
         subscriberAttributesManager: SubscriberAttributesManager,
         operationDispatcher: OperationDispatcher,
         customerInfoManager: CustomerInfoManager,
         productsManager: ProductsManager,
         offeringsManager: OfferingsManager,
         purchasesOrchestrator: PurchasesOrchestrator,
         trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker
    ) {

        Logger.debug(Strings.configure.debug_enabled, fileName: nil)
        if systemInfo.useStoreKit2IfAvailable {
            Logger.info(Strings.configure.store_kit_2_enabled, fileName: nil)
        }
        Logger.debug(Strings.configure.sdk_version(sdkVersion: Self.frameworkVersion), fileName: nil)
        Logger.user(Strings.configure.initial_app_user_id(isSet: appUserID != nil), fileName: nil)

        self.requestFetcher = requestFetcher
        self.receiptFetcher = receiptFetcher
        self.attributionFetcher = attributionFetcher
        self.attributionPoster = attributionPoster
        self.backend = backend
        self.storeKitWrapper = storeKitWrapper
        self.offeringsFactory = offeringsFactory
        self.deviceCache = deviceCache
        self.identityManager = identityManager
        self.notificationCenter = notificationCenter
        self.systemInfo = systemInfo
        self.subscriberAttributesManager = subscriberAttributesManager
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
            storeKitWrapper.delegate = purchasesOrchestrator
        }
        subscribeToAppStateNotifications()
        attributionPoster.postPostponedAttributionDataIfNeeded()
        postAppleSearchAddsAttributionCollectionIfNeeded()

        self.customerInfoObservationDisposable = customerInfoManager.monitorChanges { [weak self] customerInfo in
            guard let self = self else { return }
            self.delegate?.purchases?(self, receivedUpdated: customerInfo)
        }
    }

    /**
     * Automatically collect subscriber attributes associated with the device identifiers
     * - `$idfa`
     * - `$idfv`
     * - `$ip`
     */
    @objc public func collectDeviceIdentifiers() {
        subscriberAttributesManager.collectDeviceIdentifiers(forAppUserID: appUserID)
    }

    deinit {
        notificationCenter.removeObserver(self)
        storeKitWrapper.delegate = nil
        customerInfoObservationDisposable?()
        privateDelegate = nil
        Self.automaticAppleSearchAdsAttributionCollection = false
        Self.proxyURL = nil
    }

    static func clearSingleton() {
        Self.purchases = nil
    }

    static func setDefaultInstance(_ purchases: Purchases) {
        initLock.lock()
        if isConfigured {
            Logger.info(Strings.configure.purchase_instance_already_set)
        }

        Self.purchases = purchases
        initLock.unlock()
    }

}

// MARK: SubscriberAttributesManager Setters.
extension Purchases {

    /**
     * Subscriber attributes are useful for storing additional, structured information on a user.
     * Since attributes are writable using a public key they should not be used for
     * managing secure or sensitive information such as subscription status, coins, etc.
     *
     * Key names starting with "$" are reserved names used by RevenueCat. For a full list of key
     * restrictions refer [to our guide](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter attributes: Map of attributes by key. Set the value as an empty string to delete an attribute.
     */
    @objc public func setAttributes(_ attributes: [String: String]) {
        subscriberAttributesManager.setAttributes(attributes, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the email address for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter email: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setEmail(_ email: String?) {
        subscriberAttributesManager.setEmail(email, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the phone number for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter phoneNumber: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setPhoneNumber(_ phoneNumber: String?) {
        subscriberAttributesManager.setPhoneNumber(phoneNumber, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the display name for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter displayName: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setDisplayName(_ displayName: String?) {
        subscriberAttributesManager.setDisplayName(displayName, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the push token for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter pushToken: `nil` will delete the subscriber attribute.
     */
    @objc public func setPushToken(_ pushToken: Data?) {
        subscriberAttributesManager.setPushToken(pushToken, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Adjust Id for the user.
     * Required for the RevenueCat Adjust integration.
     *
     * #### Related Articles
     * - [Adjust RevenueCat Integration](https://docs.revenuecat.com/docs/adjust)
     *
     *- Parameter adjustID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setAdjustID(_ adjustID: String?) {
        subscriberAttributesManager.setAdjustID(adjustID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Appsflyer Id for the user.
     * Required for the RevenueCat Appsflyer integration.
     *
     * #### Related Articles
     * - [AppsFlyer RevenueCat Integration](https://docs.revenuecat.com/docs/appsflyer)
     *
     *- Parameter appsflyerID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setAppsflyerID(_ appsflyerID: String?) {
        subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Facebook SDK Anonymous Id for the user.
     * Recommended for the RevenueCat Facebook integration.
     *
     * #### Related Articles
     * - [Facebook Ads RevenueCat Integration](https://docs.revenuecat.com/docs/facebook-ads)
     *
     *- Parameter fbAnonymousID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setFBAnonymousID(_ fbAnonymousID: String?) {
        subscriberAttributesManager.setFBAnonymousID(fbAnonymousID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the mParticle Id for the user.
     * Recommended for the RevenueCat mParticle integration.
     *
     * #### Related Articles
     * - [mParticle RevenueCat Integration](https://docs.revenuecat.com/docs/mparticle)
     *
     *- Parameter mparticleID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setMparticleID(_ mparticleID: String?) {
        subscriberAttributesManager.setMparticleID(mparticleID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the OneSignal Player ID for the user.
     * Required for the RevenueCat OneSignal integration.
     *
     * #### Related Articles
     * - [OneSignal RevenueCat Integration](https://docs.revenuecat.com/docs/onesignal)
     *
     *- Parameter onesignalID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setOnesignalID(_ onesignalID: String?) {
        subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Airship Channel ID for the user.
     * Required for the RevenueCat Airship integration.
     *
     * #### Related Articles
     * - [AirShip RevenueCat Integration](https://docs.revenuecat.com/docs/airship)
     *
     *- Parameter airshipChannelID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setAirshipChannelID(_ airshipChannelID: String?) {
        subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the CleverTap ID for the user.
     * Required for the RevenueCat CleverTap integration.
     *
     * #### Related Articles
     * - [CleverTap RevenueCat Integration](https://docs.revenuecat.com/docs/clevertap)
     *
     *- Parameter cleverTapID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setCleverTapID(_ cleverTapID: String?) {
        subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Mixpanel Distinct ID for the user.
     * Optional for the RevenueCat Mixpanel integration.
     *
     * #### Related Articles
     * - [Mixpanel RevenueCat Integration](https://docs.revenuecat.com/docs/mixpanel)
     *
     *- Parameter mixpanelDistinctID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setMixpanelDistinctID(_ mixpanelDistinctID: String?) {
        subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install media source for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter mediaSource: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setMediaSource(_ mediaSource: String?) {
        subscriberAttributesManager.setMediaSource(mediaSource, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install campaign for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter campaign: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setCampaign(_ campaign: String?) {
        subscriberAttributesManager.setCampaign(campaign, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad group for the user
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter adGroup: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setAdGroup(_ adGroup: String?) {
        subscriberAttributesManager.setAdGroup(adGroup, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad for the user
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter installAd: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setAd(_ installAd: String?) {
        subscriberAttributesManager.setAd(installAd, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install keyword for the user
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter keyword: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setKeyword(_ keyword: String?) {
        subscriberAttributesManager.setKeyword(keyword, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad creative for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter creative: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc public func setCreative(_ creative: String?) {
        subscriberAttributesManager.setCreative(creative, appUserID: appUserID)
    }

    func setPushTokenString(_ pushToken: String) {
        subscriberAttributesManager.setPushTokenString(pushToken, appUserID: appUserID)
    }

}

// MARK: Attribution.
extension Purchases {

    private func post(attributionData data: [String: Any],
                      fromNetwork network: AttributionNetwork,
                      forNetworkUserId networkUserId: String?) {
        attributionPoster.post(attributionData: data, fromNetwork: network, networkUserId: networkUserId)
    }

    private func postAppleSearchAddsAttributionCollectionIfNeeded() {
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
    func logIn(_ appUserID: String, completion: @escaping (CustomerInfo?, Bool, Error?) -> Void) {
        identityManager.logIn(appUserID: appUserID) { result in
            self.operationDispatcher.dispatchOnMainThread {
                completion(result.value?.info, result.value?.created ?? false, result.error)
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
    @objc func logOut(completion: ((CustomerInfo?, Error?) -> Void)?) {
        identityManager.logOut { error in
            guard error == nil else {
                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(nil, error)
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
     *``Offerings`` allows you to configure your in-app products
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
    @objc func getOfferings(completion: @escaping (Offerings?, Error?) -> Void) {
        offeringsManager.offerings(appUserID: appUserID, completion: completion)
    }

    /**
     * Fetch the configured ``Offerings`` for this user.
     *
     *``Offerings`` allows you to configure your in-app products
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
    @objc func getCustomerInfo(completion: @escaping (CustomerInfo?, Error?) -> Void) {
        customerInfoManager.customerInfo(appUserID: appUserID) { result in
            completion(result.value, result.error)
        }
    }

    /**
     * Get latest available customer  info.
     * Returns a value immediately if ``CustomerInfo`` is cached.
     *
     * #### Related Symbols
     * - ``Purchases/customerInfoStream``
     */
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfo() async throws -> CustomerInfo {
        return try await customerInfoAsync()
    }

    /// Returns an `AsyncStream` of ``CustomerInfo`` changes, starting from the last known value.
    ///
    /// #### Related Symbols
    /// - ``PurchasesDelegate/purchases(_:receivedUpdated:)``
    /// - ``Purchases/customerInfo()``
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

    // swiftlint:disable line_length
    /**
     * Fetches the ``StoreProduct``s for your IAPs for given `productIdentifiers`.
     *
     * Use this method if you aren't using ``getOfferings(completion:)``.
     * You should use ``getOfferings(completion:)`` though.
     *
     * - Note: `completion` may be called without ``StoreProduct``s that you are expecting. This is usually caused by
     * iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect.
     * Also ensure that you have an active developer program subscription and you have signed the latest paid
     * application agreements.
     * If you're having trouble, see:
     *  [App Store Connect In-App Purchase Configuration](https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard)
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
    // swiftlint:enable line_length

    // swiftlint:disable line_length
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
     * [App Store Connect In-App Purchase Configuration](https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard)
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
    // swiftlint:enable line_length

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
     * If the purchase was not successful, there will be an `Error`.
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
     * If the purchase was not successful, there will be an `Error`.
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
     * If the purchase was not successful, there will be an `Error`.
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
     * won't be able to restore them. Use ``restorePurchases(completion:)`` to cover those cases.
     */
    @objc func syncPurchases(completion: ((CustomerInfo?, Error?) -> Void)?) {
        purchasesOrchestrator.syncPurchases {
            completion?($0.value, $0.error)
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
     * won't be able to restore them. Use ``restorePurchases(completion:)`` to cover those cases.
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
    @objc func restorePurchases(completion: ((CustomerInfo?, Error?) -> Void)? = nil) {
        purchasesOrchestrator.restorePurchases {
            completion?($0.value, $0.error)
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
        customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)
    }

#if os(iOS)
    /**
     * Displays a sheet that enables users to redeem subscription offer codes that you generated in App Store Connect.
     */
    @available(iOS 14.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @objc func presentCodeRedemptionSheet() {
        storeKitWrapper.presentCodeRedemptionSheet()
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
                             completion: @escaping (PromotionalOffer?, Error?) -> Void) {
        purchasesOrchestrator.promotionalOffer(forProductDiscount: discount,
                                               product: product) { result in
            completion(result.value, result.error)
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

     * - Parameter completion: A completion block that is called when the modal is closed.
     * If it was not successful, there will be an `Error`.

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
    @objc func showManageSubscriptions(completion: @escaping (Error?) -> Void) {
        purchasesOrchestrator.showManageSubscription(completion: completion)
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
        configure(withAPIKey: apiKey, appUserID: nil)
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
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: false)
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
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: observerMode, userDefaults: nil)
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
     * - Parameter userDefaults: Custom `UserDefaults` to use
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?) -> Purchases {
        configure(
            withAPIKey: apiKey,
            appUserID: appUserID,
            observerMode: observerMode,
            userDefaults: userDefaults,
            useStoreKit2IfAvailable: false
        )
    }

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults.
     *
     * Use this constructor if you want to sync status across a shared container,
     * such as between a host app and an extension.
     * The instance of the `Purchases` SDK will be set as a singleton.
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
     * - Parameter userDefaults: Custom `UserDefaults` to use
     *
     * - Parameter useStoreKit2IfAvailable: EXPERIMENTAL. opt in to using StoreKit 2 on devices that support it.
     * Purchases will be made using StoreKit 2 under the hood automatically.
     * - Important: Support for purchases using StoreKit 2 is currently in an experimental phase.
     * We recommend setting this value to `false` (default) for production apps.
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?,
                                             useStoreKit2IfAvailable: Bool) -> Purchases {
        configure(
            withAPIKey: apiKey,
            appUserID: appUserID,
            observerMode: observerMode,
            userDefaults: userDefaults,
            useStoreKit2IfAvailable: useStoreKit2IfAvailable,
            dangerousSettings: nil
        )
    }

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults.
     *
     * Use this constructor if you want to sync status across a shared container,
     * such as between a host app and an extension.
     * The instance of the `Purchases` SDK will be set as a singleton.
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
     * - Parameter userDefaults: Custom `UserDefaults` to use
     *
     * - Parameter dangerousSettings: Only use if suggested by RevenueCat support team.
     *
     * - Parameter useStoreKit2IfAvailable: EXPERIMENTAL. opt in to using StoreKit 2 on devices that support it.
     * Purchases will be made using StoreKit 2 under the hood automatically.
     * - Important: Support for purchases using StoreKit 2 is currently in an experimental phase.
     * We recommend setting this value to `false` (default) for production apps.
     *
     * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:dangerousSettings:)
    // swiftlint:disable:next function_parameter_count
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?,
                                             useStoreKit2IfAvailable: Bool,
                                             dangerousSettings: DangerousSettings?) -> Purchases {
        let purchases = Purchases(apiKey: apiKey,
                                  appUserID: appUserID,
                                  userDefaults: userDefaults,
                                  observerMode: observerMode,
                                  platformInfo: nil,
                                  useStoreKit2IfAvailable: useStoreKit2IfAvailable,
                                  dangerousSettings: dangerousSettings)
        setDefaultInstance(purchases)
        return purchases
    }
}

// MARK: Delegate implementation

extension Purchases: PurchasesOrchestratorDelegate {

    /**
     * Called when a user initiates a promotional in-app purchase from the App Store.
     *
     * If your app is able to handle a purchase at the current time, run the deferment block in this method.
     *
     * If the app is not in a state to make a purchase: cache the defermentBlock, then call the defermentBlock
     * when the app is ready to make the promotional purchase.
     *
     * If the purchase should never be made, you don't need to ever call the defermentBlock and ``Purchases``
     * will not proceed with promotional purchases.
     *
     * - Parameter product: ``StoreProduct`` the product that was selected from the app store.
     */
    @objc
    public func shouldPurchasePromoProduct(_ product: StoreProduct,
                                           defermentBlock: @escaping DeferredPromotionalPurchaseBlock) {
        guard let delegate = delegate else {
            return
        }

        delegate.purchases?(self, shouldPurchasePromoProduct: product, defermentBlock: defermentBlock)
    }

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

// MARK: Internal
internal extension Purchases {

    /// - Parameter syncedAttribute: will be called for every attribute that is updated
    /// - Parameter completion: will be called once all attributes have completed syncing
    /// - Returns: the number of attributes that will be synced
    @discardableResult
    func syncSubscriberAttributesIfNeeded(
        syncedAttribute: ((Error?) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> Int {
        return self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: self.appUserID,
                                                                          syncedAttribute: syncedAttribute,
                                                                          completion: completion)
    }

}

// MARK: Private
private extension Purchases {

    @objc func applicationDidBecomeActive(notification: Notification) {
        Logger.debug(Strings.configure.application_active)
        updateAllCachesIfNeeded()
        dispatchSyncSubscriberAttributesIfNeeded()
        postAppleSearchAddsAttributionCollectionIfNeeded()
    }

    @objc func applicationWillResignActive(notification: Notification) {
        dispatchSyncSubscriberAttributesIfNeeded()
    }

    func subscribeToAppStateNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidBecomeActive(notification:)),
                                       name: SystemInfo.applicationDidBecomeActiveNotification, object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillResignActive(notification:)),
                                       name: SystemInfo.applicationWillResignActiveNotification, object: nil)
    }

    func dispatchSyncSubscriberAttributesIfNeeded() {
        operationDispatcher.dispatchOnWorkerThread {
            self.syncSubscriberAttributesIfNeeded()
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

    func updateAllCaches(completion: ((Result<CustomerInfo, Error>) -> Void)?) {
        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: self.appUserID,
                                                               isAppBackgrounded: isAppBackgrounded,
                                                               completion: completion)
            self.offeringsManager.updateOfferingsCache(appUserID: self.appUserID,
                                                       isAppBackgrounded: isAppBackgrounded,
                                                       completion: nil)
        }
    }

}
