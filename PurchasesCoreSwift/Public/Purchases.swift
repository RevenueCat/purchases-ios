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

// swiftlint:disable file_length
import Foundation
import StoreKit

/**
 Completion block for calls that send back a `PurchaserInfo`
 */
public typealias ReceivePurchaserInfoBlock = (PurchaserInfo?, Error?) -> Void

/**
 Completion block for `-[RCPurchases checkTrialOrIntroductoryPriceEligibility:completionBlock:]`
 */
public typealias ReceiveIntroEligibilityBlock = ([String: IntroEligibility]) -> Void

/**
 Completion block for `-[RCPurchases offeringsWithCompletionBlock:]`
 */

public typealias ReceiveOfferingsBlock = (Offerings?, Error?) -> Void

/**
 Completion block for `-[RCPurchases productsWithIdentifiers:completionBlock:]`
 */
public typealias ReceiveProductsBlock = ([SKProduct]) -> Void

/**
 Completion block for `-[RCPurchases purchaseProduct:withCompletionBlock:]`
 */
public typealias PurchaseCompletedBlock = (SKPaymentTransaction?, PurchaserInfo?, Error?, Bool) -> Void

/**
 Deferred block for `purchases:shouldPurchasePromoProduct:defermentBlock:`
 */
public typealias DeferredPromotionalPurchaseBlock = (@escaping PurchaseCompletedBlock) -> Void

/**
 * Deferred block for `-[RCPurchases paymentDiscountForProductDiscount:product:completion:]`
 */
@available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
public typealias PaymentDiscountBlock = (SKPaymentDiscount?, Error?) -> Void

/**
 * `Purchases` is the entry point for Purchases.framework. It should be instantiated as soon as your app has a unique
 * user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random
 * user identifier.
 *  @warning Only one instance of RCPurchases should be instantiated at a time! Use a configure method to let the
 *  framework handle the singleton instance for you.
 */
@objc public class Purchasess: NSObject {

    /**
     * Delegate for `Purchases` instance. The delegate is responsible for handling promotional product purchases and
     * changes to purchaser information.
     */
    public weak var delegate: PurchasessDelegate? {
        get { privateDelegate }
        set {
            privateDelegate = newValue
            purchaserInfoManager.delegate = self
            purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(appUserID: appUserID)
            Logger.debug(Strings.configure.delegate_set)
        }
    }

    private weak var privateDelegate: PurchasessDelegate?

    private let subscriberAttributesManager: SubscriberAttributesManager
    private let operationDispatcher: OperationDispatcher

    /**
     * Enable automatic collection of Apple Search Ads attribution. Disabled by default
     */
    @objc static var automaticAppleSearchAdsAttributionCollection: Bool = false

    /**
     * Used to set the log level. Useful for debugging issues with the lovely team @RevenueCat
     */
    @objc static var logLevel: LogLevel {
        get { Logger.logLevel }
        set { Logger.logLevel = newValue }
    }

    /**
     * Set this property to your proxy URL before configuring Purchases *only* if you've received a proxy key value
     * from your RevenueCat contact.
     */
    @objc static var proxyURL: URL? {
        get { SystemInfo.proxyURL }
        set { SystemInfo.proxyURL = newValue }
    }

    /**
     * Set this property to true *only* if you're transitioning an existing Mac app from the Legacy
     * Mac App Store into the Universal Store, and you've configured your RevenueCat app accordingly.
     * Contact support before using this.
     */
    @objc static var forceUniversalAppStore: Bool {
        get { SystemInfo.forceUniversalAppStore }
        set { SystemInfo.forceUniversalAppStore = newValue }
    }

    /**
     * Set this property to true *only* when testing the ask-to-buy / SCA purchases flow. More information:
     * http://errors.rev.cat/ask-to-buy
     */
    @available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *)
    @objc static var simulatesAskToBuyInSandbox: Bool {
        get { StoreKitWrapper.simulatesAskToBuyInSandbox }
        set { StoreKitWrapper.simulatesAskToBuyInSandbox = newValue }
    }

    /**
     * Enable debug logging. Useful for debugging issues with the lovely team @RevenueCat
     */
    @objc static var debugLogsEnabled: Bool {
        get { logLevel == .debug }
        set { logLevel = newValue ? .debug : .info }
    }

    /**
     * Set a custom log handler for redirecting logs to your own logging system.
     * By default, this sends Info, Warn, and Error messages. If you wish to receive Debug level messages,
     * you must enable debug logs.
     */
    @objc static var logHandler: (LogLevel, String) -> Void {
        get { Logger.logHandler }
        set { Logger.logHandler = newValue }
    }

    @objc static var frameworkVersion: String { SystemInfo.frameworkVersion }

    @objc var allowSharingAppStoreAccount: Bool {
        get { purchasesOrchestrator.allowSharingAppStoreAccount }
        set { purchasesOrchestrator.allowSharingAppStoreAccount = newValue }
    }

    @objc var finishTransactions: Bool {
        get { systemInfo.finishTransactions }
        set { systemInfo.finishTransactions = newValue }
    }

    @objc static var sharedPurchases: Purchasess { purchases }
    @objc static var isConfigured: Bool { purchases != nil }

    private static var purchases: Purchasess!
    private var appUserID: String { identityManager.currentAppUserID }

    private let requestFetcher: StoreKitRequestFetcher
    private let productsManager: ProductsManager
    private let receiptFetcher: ReceiptFetcher
    private let backend: Backend
    private let storeKitWrapper: StoreKitWrapper
    private let notificationCenter: NotificationCenter
    private let attributionFetcher: AttributionFetcher
    private let attributionPoster: AttributionPoster
    private let offeringsFactory: OfferingsFactory
    private let deviceCache: DeviceCache
    private let identityManager: IdentityManager
    private let systemInfo: SystemInfo
    private let introEligibilityCalculator: IntroEligibilityCalculator
    private let receiptParser: ReceiptParser
    private let purchaserInfoManager: PurchaserInfoManager
    private let offeringsManager: OfferingsManager
    private let purchasesOrchestrator: PurchasesOrchestrator

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
        Logger.debug(String(format: Strings.configure.sdk_version, Self.frameworkVersion))
        Logger.user(String(format: Strings.configure.initial_app_user_id, appUserID ?? "nil appUserID"))

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
        identityManager.configure(appUserID: appUserID)

        super.init()

        systemInfo.isApplicationBackgrounded { isBackgrounded in
            if !isBackgrounded {
                self.operationDispatcher.dispatchOnWorkerThread {
                    self.updateAllCaches(completion: nil)
                }
            } else {
                self.purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(appUserID: self.appUserID)
            }
        }

        storeKitWrapper.delegate = purchasesOrchestrator
        subscribeToAppStateNotifications()
        attributionPoster.postPostponedAttributionDataIfNeeded()
        postAppleSearchAddsAttributionCollectionIfNeeded()

    }

    private func postAppleSearchAddsAttributionCollectionIfNeeded() {
        guard Self.automaticAppleSearchAdsAttributionCollection else {
            return
        }

        attributionPoster.postAppleSearchAdsAttributionIfNeeded()
    }

    @objc func collectDeviceIdentifiers() {
        subscriberAttributesManager.collectDeviceIdentifiers(forAppUserID: appUserID)
    }

    deinit {
        storeKitWrapper.delegate = nil
        purchaserInfoManager.delegate = nil
        notificationCenter.removeObserver(self)
        delegate = nil
    }

}

extension Purchasess {

    private func subscribeToAppStateNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidBecomeActive(notification:)),
                                       name: SystemInfo.applicationDidBecomeActiveNotification, object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillResignActive(notification:)),
                                       name: SystemInfo.applicationWillResignActiveNotification, object: nil)
    }

    @objc private func applicationDidBecomeActive(notification: Notification) {
        Logger.debug(Strings.configure.application_active)
        updateAllCachesIfNeeded()
        syncSubscriberAttributesIfNeeded()
        postAppleSearchAddsAttributionCollectionIfNeeded()
    }

    @objc private func applicationWillResignActive(notification: Notification) {
        syncSubscriberAttributesIfNeeded()
    }

    private func syncSubscriberAttributesIfNeeded() {
        operationDispatcher.dispatchOnWorkerThread {
            self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: self.appUserID)
        }
    }

    private func updateAllCachesIfNeeded() {
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

    private func updateAllCaches(completion: ReceivePurchaserInfoBlock?) {
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

extension Purchasess: PurchaserInfoManagerDelegate {

    public func purchaserInfoManagerDidReceiveUpdated(purchaserInfo: PurchaserInfo) {
        delegate?.purchases?(self, didReceiveUpdated: purchaserInfo)
    }

}

extension Purchasess: PurchasesOrchestratorDelegate {

    public func shouldPurchasePromoProduct(_ product: SKProduct, defermentBlock: @escaping DeferredPromotionalPurchaseBlock) {
        delegate?.purchases?(self, shouldPurchasePromoProduct: product, defermentBlock: defermentBlock)
    }

}

extension Purchasess {
    @objc public func setAttributes(_ attributes: [String: String]) {
        subscriberAttributesManager.setAttributes(attributes, appUserID: appUserID)
    }

    @objc public func setEmail(_ email: String) {
        subscriberAttributesManager.setEmail(email, appUserID: appUserID)
    }

    @objc public func setPhoneNumber(_ phoneNumber: String) {
        subscriberAttributesManager.setPhoneNumber(phoneNumber, appUserID: appUserID)
    }

    @objc public func setDisplayName(_ displayName: String) {
        subscriberAttributesManager.setDisplayName(displayName, appUserID: appUserID)
    }

    @objc public func setPushToken(_ pushToken: Data) {
        subscriberAttributesManager.setPushToken(pushToken, appUserID: appUserID)
    }

    @objc public func _setPushTokenString(_ pushToken: String) {
        subscriberAttributesManager.setPushTokenString(pushToken, appUserID: appUserID)
    }

    @objc public func setAdjustID(_ adjustID: String) {
        subscriberAttributesManager.setAdjustID(adjustID, appUserID: appUserID)
    }

    @objc public func setAppsflyerID(_ appsflyerID: String) {
        subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: appUserID)
    }

    @objc public func setFBAnonymousID(_ fbAnonymousID: String) {
        subscriberAttributesManager.setFBAnonymousID(fbAnonymousID, appUserID: appUserID)
    }

    @objc public func setMparticleID(_ mparticleID: String) {
        subscriberAttributesManager.setMparticleID(mparticleID, appUserID: appUserID)
    }

    @objc public func setOnesignalID(_ onesignalID: String) {
        subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: appUserID)
    }

    @objc public func setMediaSource(_ mediaSource: String) {
        subscriberAttributesManager.setMediaSource(mediaSource, appUserID: appUserID)
    }

    @objc public func setCampaign(_ campaign: String) {
        subscriberAttributesManager.setCampaign(campaign, appUserID: appUserID)
    }

    @objc public func setAdGroup(_ adGroup: String) {
        subscriberAttributesManager.setAdGroup(adGroup, appUserID: appUserID)
    }

    @objc public func setAd(_ ad: String) {
        subscriberAttributesManager.setAd(ad, appUserID: appUserID)
    }

    @objc public func setKeyword(_ keyword: String) {
        subscriberAttributesManager.setKeyword(keyword, appUserID: appUserID)
    }

    @objc public func setCreative(_ creative: String) {
        subscriberAttributesManager.setCreative(creative, appUserID: appUserID)
    }

}
