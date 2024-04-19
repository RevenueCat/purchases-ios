//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Deprecations.swift
//
//  Created by Nacho Soto on 3/8/22.

import Foundation
import StoreKit

// swiftlint:disable line_length missing_docs file_length

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

public extension Purchases {

    @available(iOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(tvOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(watchOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macCatalyst, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    func checkTrialOrIntroDiscountEligibility(_ productIdentifiers: [String],
                                              completion: @escaping ([String: IntroEligibility]) -> Void) {
        self.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers, completion: completion)
    }

    @available(iOS, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(tvOS, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(watchOS, introduced: 6.2, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macOS, introduced: 10.15, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macCatalyst, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    func checkTrialOrIntroDiscountEligibility(_ productIdentifiers: [String]) async -> [String: IntroEligibility] {
        return await self.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers)
    }

    @available(iOS, introduced: 13.0, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(tvOS, introduced: 13.0, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(watchOS, introduced: 6.2, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(macOS, introduced: 10.15, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(macCatalyst, introduced: 13.0, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    func getPromotionalOffer(forProductDiscount discount: StoreProductDiscount,
                             product: StoreProduct) async throws -> PromotionalOffer {
        return try await self.promotionalOffer(forProductDiscount: discount, product: product)
    }

    @available(iOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(tvOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(watchOS, introduced: 6.2, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(macOS, introduced: 10.15, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(macCatalyst, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    func getEligiblePromotionalOffers(forProduct product: StoreProduct) async -> [PromotionalOffer] {
        return await eligiblePromotionalOffers(forProduct: product)
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
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
            useStoreKit2IfAvailable: StoreKitVersion.default == .storeKit2
        )
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
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

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:dangerousSettings:)
    // swiftlint:disable:next function_parameter_count
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?,
                                             useStoreKit2IfAvailable: Bool,
                                             dangerousSettings: DangerousSettings?) -> Purchases {
        return Self.configure(
            withAPIKey: apiKey,
            appUserID: appUserID,
            observerMode: observerMode,
            userDefaults: userDefaults,
            platformInfo: nil,
            responseVerificationMode: .default,
            storeKitVersion: useStoreKit2IfAvailable ? .storeKit2 : .storeKit1,
            storeKitTimeout: Configuration.storeKitRequestTimeoutDefault,
            networkTimeout: Configuration.networkTimeoutDefault,
            dangerousSettings: dangerousSettings,
            showStoreMessagesAutomatically: true,
            diagnosticsEnabled: false
        )
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
    @available(*, deprecated, message: """
    If you're using observer mode, also ensure that you call Purchases.handleObserverModeTransaction(result:) after making a purchase.
    """,
    renamed: "configure(withAPIKey:storeKitVersion:)")
    @_disfavoredOverload
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
    @_disfavoredOverload
    @objc(configureWithAPIKey:appUserID:)
    @available(*, deprecated, message: """
    If you're using observer mode, also ensure that you call Purchases.handleObserverModeTransaction(result:) after making a purchase.
    """,
    renamed: "configure(withAPIKey:appUserID:storeKitVersion:)")
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
     *
     * - Warning: This assumes your IAP implementation uses StoreKit 1.
     */
    @available(*, deprecated, message: """
    If you're using observer mode, also ensure that you call Purchases.handleObserverModeTransaction(result:) after making a purchase.
    """,
    renamed: "configure(withAPIKey:appUserID:observerMode:storeKitVersion:)")
    @objc(configureWithAPIKey:appUserID:observerMode:)
    @_disfavoredOverload
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool) -> Purchases {
        Self.configure(
            with: Configuration
                .builder(withAPIKey: apiKey)
                .with(appUserID: appUserID)
                .with(observerMode: observerMode, storeKitVersion: .storeKit1)
                .build()
        )
    }

    /**
     * Enable automatic collection of Apple Search Ads attribution. Defaults to `false`.
     */
    @available(*, deprecated, message: "Use Purchases.shared.attribution.enableAdServicesAttributionTokenCollection() instead")
    @objc static var automaticAppleSearchAdsAttributionCollection: Bool = false

}

public extension Purchases {

    @available(iOS, deprecated, renamed: "attribution.collectDeviceIdentifiers()")
    @available(tvOS, deprecated, renamed: "attribution.collectDeviceIdentifiers()")
    @available(watchOS, deprecated, renamed: "attribution.collectDeviceIdentifiers()")
    @available(macOS, deprecated, renamed: "attribution.collectDeviceIdentifiers()")
    @available(macCatalyst, deprecated, renamed: "attribution.collectDeviceIdentifiers()")
    @objc func collectDeviceIdentifiers() {
        self.attribution.collectDeviceIdentifiers()
    }

    @available(iOS, deprecated, renamed: "attribution.setAttributes(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setAttributes(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setAttributes(_:)")
    @available(macOS, deprecated, renamed: "attribution.setAttributes(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setAttributes(_:)")
    @objc func setAttributes(_ attributes: [String: String]) {
        self.attribution.setAttributes(attributes)
    }

    @available(iOS, deprecated, renamed: "attribution.setEmail(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setEmail(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setEmail(_:)")
    @available(macOS, deprecated, renamed: "attribution.setEmail(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setEmail(_:)")
    @objc func setEmail(_ email: String?) {
        self.attribution.setEmail(email)
    }

    @available(iOS, deprecated, renamed: "attribution.setPhoneNumber(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setPhoneNumber(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setPhoneNumber(_:)")
    @available(macOS, deprecated, renamed: "attribution.setPhoneNumber(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setPhoneNumber(_:)")
    @objc func setPhoneNumber(_ phoneNumber: String?) {
        self.attribution.setPhoneNumber(phoneNumber)
    }

    @available(iOS, deprecated, renamed: "attribution.setDisplayName(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setDisplayName(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setDisplayName(_:)")
    @available(macOS, deprecated, renamed: "attribution.setDisplayName(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setDisplayName(_:)")
    @objc func setDisplayName(_ displayName: String?) {
        self.attribution.setDisplayName(displayName)
    }

    @available(iOS, deprecated, renamed: "attribution.setPushToken(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setPushToken(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setPushToken(_:)")
    @available(macOS, deprecated, renamed: "attribution.setPushToken(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setPushToken(_:)")
    @objc func setPushToken(_ pushToken: Data?) {
        self.attribution.setPushToken(pushToken)
    }

    @available(iOS, deprecated, renamed: "attribution.setPushTokenString(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setPushTokenString(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setPushTokenString(_:)")
    @available(macOS, deprecated, renamed: "attribution.setPushTokenString(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setPushTokenString(_:)")
    @objc func setPushTokenString(_ pushToken: String?) {
        self.attribution.setPushTokenString(pushToken)
    }

    @available(iOS, deprecated, renamed: "attribution.setAdjustID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setAdjustID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setAdjustID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setAdjustID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setAdjustID(_:)")
    @objc func setAdjustID(_ adjustID: String?) {
        self.attribution.setAdjustID(adjustID)
    }

    @available(iOS, deprecated, renamed: "attribution.setAppsflyerID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setAppsflyerID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setAppsflyerID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setAppsflyerID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setAppsflyerID(_:)")
    @objc func setAppsflyerID(_ appsflyerID: String?) {
        self.attribution.setAppsflyerID(appsflyerID)
    }

    @available(iOS, deprecated, renamed: "attribution.setFBAnonymousID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setFBAnonymousID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setFBAnonymousID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setFBAnonymousID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setFBAnonymousID(_:)")
    @objc func setFBAnonymousID(_ fbAnonymousID: String?) {
        self.attribution.setFBAnonymousID(fbAnonymousID)
    }

    @available(iOS, deprecated, renamed: "attribution.setMparticleID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setMparticleID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setMparticleID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setMparticleID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setMparticleID(_:)")
    @objc func setMparticleID(_ mparticleID: String?) {
        self.attribution.setMparticleID(mparticleID)
    }

    @available(iOS, deprecated, renamed: "attribution.setOnesignalID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setOnesignalID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setOnesignalID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setOnesignalID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setOnesignalID(_:)")
    @objc func setOnesignalID(_ onesignalID: String?) {
        self.attribution.setOnesignalID(onesignalID)
    }

    @available(iOS, deprecated, renamed: "attribution.setAirshipChannelID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setAirshipChannelID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setAirshipChannelID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setAirshipChannelID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setAirshipChannelID(_:)")
    @objc func setAirshipChannelID(_ airshipChannelID: String?) {
        self.attribution.setAirshipChannelID(airshipChannelID)
    }

    @available(iOS, deprecated, renamed: "attribution.setCleverTapID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setCleverTapID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setCleverTapID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setCleverTapID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setCleverTapID(_:)")
    @objc func setCleverTapID(_ cleverTapID: String?) {
        self.attribution.setCleverTapID(cleverTapID)
    }

    @available(iOS, deprecated, renamed: "attribution.setMixpanelDistinctID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setMixpanelDistinctID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setMixpanelDistinctID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setMixpanelDistinctID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setMixpanelDistinctID(_:)")
    @objc func setMixpanelDistinctID(_ mixpanelDistinctID: String?) {
        self.attribution.setMixpanelDistinctID(mixpanelDistinctID)
    }

    @available(iOS, deprecated, renamed: "attribution.setFirebaseAppInstanceID(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setFirebaseAppInstanceID(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setFirebaseAppInstanceID(_:)")
    @available(macOS, deprecated, renamed: "attribution.setFirebaseAppInstanceID(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setFirebaseAppInstanceID(_:)")
    @objc func setFirebaseAppInstanceID(_ firebaseAppInstanceID: String?) {
        self.attribution.setFirebaseAppInstanceID(firebaseAppInstanceID)
    }

    @available(iOS, deprecated, renamed: "attribution.setMediaSource(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setMediaSource(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setMediaSource(_:)")
    @available(macOS, deprecated, renamed: "attribution.setMediaSource(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setMediaSource(_:)")
    @objc func setMediaSource(_ mediaSource: String?) {
        self.attribution.setMediaSource(mediaSource)
    }

    @available(iOS, deprecated, renamed: "attribution.setCampaign(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setCampaign(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setCampaign(_:)")
    @available(macOS, deprecated, renamed: "attribution.setCampaign(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setCampaign(_:)")
    @objc func setCampaign(_ campaign: String?) {
        self.attribution.setCampaign(campaign)
    }

    @available(iOS, deprecated, renamed: "attribution.setAdGroup(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setAdGroup(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setAdGroup(_:)")
    @available(macOS, deprecated, renamed: "attribution.setAdGroup(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setAdGroup(_:)")
    @objc func setAdGroup(_ adGroup: String?) {
        self.attribution.setAdGroup(adGroup)
    }

    @available(iOS, deprecated, renamed: "attribution.setAd(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setAd(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setAd(_:)")
    @available(macOS, deprecated, renamed: "attribution.setAd(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setAd(_:)")
    @objc func setAd(_ installAd: String?) {
        self.attribution.setAd(installAd)
    }

    @available(iOS, deprecated, renamed: "attribution.setKeyword(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setKeyword(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setKeyword(_:)")
    @available(macOS, deprecated, renamed: "attribution.setKeyword(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setKeyword(_:)")
    @objc func setKeyword(_ keyword: String?) {
        self.attribution.setKeyword(keyword)
    }

    @available(iOS, deprecated, renamed: "attribution.setCreative(_:)")
    @available(tvOS, deprecated, renamed: "attribution.setCreative(_:)")
    @available(watchOS, deprecated, renamed: "attribution.setCreative(_:)")
    @available(macOS, deprecated, renamed: "attribution.setCreative(_:)")
    @available(macCatalyst, deprecated, renamed: "attribution.setCreative(_:)")
    @objc func setCreative(_ creative: String?) {
        self.attribution.setCreative(creative)
    }

}

public extension StoreProduct {

    @available(iOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(tvOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(watchOS, introduced: 6.2, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(macOS, introduced: 10.15, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(macCatalyst, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers()")
    func getEligiblePromotionalOffers() async -> [PromotionalOffer] {
        return await self.eligiblePromotionalOffers()
    }

}

#endif

extension CustomerInfo {

    /// Returns all product IDs of the non-subscription purchases a user has made.
    @available(*, deprecated, message: "use nonSubscriptionTransactions")
    @objc public var nonConsumablePurchases: Set<String> {
        return Set(self.nonSubscriptionTransactions.map { $0.productIdentifier })
    }

    /**
     * Returns all the non-subscription purchases a user has made.
     * The purchases are ordered by purchase date in ascending order.
     */
    @available(*, deprecated, renamed: "nonSubscriptions")
    @objc public var nonSubscriptionTransactions: [StoreTransaction] {
        return self.nonSubscriptions
            .map(BackendParsedTransaction.init)
            .map(StoreTransaction.init)
    }

    @available(*, deprecated, message: "Use NonSubscriptionTransaction")
    private struct BackendParsedTransaction: StoreTransactionType, @unchecked Sendable {

        let productIdentifier: String
        let purchaseDate: Date
        let transactionIdentifier: String
        let quantity: Int
        var storefront: Storefront? { return nil }
        internal var jwsRepresentation: String? { return nil }
        internal var environment: StoreEnvironment? { return nil }

        var hasKnownPurchaseDate: Bool { true }
        var hasKnownTransactionIdentifier: Bool { return true }

        init(with transaction: NonSubscriptionTransaction) {
            self.productIdentifier = transaction.productIdentifier
            self.purchaseDate = transaction.purchaseDate
            self.transactionIdentifier = transaction.transactionIdentifier

            // Defaulting to `1` since multi-quantity purchases aren't currently supported.
            self.quantity = 1
        }

        func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
            completion()
        }

    }

}

public extension Configuration.Builder {

    @available(*, deprecated, message: "Use .with(storeKitVersion:) to enable StoreKit 2")
    @objc func with(usesStoreKit2IfAvailable: Bool) -> Configuration.Builder {
        return self.with(storeKitVersion: usesStoreKit2IfAvailable ? .storeKit2 : .default)
    }

}

// swiftlint:enable line_length missing_docs file_length
