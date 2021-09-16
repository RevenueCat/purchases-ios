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

// swiftlint:disable file_length function_parameter_count type_body_length
import Foundation
import StoreKit

// MARK: Block definitions
// NOTE: Any changes here must be reflected in RevenueCat.h for ObjC compatibility.
/**
 Completion block for calls that send back a ``PurchaserInfo``
 */
public typealias ReceivePurchaserInfoBlock = (PurchaserInfo?, Error?) -> Void

/**
 Completion block for  ``Purchases/checkTrialOrIntroductoryPriceEligibility(_:completionBlock:)``
 */
public typealias ReceiveIntroEligibilityBlock = ([String: IntroEligibility]) -> Void

/**
 Completion block for ``Purchases/offerings(completionBlock:)``
 */

public typealias ReceiveOfferingsBlock = (Offerings?, Error?) -> Void

/**
 Completion block for ``Purchases/products(identifiers:completionBlock:)``
 */
public typealias ReceiveProductsBlock = ([SKProduct]) -> Void

/**
 Completion block for ``Purchases/purchase(product:completion:)``
 */
public typealias PurchaseCompletedBlock = (SKPaymentTransaction?, PurchaserInfo?, Error?, Bool) -> Void

/**
 Deferred block for ``Purchases/shouldPurchasePromoProduct(_:defermentBlock:)``
 */
public typealias DeferredPromotionalPurchaseBlock = (@escaping PurchaseCompletedBlock) -> Void

/**
 * Deferred block for ``Purchases/paymentDiscount(forProductDiscount:product:completion:)``
 */
@available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
public typealias PaymentDiscountBlock = (SKPaymentDiscount?, Error?) -> Void

/**
 * `Purchases` is the entry point for RevenueCat.framework. It should be instantiated as soon as your app has a unique
 * user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random
 * user identifier.
 *  - Warning: Only one instance of Purchases should be instantiated at a time! Use a configure method to let the
 *  framework handle the singleton instance for you.
 */
@objc(RCPurchases) public class Purchases: NSObject {

    @objc(sharedPurchases)
    public static var shared: Purchases {
        guard let purchases = purchases else {
            fatalError(Strings.purchase.purchases_nil.description)
        }

        return purchases
    }
    private static var purchases: Purchases?

    @objc public static var isConfigured: Bool { purchases != nil }

    /**
     * Delegate for `Purchases` instance. The delegate is responsible for handling promotional product purchases and
     * changes to purchaser information.
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
            purchaserInfoManager.delegate = self
            purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(appUserID: appUserID)
            Logger.debug(Strings.configure.delegate_set)
        }
    }

    private weak var privateDelegate: PurchasesDelegate?
    private let operationDispatcher: OperationDispatcher

    /**
     * Enable automatic collection of Apple Search Ads attribution. Disabled by default
     */
    @objc public static var automaticAppleSearchAdsAttributionCollection: Bool = false

    /**
     * Used to set the log level. Useful for debugging issues with the lovely team @RevenueCat
     */
    @objc public static var logLevel: LogLevel {
        get { Logger.logLevel }
        set { Logger.logLevel = newValue }
    }

    /**
     * Enable debug logging. Useful for debugging issues with the lovely team @RevenueCat.
     */
    @available(*, deprecated, message: "use Purchases.logLevel instead.")
    @objc public static var debugLogsEnabled: Bool {
        get { logLevel == .debug }
        set { logLevel = newValue ? .debug : .info }
    }

    /**
     * Set this property to your proxy URL before configuring Purchases *only* if you've received a proxy key value
     * from your RevenueCat contact.
     */
    @objc public static var proxyURL: URL? {
        get { SystemInfo.proxyURL }
        set { SystemInfo.proxyURL = newValue }
    }

    /**
     * Set this property to true *only* if you're transitioning an existing Mac app from the Legacy
     * Mac App Store into the Universal Store, and you've configured your RevenueCat app accordingly.
     * Contact support before using this.
     */
    @objc public static var forceUniversalAppStore: Bool {
        get { SystemInfo.forceUniversalAppStore }
        set { SystemInfo.forceUniversalAppStore = newValue }
    }

    /**
     * Set this property to true *only* when testing the ask-to-buy / SCA purchases flow. More information:
     * http://errors.rev.cat/ask-to-buy
     */
    @available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *)
    @objc public static var simulatesAskToBuyInSandbox: Bool {
        get { StoreKitWrapper.simulatesAskToBuyInSandbox }
        set { StoreKitWrapper.simulatesAskToBuyInSandbox = newValue }
    }

    /**
     * Indicates whether the user is allowed to make payments.
     */
    @objc public static func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }

    /**
     * Set a custom log handler for redirecting logs to your own logging system.
     * By default, this sends Info, Warn, and Error messages. If you wish to receive Debug level messages,
     * you must enable debug logs.
     */
    @objc public static var logHandler: (LogLevel, String) -> Void {
        get { Logger.logHandler }
        set { Logger.logHandler = newValue }
    }

    /// Current version of the Purchases framework.
    @objc public static var frameworkVersion: String { SystemInfo.frameworkVersion }

    @objc public var allowSharingAppStoreAccount: Bool {
        get { purchasesOrchestrator.allowSharingAppStoreAccount }
        set { purchasesOrchestrator.allowSharingAppStoreAccount = newValue }
    }

    @objc public var finishTransactions: Bool {
        get { systemInfo.finishTransactions }
        set { systemInfo.finishTransactions = newValue }
    }

    private let attributionFetcher: AttributionFetcher
    private let attributionPoster: AttributionPoster
    private let backend: Backend
    private let deviceCache: DeviceCache
    private let identityManager: IdentityManager
    private let introEligibilityCalculator: IntroEligibilityCalculator
    private let notificationCenter: NotificationCenter
    private let offeringsFactory: OfferingsFactory
    private let offeringsManager: OfferingsManager
    private let productsManager: ProductsManager
    private let purchaserInfoManager: PurchaserInfoManager
    private let purchasesOrchestrator: PurchasesOrchestrator
    private let receiptFetcher: ReceiptFetcher
    private let receiptParser: ReceiptParser
    private let requestFetcher: StoreKitRequestFetcher
    private let storeKitWrapper: StoreKitWrapper
    private let subscriberAttributesManager: SubscriberAttributesManager
    private let systemInfo: SystemInfo

    fileprivate static let initLock = NSLock()

    convenience init(apiKey: String, appUserID: String?) {
        self.init(apiKey: apiKey,
                  appUserID: appUserID,
                  userDefaults: nil,
                  observerMode: false,
                  platformFlavor: nil,
                  platformFlavorVersion: nil)
    }

    // swiftlint:disable function_body_length
    convenience init(apiKey: String,
                     appUserID: String?,
                     userDefaults: UserDefaults?,
                     observerMode: Bool,
                     platformFlavor: String?,
                     platformFlavorVersion: String?) {
        let operationDispatcher = OperationDispatcher()
        let receiptRefreshRequestFactory = ReceiptRefreshRequestFactory()
        let fetcher = StoreKitRequestFetcher(requestFactory: receiptRefreshRequestFactory,
                                             operationDispatcher: operationDispatcher)
        let receiptFetcher = ReceiptFetcher(requestFetcher: fetcher)
        let systemInfo: SystemInfo
        do {
            systemInfo = try SystemInfo(platformFlavor: platformFlavor,
                                        platformFlavorVersion: platformFlavorVersion,
                                        finishTransactions: !observerMode)
        } catch {
            fatalError(error.localizedDescription)
        }

        let eTagManager = ETagManager()
        let backend = Backend(apiKey: apiKey,
                              systemInfo: systemInfo,
                              eTagManager: eTagManager,
                              operationDispatcher: operationDispatcher)
        let storeKitWrapper = StoreKitWrapper()
        let offeringsFactory = OfferingsFactory()
        let userDefaults = userDefaults ?? UserDefaults.standard
        let deviceCache = DeviceCache(userDefaults: userDefaults)
        let introCalculator = IntroEligibilityCalculator()
        let receiptParser = ReceiptParser()
        let purchaserInfoManager = PurchaserInfoManager(operationDispatcher: operationDispatcher,
                                                        deviceCache: deviceCache,
                                                        backend: backend,
                                                        systemInfo: systemInfo)
        let identityManager = IdentityManager(deviceCache: deviceCache,
                                              backend: backend,
                                              purchaserInfoManager: purchaserInfoManager)
        let attributionTypeFactory = AttributionTypeFactory()
        let attributionFetcher = AttributionFetcher(attributionFactory: attributionTypeFactory, systemInfo: systemInfo)
        let attributionDataMigrator = AttributionDataMigrator()
        let subscriberAttributesManager = SubscriberAttributesManager(backend: backend,
                                                                      deviceCache: deviceCache,
                                                                      attributionFetcher: attributionFetcher,
                                                                      attributionDataMigrator: attributionDataMigrator)
        let attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFetcher: attributionFetcher,
                                                  subscriberAttributesManager: subscriberAttributesManager)
        let productsRequestFactory = ProductsRequestFactory()
        let productsManager = ProductsManager(productsRequestFactory: productsRequestFactory)
        let offeringsManager = OfferingsManager(deviceCache: deviceCache,
                                                operationDispatcher: operationDispatcher,
                                                systemInfo: systemInfo,
                                                backend: backend,
                                                offeringsFactory: offeringsFactory,
                                                productsManager: productsManager)
        let purchasesOrchestrator = PurchasesOrchestrator(productsManager: productsManager,
                                                          storeKitWrapper: storeKitWrapper,
                                                          systemInfo: systemInfo,
                                                          subscriberAttributesManager: subscriberAttributesManager,
                                                          operationDispatcher: operationDispatcher,
                                                          receiptFetcher: receiptFetcher,
                                                          purchaserInfoManager: purchaserInfoManager,
                                                          backend: backend,
                                                          identityManager: identityManager,
                                                          receiptParser: receiptParser,
                                                          deviceCache: deviceCache)
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
                  introEligibilityCalculator: introCalculator,
                  receiptParser: receiptParser,
                  purchaserInfoManager: purchaserInfoManager,
                  productsManager: productsManager,
                  offeringsManager: offeringsManager,
                  purchasesOrchestrator: purchasesOrchestrator)
    }
    // swiftlint:enable function_body_length

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
         introEligibilityCalculator: IntroEligibilityCalculator,
         receiptParser: ReceiptParser,
         purchaserInfoManager: PurchaserInfoManager,
         productsManager: ProductsManager,
         offeringsManager: OfferingsManager,
         purchasesOrchestrator: PurchasesOrchestrator) {

        Logger.debug(Strings.configure.debug_enabled)
        Logger.debug(Strings.configure.sdk_version(sdkVersion: Self.frameworkVersion))
        Logger.user(Strings.configure.initial_app_user_id(appUserID: appUserID))

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
        self.introEligibilityCalculator = introEligibilityCalculator
        self.receiptParser = receiptParser
        self.purchaserInfoManager = purchaserInfoManager
        self.productsManager = productsManager
        self.offeringsManager = offeringsManager
        self.purchasesOrchestrator = purchasesOrchestrator

        super.init()

        identityManager.configure(appUserID: appUserID)
        self.purchasesOrchestrator.maybeDelegate = self

        systemInfo.isApplicationBackgrounded { isBackgrounded in
            if isBackgrounded {
                self.purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(appUserID: self.appUserID)
            } else {
                self.operationDispatcher.dispatchOnWorkerThread {
                    self.updateAllCaches(completion: nil)
                }
            }
        }

        storeKitWrapper.delegate = purchasesOrchestrator
        subscribeToAppStateNotifications()
        attributionPoster.postPostponedAttributionDataIfNeeded()
        postAppleSearchAddsAttributionCollectionIfNeeded()
    }

    /**
     * Automatically collect subscriber attributes associated with the device identifiers
     * $idfa, $idfv, $ip
     */
    @objc public func collectDeviceIdentifiers() {
        subscriberAttributesManager.collectDeviceIdentifiers(forAppUserID: appUserID)
    }

    deinit {
        notificationCenter.removeObserver(self)
        storeKitWrapper.delegate = nil
        purchaserInfoManager.delegate = nil
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
     * restrictions refer to our guide: https://docs.revenuecat.com/docs/subscriber-attributes
     *
     * - Parameter attributes: Map of attributes by key. Set the value as an empty string to delete an attribute.
     */
    @objc public func setAttributes(_ attributes: [String: String]) {
        subscriberAttributesManager.setAttributes(attributes, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the email address for the user
     *
     * - Parameter email: Empty String or nil will delete the subscriber attribute.
     */
    @objc public func setEmail(_ email: String?) {
        subscriberAttributesManager.setEmail(email, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the phone number for the user
     *
     * - Parameter phoneNumber: Empty String or nil will delete the subscriber attribute.
     */
    @objc public func setPhoneNumber(_ phoneNumber: String?) {
        subscriberAttributesManager.setPhoneNumber(phoneNumber, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the display name for the user
     *
     * - Parameter displayName: Empty String or nil will delete the subscriber attribute.
     */
    @objc public func setDisplayName(_ displayName: String?) {
        subscriberAttributesManager.setDisplayName(displayName, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the push token for the user
     *
     * - Parameter pushToken: nil will delete the subscriber attribute.
     */
    @objc public func setPushToken(_ pushToken: Data?) {
        subscriberAttributesManager.setPushToken(pushToken, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Adjust Id for the user
     * Required for the RevenueCat Adjust integration
     *
     * - Parameter adjustID: nil will delete the subscriber attribute
     */
    @objc public func setAdjustID(_ adjustID: String?) {
        subscriberAttributesManager.setAdjustID(adjustID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Appsflyer Id for the user
     * Required for the RevenueCat Appsflyer integration
     *
     * - Parameter appsflyerID: nil will delete the subscriber attribute
     */
    @objc public func setAppsflyerID(_ appsflyerID: String?) {
        subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Facebook SDK Anonymous Id for the user
     * Recommended for the RevenueCat Facebook integration
     *
     * - Parameter fbAnonymousID: nil will delete the subscriber attribute
     */
    @objc public func setFBAnonymousID(_ fbAnonymousID: String?) {
        subscriberAttributesManager.setFBAnonymousID(fbAnonymousID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the mParticle Id for the user
     * Recommended for the RevenueCat mParticle integration
     *
     * - Parameter mparticleID: nil will delete the subscriber attribute
     */
    @objc public func setMparticleID(_ mparticleID: String?) {
        subscriberAttributesManager.setMparticleID(mparticleID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the OneSignal Player Id for the user
     * Required for the RevenueCat OneSignal integration
     *
     * - Parameter onesignalID: nil will delete the subscriber attribute
     */
    @objc public func setOnesignalID(_ onesignalID: String?) {
        subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install media source for the user
     *
     * - Parameter mediaSource: nil will delete the subscriber attribute.
     */
    @objc public func setMediaSource(_ mediaSource: String?) {
        subscriberAttributesManager.setMediaSource(mediaSource, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install campaign for the user
     *
     * - Parameter campaign: nil will delete the subscriber attribute.
     */
    @objc public func setCampaign(_ campaign: String?) {
        subscriberAttributesManager.setCampaign(campaign, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad group for the user
     *
     * - Parameter adGroup: nil will delete the subscriber attribute.
     */
    @objc public func setAdGroup(_ adGroup: String?) {
        subscriberAttributesManager.setAdGroup(adGroup, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad for the user
     *
     * - Parameter installAd: nil will delete the subscriber attribute.
     */
    @objc public func setAd(_ installAd: String?) {
        subscriberAttributesManager.setAd(installAd, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install keyword for the user
     *
     * - Parameter keyword: nil will delete the subscriber attribute.
     */
    @objc public func setKeyword(_ keyword: String?) {
        subscriberAttributesManager.setKeyword(keyword, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad creative for the user.
     *
     * - Parameter creative: nil will delete the subscriber attribute.
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

    /**
     * Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.
     *
     * - Parameter data: Dictionary provided by the network. See https://docs.revenuecat.com/docs/attribution
     * - Parameter network: Enum for the network the data is coming from, see ``AttributionNetwork`` for supported
     * networks.
     */
    @objc public static func addAttributionData(_ data: [String: Any], fromNetwork network: AttributionNetwork) {
            addAttributionData(data, fromNetwork: network, forNetworkUserId: nil)
    }

    /**
     * Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.
     *
     * - Parameter data: Dictionary provided by the network. See https://docs.revenuecat.com/docs/attribution
     * - Parameter network: Enum for the network the data is coming from, see ``AttributionNetwork`` for supported
     * networks.
     * - Parameter maybeNetworkUserId: User Id that should be sent to the network. Default is the current App User Id.
     */
    @objc public static func addAttributionData(_ data: [String: Any],
                                                fromNetwork network: AttributionNetwork,
                                                forNetworkUserId maybeNetworkUserId: String?) {
        if Self.isConfigured {
            shared.post(attributionData: data, fromNetwork: network, forNetworkUserId: maybeNetworkUserId)
        } else {
            AttributionPoster.store(postponedAttributionData: data,
                                    fromNetwork: network,
                                    forNetworkUserId: maybeNetworkUserId)
        }
    }

    /**
     * Send your attribution data to RevenueCat so you can track the revenue generated by your different campaigns.
     *
     * - Parameter data: Dictionary provided by the network. See https://docs.revenuecat.com/docs/attribution
     * - Parameter network: Enum for the network the data is coming from, see ``AttributionNetwork`` for supported
     * networks.
     * - Parameter networkUserId: User Id that should be sent to the network. Default is the current App User Id.
     */
    public static func addAttributionData(_ data: [String: Any],
                                          from network: AttributionNetwork,
                                          forNetworkUserId networkUserId: String?) {
        addAttributionData(data, fromNetwork: network, forNetworkUserId: networkUserId)
    }

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
    * The `appUserID` used by `Purchases`.
    * If not passed on initialization this will be generated and cached by `Purchases`.
    */
    @objc var appUserID: String { identityManager.currentAppUserID }

    /// If the `appUserID` has been generated by RevenueCat
    @objc var isAnonymous: Bool { identityManager.currentUserIsAnonymous }

    /**
     * This function will alias two appUserIDs together.
     *
     * - Parameter alias: The new appUserID that should be linked to the currently identified appUserID
     * - Parameter maybeCompletionBlock: An optional completion block called when the aliasing has been successful.
     * This completion block will receive an error if there's been one.
     */
    @objc func createAlias(_ alias: String, completionBlock maybeCompletionBlock: ReceivePurchaserInfoBlock?) {
        if alias == appUserID {
            purchaserInfoManager.purchaserInfo(appUserID: appUserID, completion: maybeCompletionBlock)
        } else {
            identityManager.createAlias(appUserID: alias) { maybeError in
                guard maybeError == nil else {
                    if let completion = maybeCompletionBlock {
                        self.operationDispatcher.dispatchOnMainThread {
                            completion(nil, maybeError)
                        }
                    }
                    return
                }

                self.updateAllCaches(completion: maybeCompletionBlock)
            }
        }
    }

    /**
     * This function will identify the current user with an appUserID. Typically this would be used after a
     * logout to identify a new user without calling configure.
     *
     * - Parameter appUserID: The appUserID that should be linked to the current user.
     */
    @objc func identify(_ appUserID: String, completionBlock maybeCompletion: ReceivePurchaserInfoBlock?) {
        if appUserID == identityManager.currentAppUserID {
            purchaserInfoManager.purchaserInfo(appUserID: self.appUserID, completion: maybeCompletion)
        } else {
            identityManager.identify(appUserID: appUserID) { maybeError in
                guard maybeError == nil else {
                    if let completion = maybeCompletion {
                        self.operationDispatcher.dispatchOnMainThread {
                            completion(nil, maybeError)
                        }
                    }
                    return
                }
                self.updateAllCaches(completion: maybeCompletion)
            }
        }
    }

    /**
     * This function will logIn the current user with an appUserID.
     *
     * - Parameter appUserID: The appUserID that should be linked to the current user.
     *
     * The callback will be called with the latest PurchaserInfo for the user, as well as a boolean
     * indicating whether the user was created for the first time in the RevenueCat backend.
     * See https://docs.revenuecat.com/docs/user-ids
     */
    @objc(logIn:completionBlock:)
    func logIn(appUserID: String, completionBlock completion: @escaping (PurchaserInfo?, Bool, Error?) -> Void) {
        identityManager.logIn(appUserID: appUserID) { purchaserInfo, created, maybeError in
            self.operationDispatcher.dispatchOnMainThread {
                completion(purchaserInfo, created, maybeError)
            }

            guard maybeError == nil else {
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
     * Logs out the Purchases client clearing the saved appUserID.
     * This will generate a random user id and save it in the cache.
     * If this method is called and the current user is anonymous, it will return an error.
     * See https://docs.revenuecat.com/docs/user-ids
     */
    @objc func logOut(completionBlock maybeCompletion: ReceivePurchaserInfoBlock?) {
        identityManager.logOut { maybeError in
            guard maybeError == nil else {
                if let completion = maybeCompletion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(nil, maybeError)
                    }
                }
                return
            }

            self.updateAllCaches(completion: maybeCompletion)
        }
    }

    /**
     * Resets the Purchases client clearing the saved appUserID.
     * This will generate a random user id and save it in the cache.
     */
    @objc func reset(completionBlock maybeCompletion: ReceivePurchaserInfoBlock?) {
        identityManager.resetAppUserID()
        updateAllCaches(completion: maybeCompletion)
    }

    /**
     * Fetch the configured offerings for this users. ``Offerings`` allows you to configure your in-app products
     * via RevenueCat and greatly simplifies management.
     * See the guide (https://docs.revenuecat.com/entitlements) for more info.
     *
     * ``Offerings`` will be fetched and cached on instantiation so that, by the time they are needed,
     * your prices are loaded for your purchase flow. Time is money.
     *
     * - Parameter completion: A completion block called when offerings are available.
     * Called immediately if offerings are cached. Offerings will be nil if an error occurred.
     */
    @objc func offerings(completionBlock completion: @escaping ReceiveOfferingsBlock) {
        offeringsManager.offerings(appUserID: appUserID, completion: completion)
    }

}

// MARK: Purchasing
public extension Purchases {

    /**
     * Get latest available purchaser info.
     *
     * - Parameter completion: A completion block called when purchaser info is available and not stale.
     * Called immediately if ``PurchaserInfo`` is cached. Purchaser info can be nil * if an error occurred.
     */
    @objc func purchaserInfo(completionBlock completion: @escaping ReceivePurchaserInfoBlock) {
        purchaserInfoManager.purchaserInfo(appUserID: appUserID, completion: completion)
    }

    /**
     * Fetches the `SKProducts` for your IAPs for given `productIdentifiers`.
     * Use this method if you aren't using `-offeringsWithCompletionBlock:`.
     * You should use offerings though.
     *
     * - Note: `completion` may be called without `SKProduct`s that you are expecting. This is usually caused by
     * iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect.
     * Also ensure that you have an active developer program subscription and you have signed the latest paid
     * application agreements.
     * If you're having trouble see: https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard
     *
     * - Parameter identifiers: A set of product identifiers for in app purchases setup via AppStoreConnect:
     * https://appstoreconnect.apple.com/
     * This should be either hard coded in your application, from a file, or from a custom endpoint if you want
     * to be able to deploy new IAPs without an app update.
     * - Parameter completion: An @escaping callback that is called with the loaded products.
     * If the fetch fails for any reason it will return an empty array.
     */
    @objc func products(identifiers: [String], completionBlock completion: @escaping ([SKProduct]) -> Void) {
        purchasesOrchestrator.products(withIdentifiers: identifiers, completion: completion)
    }

    /**
     * Use this function if you are not using the Offerings system to purchase an `SKProduct`.
     * If you are using the Offerings system, use ``Purchases/purchase(package:completion:)`` instead.
     *
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     *
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `PurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will
     * handle this for you.
     *
     * - Parameter product: The `SKProduct` the user intends to purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a `SKPaymentTransaction` and a ``PurchaserInfo``.
     *
     * If the purchase was not successful, there will be an `NSError`.
     *
     * If the user cancelled, `userCancelled` will be `YES`.
     */
    @objc(purchaseProduct:withCompletionBlock:)
    func purchase(product: SKProduct, completion: @escaping PurchaseCompletedBlock) {
        let payment: SKMutablePayment = storeKitWrapper.payment(withProduct: product)
        purchase(product: product, payment: payment, presentedOfferingIdentifier: nil, completion: completion)
    }

    /**
     * Purchase the passed ``Package``.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `PurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will
     * handle this for you.
     *
     * - Parameter package: The ``Package`` the user intends to purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a `SKPaymentTransaction` and a ``PurchaserInfo``.
     *
     * If the purchase was not successful, there will be an `Error`.
     *
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @objc(purchasePackage:withCompletionBlock:)
    func purchase(package: Package, completion: @escaping PurchaseCompletedBlock) {
        let payment = storeKitWrapper.payment(withProduct: package.product)
        purchase(product: package.product,
                 payment: payment,
                 presentedOfferingIdentifier: package.offeringIdentifier,
                 completion: completion)
    }

    /**
     * Use this function if you are not using the Offerings system to purchase an `SKProduct` with an
     * applied `SKPaymentDiscount`.
     * If you are using the Offerings system, use ``Purchases/purchase(package:discount:completion:)`` instead.
     *
     * Call this method when a user has decided to purchase a product with an applied discount.
     * Only call this in direct response to user input.
     *
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `PurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter product: The `SKProduct` the user intends to purchase
     * - Parameter discount: The `SKPaymentDiscount` to apply to the purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a `SKPaymentTransaction` and a ``PurchaserInfo``.
     * If the purchase was not successful, there will be an `Error`.
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc(purchaseProduct:withDiscount:completionBlock:)
    func purchase(product: SKProduct, discount: SKPaymentDiscount, completion: @escaping PurchaseCompletedBlock) {
        let payment = storeKitWrapper.payment(withProduct: product, discount: discount)
        purchase(product: product, payment: payment, presentedOfferingIdentifier: nil, completion: completion)
    }

    /**
     * Purchase the passed ``Package``.
     * Call this method when a user has decided to purchase a product with an applied discount. Only call this in
     * direct response to user input. From here `Purchases` will handle the purchase with `StoreKit` and call the
     * `PurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter package: The ``Package`` the user intends to purchase
     * - Parameter discount: The `SKPaymentDiscount` to apply to the purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a `SKPaymentTransaction` and a ``PurchaserInfo``.
     * If the purchase was not successful, there will be an `Error`.
     * If the user cancelled, `userCancelled` will be `true`.
     */
    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc(purchasePackage:withDiscount:completionBlock:)
    func purchase(package: Package, discount: SKPaymentDiscount, completion: @escaping PurchaseCompletedBlock) {
        let payment = storeKitWrapper.payment(withProduct: package.product, discount: discount)
        purchase(product: package.product,
                 payment: payment,
                 presentedOfferingIdentifier: package.offeringIdentifier,
                 completion: completion)
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and
     * become associated with the current ``appUserID``.
     *
     * If the receipt is being used by an existing user, the current ``appUserID`` will be aliased together with
     * the `appUserID` of the existing user.
     * Going forward, either `appUserID` will be able to reference the same user.
     *
     * - Warning: This function should only be called if you're not calling any purchase method.
     *
     * - Note: This method will not trigger a login prompt from App Store. However, if the receipt currently
     * on the device does not contain subscriptions, but the user has made subscription purchases, this method
     * won't be able to restore them. Use restoreTransactionsWithCompletionBlock to cover those cases.
     */
    @objc func syncPurchases(completionBlock completion: ReceivePurchaserInfoBlock?) {
        purchasesOrchestrator.syncPurchases(completion: completion)
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and become
     * associated with the current ``appUserID``. If the receipt is being used by an existing user, the current
     * ``appUserID`` will be aliased together with the `appUserID` of the existing user.
     *  Going forward, either `appUserID` will be able to reference the same user.
     *
     * You shouldn't use this method if you have your own account system. In that case "restoration" is provided
     * by your app passing the same `appUserId` used to purchase originally.
     *
     * - Note: This may force your users to enter the App Store password so should only be performed on request of
     * the user. Typically with a button in settings or near your purchase UI. Use
     * ``Purchases/syncPurchases(completionBlock:)`` if you need to restore transactions programmatically.
     */
    @objc func restoreTransactions(completionBlock completion: ReceivePurchaserInfoBlock? = nil) {
        purchasesOrchestrator.restoreTransactions(completion: completion)
    }

    /**
     * Computes whether or not a user is eligible for the introductory pricing period of a given product.
     * You should use this method to determine whether or not you show the user the normal product price or
     * the introductory price. This also applies to trials (trials are considered a type of introductory pricing).
     *
     * - Note: Subscription groups are automatically collected for determining eligibility. If RevenueCat can't
     * definitively compute the eligibilty, most likely because of missing group information, it will return
     * ``IntroEligibilityStatus/unknown``. The best course of action on unknown status is to display the non-intro
     * pricing, to not create a misleading situation. To avoid this, make sure you are testing with the latest
     * version of iOS so that the subscription group can be collected by the SDK.
     *
     * - Parameter productIdentifiers: Array of product identifiers for which you want to compute eligibility
     * - Parameter receiveEligibility: A block that receives a dictionary of product_id -> ``IntroEligibility``.
     */
    @objc
    // swiftlint:disable line_length
    func checkTrialOrIntroductoryPriceEligibility(_ productIdentifiers: [String],
                                                  completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
    // swiftlint:enable line_length
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            if #available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *),
               let data = maybeData {
                self.modernEligibilityHandler(maybeReceiptData: data,
                                              productIdentifiers: productIdentifiers,
                                              completionBlock: receiveEligibility)
            } else {
                self.backend.getIntroEligibility(appUserID: self.appUserID,
                                                 receiptData: maybeData ?? Data(),
                                                 productIdentifiers: productIdentifiers) { result, maybeError in
                    if let error = maybeError {
                        Logger.error(String(format: "Unable to getIntroEligibilityForAppUserID: %@",
                                            error.localizedDescription))
                    }
                    self.operationDispatcher.dispatchOnMainThread {
                        receiveEligibility(result)
                    }
                }
            }
        }
    }

    /**
     * Invalidates the cache for purchaser information.
     *
     * Most apps will not need to use this method; invalidating the cache can leave your app in an invalid state.
     * Refer to https://docs.revenuecat.com/docs/purchaserinfo#section-get-user-information for more information on
     * using the cache properly.
     *
     * This is useful for cases where purchaser information might have been updated outside of the app, like if a
     * promotional subscription is granted through the RevenueCat dashboard.
     */
    @objc func invalidatePurchaserInfoCache() {
        purchaserInfoManager.clearPurchaserInfoCache(forAppUserID: appUserID)
    }

    #if os(iOS)
    /**
     * Displays a sheet that enables users to redeem subscription offer codes that you generated in App Store Connect.
     */
    @available(iOS 14.0, *)
    @objc func presentCodeRedemptionSheet() {
        storeKitWrapper.presentCodeRedemptionSheet()
    }
    #endif

    /**
     * Use this function to retrieve the `SKPaymentDiscount` for a given `SKProduct`.
     *
     * - Parameter discount: The `SKProductDiscount` to apply to the product.
     * - Parameter product: The `SKProduct` the user intends to purchase.
     * - Parameter completion: A completion block that is called when the `SKPaymentDiscount` is returned.
     * If it was not successful, there will be an `Error`.
     */
    @available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
    @objc(paymentDiscountForProductDiscount:product:completion:)
    func paymentDiscount(forProductDiscount discount: SKProductDiscount,
                         product: SKProduct,
                         completion: @escaping PaymentDiscountBlock) {
        purchasesOrchestrator.paymentDiscount(forProductDiscount: discount, product: product, completion: completion)
    }

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    private func modernEligibilityHandler(maybeReceiptData data: Data,
                                          productIdentifiers: [String],
                                          completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:disable line_length
        introEligibilityCalculator
            .checkTrialOrIntroductoryPriceEligibility(with: data,
                                                      productIdentifiers: Set(productIdentifiers)) { receivedEligibility, maybeError in
                if let error = maybeError {
                    Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
                    self.backend.getIntroEligibility(appUserID: self.appUserID,
                                                     receiptData: data,
                                                     productIdentifiers: productIdentifiers) { result, maybeAnotherError in
                        if let intoEligibilityError = maybeAnotherError {
                            Logger.error(String(format: "Unable to getIntroEligibilityForAppUserID: %@",
                                                intoEligibilityError.localizedDescription))
                        }
                        self.operationDispatcher.dispatchOnMainThread {
                            receiveEligibility(result)
                        }
                    }
                } else {
                    var convertedEligibility: [String: IntroEligibility] = [:]
                    for (key, value) in receivedEligibility {
                        do {
                            let introEligibility = try IntroEligibility(eligibilityStatusCode: value)
                            convertedEligibility[key] = introEligibility
                        } catch {
                            Logger.error(String(format: "Unable to create an RCIntroEligibility: %@",
                                                error.localizedDescription))
                        }
                    }
                    self.operationDispatcher.dispatchOnMainThread {
                        receiveEligibility(convertedEligibility)
                    }
                }
            }
        // swiftlint:enable line_length
    }

    private func purchase(product: SKProduct,
                          payment: SKMutablePayment,
                          presentedOfferingIdentifier: String?,
                          completion: @escaping PurchaseCompletedBlock) {
        purchasesOrchestrator.purchase(product: product,
                                       payment: payment,
                                       presentedOfferingIdentifier: presentedOfferingIdentifier,
                                       completion: completion)
    }

}

// MARK: Configuring Purchases
public extension Purchases {

    /**
     * Configures an instance of the Purchases SDK with a specified API key. The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Note: Use this initializer if your app does not have an account system.
     * `Purchases` will generate a unique identifier for the current device and persist it to `NSUserDefaults`.
     * This also affects the behavior of ``Purchases/restoreTransactions(completionBlock:)``.
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:)
    @discardableResult static func configure(withAPIKey apiKey: String) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: nil)
    }

    /**
     * Configures an instance of the Purchases SDK with a specified API key and app user ID.
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
     * purchases and subscriptions across devices. Pass nil if you want `Purchases` to generate this for you.
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:)
    @discardableResult static func configure(withAPIKey apiKey: String, appUserID: String?) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: false)
    }

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults. Use this constructor if you want to
     * sync status across a shared container, such as between a host app and an extension. The instance of the
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass nil if you want `Purchases` to generate this for you.
     *
     * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
     * RevenueCat's backend. Default is `false`.
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: observerMode, userDefaults: nil)
    }

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults. Use this constructor if you want to
     * sync status across a shared container, such as between a host app and an extension. The instance of the
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass nil if you want `Purchases` to generate this for you.
     *
     * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
     * RevenueCat's backend. Default is `false`.
     *
     * - Parameter userDefaults: Custom userDefaults to use
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?) -> Purchases {
        configure(apiKey: apiKey,
                  appUserID: appUserID,
                  observerMode: observerMode,
                  userDefaults: userDefaults,
                  platformFlavor: nil,
                  platformFlavorVersion: nil)
    }

    static internal func configure(apiKey: String,
                                   appUserID: String?,
                                   observerMode: Bool,
                                   userDefaults: UserDefaults?,
                                   platformFlavor: String?,
                                   platformFlavorVersion: String?) -> Purchases {
        let purchases = Purchases(apiKey: apiKey,
                                  appUserID: appUserID,
                                  userDefaults: userDefaults,
                                  observerMode: observerMode,
                                  platformFlavor: platformFlavor,
                                  platformFlavorVersion: platformFlavorVersion)
        setDefaultInstance(purchases)
        return purchases
    }

}

// MARK: Delegate implementation
extension Purchases: PurchaserInfoManagerDelegate {

    public func purchaserInfoManagerDidReceiveUpdated(purchaserInfo: PurchaserInfo) {
        delegate?.purchases?(self, didReceiveUpdated: purchaserInfo)
    }

}

extension Purchases: PurchasesOrchestratorDelegate {

    /**
     * Called when a user initiates a promotional in-app purchase from the App Store.
     *
     * If your app is able to handle a purchase at the current time, run the deferment block in this method.
     *
     * If the app is not in a state to make a purchase: cache the defermentBlock, then call the defermentBlock
     * when the app is ready to make the promotional purchase.
     *
     * If the purchase should never be made, you don't need to ever call the defermentBlock and `Purchases`
     * will not proceed with promotional purchases.
     *
     * - Parameter product: `SKProduct` the product that was selected from the app store.
     */
    @objc
    public func shouldPurchasePromoProduct(_ product: SKProduct,
                                           defermentBlock: @escaping DeferredPromotionalPurchaseBlock) {
        guard let delegate = delegate else {
            return
        }

        delegate.purchases?(self, shouldPurchasePromoProduct: product, defermentBlock: defermentBlock)
    }

}

// MARK: Private
private extension Purchases {

    @objc func applicationDidBecomeActive(notification: Notification) {
        Logger.debug(Strings.configure.application_active)
        updateAllCachesIfNeeded()
        syncSubscriberAttributesIfNeeded()
        postAppleSearchAddsAttributionCollectionIfNeeded()
    }

    @objc func applicationWillResignActive(notification: Notification) {
        syncSubscriberAttributesIfNeeded()
    }

    func subscribeToAppStateNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidBecomeActive(notification:)),
                                       name: SystemInfo.applicationDidBecomeActiveNotification, object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillResignActive(notification:)),
                                       name: SystemInfo.applicationWillResignActiveNotification, object: nil)
    }

    func syncSubscriberAttributesIfNeeded() {
        operationDispatcher.dispatchOnWorkerThread {
            self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: self.appUserID)
        }
    }

    func updateAllCachesIfNeeded() {
        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(appUserID: self.appUserID,
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

    func updateAllCaches(completion: ReceivePurchaserInfoBlock?) {
        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.purchaserInfoManager.fetchAndCachePurchaserInfo(appUserID: self.appUserID,
                                                                 isAppBackgrounded: isAppBackgrounded,
                                                                 completion: completion)
            self.offeringsManager.updateOfferingsCache(appUserID: self.appUserID,
                                                       isAppBackgrounded: isAppBackgrounded,
                                                       completion: nil)
        }
    }

}
