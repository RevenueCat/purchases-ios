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

    private let deviceCache: DeviceCache
    private let currentUserProvider: CurrentUserProvider
    private let backend: Backend
    private let attributionFetcher: AttributionFetcher
    private let subscriberAttributesManager: SubscriberAttributesManager

    private static var postponedAttributionData: [AttributionData]?

    init(deviceCache: DeviceCache,
         currentUserProvider: CurrentUserProvider,
         backend: Backend,
         attributionFetcher: AttributionFetcher,
         subscriberAttributesManager: SubscriberAttributesManager) {
        self.deviceCache = deviceCache
        self.currentUserProvider = currentUserProvider
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

        let identifierForAdvertisers = attributionFetcher.identifierForAdvertisers
        if identifierForAdvertisers == nil {
            Logger.warn(Strings.attribution.missing_advertiser_identifiers)
        }

        let currentAppUserID = self.currentUserProvider.currentAppUserID
        let networkKey = String(network.rawValue)
        let latestNetworkIdsAndAdvertisingIdsSentByNetwork =
            deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
        let latestSentToNetwork = latestNetworkIdsAndAdvertisingIdsSentByNetwork[networkKey]

        let newValueForNetwork = "\(identifierForAdvertisers ?? "(null)")_\(networkUserId ?? "(null)")"
        guard latestSentToNetwork != newValueForNetwork else {
            Logger.debug(Strings.attribution.skip_same_attributes)
            return
        }

        var newDictToCache = latestNetworkIdsAndAdvertisingIdsSentByNetwork
        newDictToCache[networkKey] = newValueForNetwork
//        guard let newDictToCache = getNewDictToCache(currentAppUserID: currentAppUserID,
//                                               network: network,
//                                               networkUserId: networkUserId,
//                                                     identifierForAdvertisers: identifierForAdvertisers) else {
//            
//        }

        var newData = data

        if let identifierForAdvertisers = identifierForAdvertisers {
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

    // note to maddie -- tried pulling this out for re-use, but subattrs handles
    // latestSentToNetwork == newValueForNetwork differently than what we want for adservices.
    // this is techncially OK from a functionality standpoint, because we already skip fetching
    // a new token if previous != nil, so it shouldn't get to this point. but need to somehow
    // pull the subattrs-specific log out of here
//    func getNewDictToCache(currentAppUserID: String,
//                           network: AttributionNetwork,
//                           networkUserId: String?,
//                           identifierForAdvertisers: String?) -> [String: String]? {
//        let networkKey = String(network.rawValue)
//        let latestNetworkIdsAndAdvertisingIdsSentByNetwork =
//            deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
//        let latestSentToNetwork = latestNetworkIdsAndAdvertisingIdsSentByNetwork[networkKey]
//
//        let newValueForNetwork = "\(identifierForAdvertisers ?? "(null)")_\(networkUserId ?? "(null)")"
//        guard latestSentToNetwork != newValueForNetwork else {
//            Logger.debug(Strings.attribution.skip_same_attributes)
//            return nil
//        }
//
//        var newDictToCache = latestNetworkIdsAndAdvertisingIdsSentByNetwork
//        newDictToCache[networkKey] = newValueForNetwork
//        return newDictToCache
//    }

    func post(adServicesToken: String) {
        let currentAppUserID = self.currentUserProvider.currentAppUserID
        backend.post(adServicesToken: adServicesToken, appUserID: currentAppUserID) { error in
            guard error == nil else {
                return
            }

//            let newDictToCache = getNewDictToCache(currentAppUserID: currentAppUserID,
//                                                   network: .adServices,
//                                                   networkUserId: nil,
//                                                   identifierForAdvertisers: nil)

            let latestNetworkIdsAndAdvertisingIdsSentByNetwork =
                self.deviceCache.latestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)
            var newDictToCache = latestNetworkIdsAndAdvertisingIdsSentByNetwork
            newDictToCache[String(AttributionNetwork.adServices.rawValue)] = adServicesToken

            self.deviceCache.set(latestNetworkAndAdvertisingIdsSent: newDictToCache, appUserID: currentAppUserID)
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

        attributionFetcher.afficheClientAttributionDetails { attributionDetails, error in
            guard let attributionDetails = attributionDetails,
                  error == nil else {
                return
            }

            let attributionDetailsValues = Array(attributionDetails.values)
            let firstAttributionDict = attributionDetailsValues.first as? [String: NSObject]

            guard let hasIad = firstAttributionDict?["iad-attribution"] as? NSNumber,
                  hasIad.boolValue == true else {
                return
            }

            self.post(attributionData: attributionDetails, fromNetwork: .appleSearchAds, networkUserId: nil)
        }
    }

    // should match OS availability in https://developer.apple.com/documentation/ad_services
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func postAdServicesTokenIfNeeded() {
        let latestTokenSent = latestNetworkIdAndAdvertisingIdentifierSent(network: .adServices)
        guard latestTokenSent == nil else {
            return
        }

        guard let attributionToken = attributionFetcher.adServicesToken() else {
            return
        }

        self.post(adServicesToken: attributionToken)
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
        let cachedDict = deviceCache.latestNetworkAndAdvertisingIdsSent(
            appUserID: self.currentUserProvider.currentAppUserID
        )
        return cachedDict[networkID]
}

    private func postSearchAds(newData: [String: Any],
                               network: AttributionNetwork,
                               appUserID: String,
                               newDictToCache: [String: String]) {
        backend.post(attributionData: newData, network: network, appUserID: appUserID) { error in
            guard error == nil else {
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
