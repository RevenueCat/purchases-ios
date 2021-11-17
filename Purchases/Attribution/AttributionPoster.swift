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

class AttributionPoster {

    let deviceCache: DeviceCache
    let identityManager: IdentityManager
    let backend: Backend
    let attributionFetcher: AttributionFetcher
    let subscriberAttributesManager: SubscriberAttributesManager

    private static var postponedAttributionData: [AttributionData]?

    init(deviceCache: DeviceCache,
         identityManager: IdentityManager,
         backend: Backend,
         attributionFetcher: AttributionFetcher,
         subscriberAttributesManager: SubscriberAttributesManager) {
        self.deviceCache = deviceCache
        self.identityManager = identityManager
        self.backend = backend
        self.attributionFetcher = attributionFetcher
        self.subscriberAttributesManager = subscriberAttributesManager
    }

    // swiftlint:disable:next function_body_length
    func post(attributionData data: [String: Any],
              fromNetwork network: AttributionNetwork,
              networkUserId: String?) {
        Logger.debug(Strings.attribution.instance_configured_posting_attribution)
        if data["rc_appsflyer_id"] != nil {
            Logger.warn(Strings.attribution.appsflyer_id_deprecated)
        }

        if network == .appsFlyer && networkUserId == nil {
            Logger.warn(Strings.attribution.networkuserid_required_for_appsflyer)
        }

        let maybeIdentifierForAdvertisers = attributionFetcher.identifierForAdvertisers
        if maybeIdentifierForAdvertisers == nil {
            Logger.warn(Strings.attribution.missing_advertiser_identifiers)
        }

        let currentAppUserID = identityManager.currentAppUserID
        let networkKey = String(network.rawValue)
        let latestNetworkIdsAndAdvertisingIdsSentByNetwork =
            deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
        let latestSentToNetwork = latestNetworkIdsAndAdvertisingIdsSentByNetwork[networkKey]

        let newValueForNetwork = "\(maybeIdentifierForAdvertisers ?? "(null)")_\(networkUserId ?? "(null)")"
        guard latestSentToNetwork != newValueForNetwork else {
            Logger.debug(Strings.attribution.skip_same_attributes)
            return
        }

        var newDictToCache = latestNetworkIdsAndAdvertisingIdsSentByNetwork
        newDictToCache[networkKey] = newValueForNetwork
        var newData = data

        if let identifierForAdvertisers = maybeIdentifierForAdvertisers {
            newData["rc_idfa"] = identifierForAdvertisers
        } else {
            newData.removeValue(forKey: "rc_idfa")
        }

        if let identifierForVendor = attributionFetcher.identifierForVendor {
            newData["rc_idfv"] = identifierForVendor
        } else {
            newData.removeValue(forKey: "rc_idfv")
        }

        if let networkUserId = networkUserId {
            newData["rc_attribution_network_id"] = networkUserId
        } else {
            newData.removeValue(forKey: "rc_attribution_network_id")
        }

        if !newData.isEmpty {
            if network == .appleSearchAds {
                postSearchAds(newData: newData,
                              network: network,
                              appUserID: currentAppUserID,
                              newDictToCache: newDictToCache)
            } else {
                postSubscriberAttributes(newData: newData,
                                         network: network,
                                         appUserID: currentAppUserID,
                                         newDictToCache: newDictToCache)
            }
        }
    }

    func postAppleSearchAdsAttributionIfNeeded() {
        guard attributionFetcher.isAuthorizedToPostSearchAds else {
            return
        }

        let latestIdsSent = latestNetworkIdAndAdvertisingIdentifierSent(network: .appleSearchAds)
        guard latestIdsSent == nil else {
            return
        }

        attributionFetcher.afficheClientAttributionDetails { maybeAttributionDetails, maybeError in
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

            self.post(attributionData: attributionDetails, fromNetwork: .appleSearchAds, networkUserId: nil)
        }
    }

    func postPostponedAttributionDataIfNeeded() {
        guard let postponedAttributionData = Self.postponedAttributionData else {
            return
        }

        for attributionData in postponedAttributionData {
            post(attributionData: attributionData.data,
                 fromNetwork: attributionData.network,
                 networkUserId: attributionData.networkUserId)
        }

        Self.postponedAttributionData = nil
    }

    static func store(postponedAttributionData data: [String: Any],
                      fromNetwork network: AttributionNetwork,
                      forNetworkUserId networkUserID: String?) {
        Logger.debug(Strings.attribution.no_instance_configured_caching_attribution)

        var postponedData = postponedAttributionData ?? []
        postponedData.append(AttributionData(data: data, network: network, networkUserId: networkUserID))
        postponedAttributionData = postponedData
    }

    private func latestNetworkIdAndAdvertisingIdentifierSent(network: AttributionNetwork) -> String? {
        let networkID = String(network.rawValue)
        let cachedDict = deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: identityManager.currentAppUserID)
        return cachedDict[networkID]
    }

    private func postSearchAds(newData: [String: Any],
                               network: AttributionNetwork,
                               appUserID: String,
                               newDictToCache: [String: String]) {
        backend.post(attributionData: newData, network: network, appUserID: appUserID) { maybeError in
            guard maybeError == nil else {
                return
            }

            self.deviceCache.set(latestNetworkAndAdvertisingIdsSent: newDictToCache, appUserID: appUserID)
        }
    }

    private func postSubscriberAttributes(newData: [String: Any],
                                          network: AttributionNetwork,
                                          appUserID: String,
                                          newDictToCache: [String: String]) {
        subscriberAttributesManager.setAttributes(fromAttributionData: newData,
                                                  network: network,
                                                  appUserID: appUserID)
        deviceCache.set(latestNetworkAndAdvertisingIdsSent: newDictToCache, appUserID: appUserID)
    }

}
