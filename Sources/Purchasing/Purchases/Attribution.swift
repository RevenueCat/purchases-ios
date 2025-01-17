//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Attribution.swift
//
//  Created by Joshua Liebowitz on 6/8/22.

import Foundation

// swiftlint:disable file_length

/**
 * This class is responsible for all explicit attribution APIs as well as subscriber attributes that RevenueCat offers.
 * The attributes are additional structured information on a user. Since attributes are writable using a public key
 * they should not be used for managing secure or sensitive information such as subscription status, coins, etc.
 *
 * Key names starting with "$" are reserved names used by RevenueCat. For a full list of key restrictions refer
 * [to our guide](https://docs.revenuecat.com/docs/subscriber-attributes)
 */
@objc(RCAttribution) public final class Attribution: NSObject {

    // internal for testing purposes
    var automaticAdServicesAttributionTokenCollection: Bool = false

    private let subscriberAttributesManager: SubscriberAttributesManager
    private let currentUserProvider: CurrentUserProvider
    private let attributionPoster: AttributionPoster
    private let systemInfo: SystemInfo

    private var appUserID: String { self.currentUserProvider.currentAppUserID }

    weak var delegate: AttributionDelegate?

    init(subscriberAttributesManager: SubscriberAttributesManager,
         currentUserProvider: CurrentUserProvider,
         attributionPoster: AttributionPoster,
         systemInfo: SystemInfo) {
        self.subscriberAttributesManager = subscriberAttributesManager
        self.currentUserProvider = currentUserProvider
        self.attributionPoster = attributionPoster
        self.systemInfo = systemInfo

        super.init()

        self.subscriberAttributesManager.delegate = self
    }

}

// should match OS availability in https://developer.apple.com/documentation/ad_services
@available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension Attribution {

    /**
     * Enable automatic collection of AdServices attribution token.
     */
    @objc func enableAdServicesAttributionTokenCollection() {
        self.automaticAdServicesAttributionTokenCollection = true

        self.postAdServicesTokenOncePerInstallIfNeeded()
    }

    internal func postAdServicesTokenOncePerInstallIfNeeded() {
        if self.automaticAdServicesAttributionTokenCollection,
           self.automaticAdServicesTokenPostingEnabled {
            self.attributionPoster.postAdServicesTokenOncePerInstallIfNeeded()
        }
    }

    private var automaticAdServicesTokenPostingEnabled: Bool {
        /// In custom entitlements computation mode, ad services token is sent only through `PostReceiptOperation`
        return !self.systemInfo.dangerousSettings.customEntitlementComputation
    }

}

#if !CUSTOM_ENTITLEMENTS_COMPUTATION

public extension Attribution {

    /**
     * Automatically collect subscriber attributes associated with the device identifiers
     * - `$idfa`
     * - `$idfv`
     * - `$ip`
     */
    @objc func collectDeviceIdentifiers() {
        self.subscriberAttributesManager.collectDeviceIdentifiers(forAppUserID: appUserID)
    }

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
    @objc func setAttributes(_ attributes: [String: String]) {
        self.subscriberAttributesManager.setAttributes(attributes, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the email address for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter email: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setEmail(_ email: String?) {
        self.subscriberAttributesManager.setEmail(email, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the phone number for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter phoneNumber: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setPhoneNumber(_ phoneNumber: String?) {
        self.subscriberAttributesManager.setPhoneNumber(phoneNumber, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the display name for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter displayName: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setDisplayName(_ displayName: String?) {
        self.subscriberAttributesManager.setDisplayName(displayName, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the push token for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter pushToken: `nil` will delete the subscriber attribute.
     *
     * #### Related Symbols
     * - ``Attribution/setPushTokenString(_:)``
     */
    @objc func setPushToken(_ pushToken: Data?) {
        self.subscriberAttributesManager.setPushToken(pushToken, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the push token for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter pushToken: `nil` will delete the subscriber attribute.
     *
     * #### Related Symbols
     * - ``Attribution/setPushToken(_:)``
     */
    @objc func setPushTokenString(_ pushToken: String?) {
        self.subscriberAttributesManager.setPushTokenString(pushToken, appUserID: appUserID)
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
    @objc func setAdjustID(_ adjustID: String?) {
        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: appUserID)
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
    @objc func setAppsflyerID(_ appsflyerID: String?) {
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: appUserID)
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
    @objc func setFBAnonymousID(_ fbAnonymousID: String?) {
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonymousID, appUserID: appUserID)
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
    @objc func setMparticleID(_ mparticleID: String?) {
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the OneSignal Player ID for the user.
     * Required for the RevenueCat OneSignal integration. Deprecated for OneSignal versions above v9.0.
     *
     * #### Related Articles
     * - [OneSignal RevenueCat Integration](https://docs.revenuecat.com/docs/onesignal)
     *
     *- Parameter onesignalID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setOnesignalID(_ onesignalID: String?) {
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the OneSignal User ID for the user.
     * Required for the RevenueCat OneSignal integration with versions v11.0 and above.
     *
     * #### Related Articles
     * - [OneSignal RevenueCat Integration](https://docs.revenuecat.com/docs/onesignal)
     *
     *- Parameter onesignalUserID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setOnesignalUserID(_ onesignalUserID: String?) {
        self.subscriberAttributesManager.setOnesignalUserID(onesignalUserID, appUserID: appUserID)
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
    @objc func setAirshipChannelID(_ airshipChannelID: String?) {
        self.subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: appUserID)
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
    @objc func setCleverTapID(_ cleverTapID: String?) {
        self.subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Kochava Device ID for the user.
     * Recommended for the RevenueCat Kochava integration.
     *
     * #### Related Articles
     * - [Kochava RevenueCat Integration](https://docs.revenuecat.com/docs/kochava)
     *
     * - Parameter kochavaDeviceID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setKochavaDeviceID(_ kochavaDeviceID: String?) {
        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceID, appUserID: appUserID)
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
    @objc func setMixpanelDistinctID(_ mixpanelDistinctID: String?) {
        self.subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Firebase App Instance ID for the user.
     * Required for the RevenueCat Firebase integration.
     *
     * #### Related Articles
     * - [Firebase RevenueCat Integration](https://docs.revenuecat.com/docs/firebase-integration)
     *
     *- Parameter firebaseAppInstanceID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setFirebaseAppInstanceID(_ firebaseAppInstanceID: String?) {
        self.subscriberAttributesManager.setFirebaseAppInstanceID(firebaseAppInstanceID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the Tenjin analytics installation ID for the user.
     * Required for the RevenueCat Tenjin integration.
     *
     *- Parameter firebaseAppInstanceID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setTenjinAnalyticsInstallationID(_ tenjinAnalyticsInstallationID: String?) {
        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(tenjinAnalyticsInstallationID,
                                                                          appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the PostHog User ID for the user.
     * Optional for the RevenueCat PostHog integration.
     *
     *- Parameter postHogUserID: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setPostHogUserID(_ postHogUserID: String?) {
        self.subscriberAttributesManager.setPostHogUserID(postHogUserID, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install media source for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter mediaSource: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setMediaSource(_ mediaSource: String?) {
        self.subscriberAttributesManager.setMediaSource(mediaSource, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install campaign for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter campaign: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setCampaign(_ campaign: String?) {
        self.subscriberAttributesManager.setCampaign(campaign, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad group for the user
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter adGroup: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setAdGroup(_ adGroup: String?) {
        self.subscriberAttributesManager.setAdGroup(adGroup, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad for the user
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter installAd: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setAd(_ installAd: String?) {
        self.subscriberAttributesManager.setAd(installAd, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install keyword for the user
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter keyword: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setKeyword(_ keyword: String?) {
        self.subscriberAttributesManager.setKeyword(keyword, appUserID: appUserID)
    }

    /**
     * Subscriber attribute associated with the install ad creative for the user.
     *
     * #### Related Articles
     * -  [Subscriber attributes](https://docs.revenuecat.com/docs/subscriber-attributes)
     *
     * - Parameter creative: Empty String or `nil` will delete the subscriber attribute.
     */
    @objc func setCreative(_ creative: String?) {
        self.subscriberAttributesManager.setCreative(creative, appUserID: appUserID)
    }

}

#endif

// @unchecked because:
// - It contains mutable state (`weak var delegate`).
extension Attribution: @unchecked Sendable {}

extension Attribution: SubscriberAttributesManagerDelegate {

    func subscriberAttributesManager(
        _ manager: SubscriberAttributesManager,
        didFinishSyncingAttributes attributes: SubscriberAttribute.Dictionary,
        forUserID userID: String
    ) {
        self.delegate?.attribution(didFinishSyncingAttributes: attributes, forUserID: userID)
    }

}

extension Attribution {

    /// - Parameter syncedAttribute: will be called for every attribute that is updated
    /// - Parameter completion: will be called once all attributes have completed syncing
    /// - Returns: the number of attributes that will be synced
    @discardableResult
    func syncSubscriberAttributes(
        syncedAttribute: (@Sendable (PurchasesError?) -> Void)? = nil,
        completion: (@Sendable () -> Void)? = nil
    ) -> Int {
        return self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: self.appUserID,
                                                                          syncedAttribute: syncedAttribute,
                                                                          completion: completion)
    }

    func unsyncedAttributesByKey(appUserID: String) -> SubscriberAttribute.Dictionary {
        self.subscriberAttributesManager.unsyncedAttributesByKey(appUserID: appUserID)
    }

    var unsyncedAdServicesToken: String? {
        get async {
            return self.automaticAdServicesAttributionTokenCollection
            ? await self.attributionPoster.adServicesTokenToPostIfNeeded
            : nil
        }
    }

    func unsyncedAdServicesToken(_ completion: @escaping (String?) -> Void) {
        guard self.automaticAdServicesAttributionTokenCollection else {
            completion(nil)
            return
        }

        Async.call(with: completion) {
            await self.attributionPoster.adServicesTokenToPostIfNeeded
        }
    }

    @discardableResult
    func syncAttributesForAllUsers(currentAppUserID: String,
                                   syncedAttribute: (@Sendable (PurchasesError?) -> Void)? = nil,
                                   completion: (@Sendable () -> Void)? = nil) -> Int {
        self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: currentAppUserID,
                                                                   syncedAttribute: syncedAttribute,
                                                                   completion: completion)
    }

    func markAttributesAsSynced(_ attributesToSync: SubscriberAttribute.Dictionary?, appUserID: String) {
        self.subscriberAttributesManager.markAttributesAsSynced(attributesToSync, appUserID: appUserID)
    }

    func markAdServicesTokenAsSynced(_ token: String, appUserID: String) {
        self.attributionPoster.markAdServicesToken(token, asSyncedFor: appUserID)
    }

}

protocol AttributionDelegate: AnyObject, Sendable {

    func attribution(didFinishSyncingAttributes attributes: SubscriberAttribute.Dictionary,
                     forUserID userID: String)

}
