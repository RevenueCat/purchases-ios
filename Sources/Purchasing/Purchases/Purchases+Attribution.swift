//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+Attribution.swift
//
//  Created by Joshua Liebowitz on 6/8/22.

import Foundation

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
        self.attribution.setAttributes(attributes)
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
        self.attribution.setEmail(email)
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
        self.attribution.setPhoneNumber(phoneNumber)
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
        self.attribution.setDisplayName(displayName)
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
     * - ``Purchases/setPushTokenString(_:)``
     */
    @objc public func setPushToken(_ pushToken: Data?) {
        self.attribution.setPushToken(pushToken)
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
     * - ``Purchases/setPushToken(_:)``
     */
    @objc public func setPushTokenString(_ pushToken: String?) {
        self.attribution.setPushTokenString(pushToken)
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
        self.attribution.setAdjustID(adjustID)
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
        self.attribution.setAppsflyerID(appsflyerID)
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
        self.attribution.setFBAnonymousID(fbAnonymousID)
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
        self.attribution.setMparticleID(mparticleID)
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
        self.attribution.setOnesignalID(onesignalID)
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
        self.attribution.setAirshipChannelID(airshipChannelID)
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
        self.attribution.setCleverTapID(cleverTapID)
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
        self.attribution.setMixpanelDistinctID(mixpanelDistinctID)
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
    @objc public func setFirebaseAppInstanceID(_ firebaseAppInstanceID: String?) {
        self.attribution.setFirebaseAppInstanceID(firebaseAppInstanceID)
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
        self.attribution.setMediaSource(mediaSource)
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
        self.attribution.setCampaign(campaign)
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
        self.attribution.setAdGroup(adGroup)
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
        self.attribution.setAd(installAd)
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
        self.attribution.setKeyword(keyword)
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
        self.attribution.setCreative(creative)
    }

    func setPushTokenString(_ pushToken: String) {
        self.attribution.setPushTokenString(pushToken)
    }

}
