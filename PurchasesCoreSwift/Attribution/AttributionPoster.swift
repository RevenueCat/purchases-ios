//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionPoster.swift
//
//  Created by Joshua Liebowitz on 8/11/21.

import Foundation

public class SubscriberAttributesManager: NSObject {

    @objc public func convertToSubscriberAttributes(attributionData: [String: Any], network: Int, appUserID: String) {
        // Stub
    }
}

@objc(RCAttributionPoster) public class AttributionPoster: NSObject {

    let deviceCache: DeviceCache
    let identityManager: IdentityManager
    let backend: Backend
    let systemInfo: SystemInfo
    let attributionFetcher: AttributionFetcher
    let subscriberAttributesManager: SubscriberAttributesManager

    private static var postponedAttributionData: [AttributionData]?

    @objc public init(deviceCache: DeviceCache,
                      identityManager: IdentityManager,
                      backend: Backend,
                      systemInfo: SystemInfo,
                      attributionFetcher: AttributionFetcher,
                      subscriberAttributesManager: SubscriberAttributesManager) {
        self.deviceCache = deviceCache
        self.identityManager = identityManager
        self.backend = backend
        self.systemInfo = systemInfo
        self.attributionFetcher = attributionFetcher
        self.subscriberAttributesManager = subscriberAttributesManager
    }

    @objc(postAttributionData:fromNetwork:forNetworkUserId:)
    public func post(attributionData data: [String: Any],
                     fromNetwork network: AttributionNetwork,
                     forNetworkUserId networkUserId: String?) {
        Logger.debug(Strings.attribution.instance_configured_posting_attribution)
        if data["rc_appsflyer_id"] != nil {
            Logger.warn(Strings.attribution.appsflyer_id_deprecated)
        }

        if network == .appsFlyer && networkUserId == nil {
            Logger.warn(Strings.attribution.networkuserid_required_for_appsflyer)
        }

        guard let appUserID = self.identityManager.maybeCurrentAppUserID else {
            Logger.error(Strings.attribution.missing_app_user_id)
            return
        }

        guard let identifierForAdvertisers = attributionFetcher.identifierForAdvertisers else {
            Logger.error(Strings.attribution.missing_advertiser_identifiers)
            return
        }

        let networkKey = String(network.rawValue)
        let dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks = deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: appUserID)
        let latestSentToNetwork = dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks[networkKey]

        // TODO: `(null)` is true to the ObjC code here, maybe we should reject this and not post?
        let newValueForNetwork = "\(identifierForAdvertisers)_\(networkUserId ?? "(null)")"
        guard latestSentToNetwork != newValueForNetwork else {
            Logger.debug(Strings.attribution.skip_same_attributes)
            return
        }

        var newDictToCache = dictOfLatestNetworkIdsAndAdvertisingIdsSentToNetworks
        newDictToCache[networkKey] = newValueForNetwork
        var newData = data

        newData["rc_idfa"] = identifierForAdvertisers
        newData["rc_idfv"] = attributionFetcher.identifierForVendor
        newData["rc_attribution_network_id"] = networkUserId

        if newData.count > 0 {
            if network == .appleSearchAds {
                backend.post(attributionData: newData, network: network, appUserID: appUserID) { maybeError in
                    guard maybeError == nil else {
                        return
                    }

                    self.deviceCache.set(latestNetworkAndAdvertisingIdsSent: newDictToCache, appUserID: appUserID)
                }
            } else {

                self.subscriberAttributesManager.convertToSubscriberAttributes(attributionData: newData,
                                                                               network: network.rawValue,
                                                                               appUserID: appUserID)
                self.deviceCache.set(latestNetworkAndAdvertisingIdsSent: newDictToCache, appUserID: appUserID)
            }
        }
    }

    @objc public func postAppleSearchAdsAttributionIfNeeded() {
        guard attributionFetcher.isAuthorizedToPostSearchAds else {
            return
        }

        guard latestNetworkIdAndAdvertisingIdentifierSent(network: .appleSearchAds) != nil else {
            return
        }

        attributionFetcher.adClientAttributionDetails { maybeAttributionDetails, maybeError in
            guard let attributionDetails = maybeAttributionDetails,
                  maybeError == nil else {
                return
            }

            let attributionDetailsValues = Array(attributionDetails.values)
            let maybeFirstAttributionDict = attributionDetailsValues.first as? [String: NSObject]

            guard let hasIad = maybeFirstAttributionDict?["iad-attribution"] as? NSNumber,
                  hasIad.boolValue == true else {
                return
            }

            self.post(attributionData: attributionDetails, fromNetwork: .appleSearchAds, forNetworkUserId: nil)
        }
    }

    @objc public func postPostponedAttributionDataIfNeeded() {
        guard let postponedAttributionData = Self.postponedAttributionData else {
            return
        }

        for attributionData in postponedAttributionData {
            post(attributionData: attributionData.data,
                 fromNetwork: attributionData.network,
                 forNetworkUserId: attributionData.networkUserId)
        }

        Self.postponedAttributionData = nil
    }

    @objc(storePostponedAttributionData:fromNetwork:forNetworkUserId:)
    public static func store(postponedAttributionData data: [String: String],
                             fromNetwork network: AttributionNetwork,
                             forNetworkUserId networkUserID: String?) {
        Logger.debug(Strings.attribution.no_instance_configured_caching_attribution)

        var postponedData = postponedAttributionData ?? []
        postponedData.append(AttributionData(data: data, network: network, networkUserId: networkUserID))
        postponedAttributionData = postponedData
    }

    private func latestNetworkIdAndAdvertisingIdentifierSent(network: AttributionNetwork) -> String? {
        guard let currentAppuserID = identityManager.maybeCurrentAppUserID else {
            return nil
        }

        let networkID = String(network.rawValue)
        let cachedDict = deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: currentAppuserID)
        return cachedDict[networkID]
    }

}
