//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

extension SubscriberAttributesManager {

    func setAppstackAttributionParams(_ data: [AnyHashable: Any]?, appUserID: String) {
        guard let data = data else { return }

        setAppstackCampaignAttributes(from: data, appUserID: appUserID)
        setAppstackClickIDs(from: data, appUserID: appUserID)
        setAppstackIDAttribute(from: data, appUserID: appUserID)
    }

}

private extension SubscriberAttributesManager {

    enum AppstackAttributionKeys {

        static let appstackID = "appstack_id"
        static let adNetwork = "appstack_adnetwork"
        static let campaign = "appstack_campaign"
        static let adSet = "appstack_adset"
        static let adKey = "appstack_ad"
        static let keywords = "appstack_keywords"

        static let clickIDs = ["fbclid", "gclid", "wbraid", "gbraid", "ttclid"]

    }

    func setAppstackCampaignAttributes(from data: [AnyHashable: Any], appUserID: String) {
        if let mediaSource = stringValueForAppstackData(from: data, key: AppstackAttributionKeys.adNetwork) {
            setMediaSource(mediaSource, appUserID: appUserID)
            setAttributes([AppstackAttributionKeys.adNetwork: mediaSource], appUserID: appUserID)
        }

        if let campaign = stringValueForAppstackData(from: data, key: AppstackAttributionKeys.campaign) {
            setCampaign(campaign, appUserID: appUserID)
            setAttributes([AppstackAttributionKeys.campaign: campaign], appUserID: appUserID)
        }

        if let adGroup = stringValueForAppstackData(from: data, key: AppstackAttributionKeys.adSet) {
            setAdGroup(adGroup, appUserID: appUserID)
            setAttributes([AppstackAttributionKeys.adSet: adGroup], appUserID: appUserID)
        }

        // swiftlint:disable:next identifier_name
        if let ad = stringValueForAppstackData(from: data, key: AppstackAttributionKeys.adKey) {
            setAd(ad, appUserID: appUserID)
            setAttributes([AppstackAttributionKeys.adKey: ad], appUserID: appUserID)
        }

        if let keyword = stringValueForAppstackData(from: data, key: AppstackAttributionKeys.keywords) {
            setKeyword(keyword, appUserID: appUserID)
            setAttributes([AppstackAttributionKeys.keywords: keyword], appUserID: appUserID)
        }
    }

    func setAppstackClickIDs(from data: [AnyHashable: Any], appUserID: String) {
        for key in AppstackAttributionKeys.clickIDs {
            if let value = stringValueForAppstackData(from: data, key: key) {
                setAttributes([key: value], appUserID: appUserID)
            }
        }
    }

    func setAppstackIDAttribute(from data: [AnyHashable: Any], appUserID: String) {
        if let appstackID = stringValueForAppstackData(from: data, key: AppstackAttributionKeys.appstackID) {
            setAppstackID(appstackID, appUserID: appUserID)
        }
    }

    func stringValueForAppstackData(from data: [AnyHashable: Any], key: String) -> String? {
        guard let value = data[key as AnyHashable] else { return nil }

        if let stringValue = value as? String {
            return stringValue.isEmpty ? nil : stringValue
        }
        if let boolValue = value as? Bool { return String(boolValue) }
        if let number = value as? NSNumber {
            return number.stringValue
        }

        return nil
    }

}
