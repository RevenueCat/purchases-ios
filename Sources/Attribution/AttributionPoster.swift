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

final class AttributionPoster {

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
        guard let newDictToCache = self.getNewDictToCache(currentAppUserID: currentAppUserID,
                                                          idfa: identifierForAdvertisers,
                                                          network: network,
                                                          networkUserId: networkUserId) else {
            return
        }

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
            if network.isAppleSearchAdds {
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

    @available(*, deprecated)
    func postAppleSearchAdsAttributionIfNeeded() {
        guard attributionFetcher.isAuthorizedToPostSearchAds else {
            return
        }

        guard self.latestNetworkIdAndAdvertisingIdentifierSent(network: .appleSearchAds) == nil else {
            return
        }

        attributionFetcher.afficheClientAttributionDetails { attributionDetails, error in
            guard let attributionDetails = attributionDetails,
                  error == nil else {
                return
            }

            let attributionDetailsValues = attributionDetails.values
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
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func postAdServicesTokenIfNeeded() {
        guard latestNetworkIdAndAdvertisingIdentifierSent(network: .adServices) == nil else {
            return
        }

        guard let attributionToken = attributionFetcher.adServicesToken else {
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

    private func post(adServicesToken: String) {
        let currentAppUserID = self.currentUserProvider.currentAppUserID

        // set the cache in advance to avoid multiple post calls
        var newDictToCache = self.deviceCache.latestAdvertisingIdsByNetworkSent(appUserID: currentAppUserID)
        newDictToCache[AttributionNetwork.adServices] = adServicesToken
        self.deviceCache.set(latestAdvertisingIdsByNetworkSent: newDictToCache, appUserID: currentAppUserID)

         backend.post(adServicesToken: adServicesToken, appUserID: currentAppUserID) { error in
             guard let error = error else {
                 Logger.debug(Strings.attribution.adservices_token_post_succeeded)
                 return
             }
             Logger.warn(Strings.attribution.adservices_token_post_failed(error: error))

            // if there's an error, reset the cache
            newDictToCache[AttributionNetwork.adServices] = nil
            self.deviceCache.set(latestAdvertisingIdsByNetworkSent: newDictToCache, appUserID: currentAppUserID)
        }
    }

    private func latestNetworkIdAndAdvertisingIdentifierSent(network: AttributionNetwork) -> String? {
        let cachedDict = deviceCache.latestAdvertisingIdsByNetworkSent(
            appUserID: self.currentUserProvider.currentAppUserID
        )
        return cachedDict[network]
    }

    private func postSearchAds(newData: [String: Any],
                               network: AttributionNetwork,
                               appUserID: String,
                               newDictToCache: [AttributionNetwork: String]) {
        backend.post(attributionData: newData, network: network, appUserID: appUserID) { error in
            guard error == nil else {
                return
            }

            self.deviceCache.set(latestAdvertisingIdsByNetworkSent: newDictToCache, appUserID: appUserID)
        }
    }

    private func postSubscriberAttributes(newData: [String: Any],
                                          network: AttributionNetwork,
                                          appUserID: String,
                                          newDictToCache: [AttributionNetwork: String]) {
        subscriberAttributesManager.setAttributes(fromAttributionData: newData,
                                                  network: network,
                                                  appUserID: appUserID)
        deviceCache.set(latestAdvertisingIdsByNetworkSent: newDictToCache, appUserID: appUserID)
    }

    private func getNewDictToCache(currentAppUserID: String,
                                   idfa: String?,
                                   network: AttributionNetwork,
                                   networkUserId: String?) -> [AttributionNetwork: String]? {
        let latestAdvertisingIdsByNetworkSent =
            deviceCache.latestAdvertisingIdsByNetworkSent(appUserID: currentAppUserID)
        let latestSentToNetwork = latestAdvertisingIdsByNetworkSent[network]

        let newValueForNetwork = "\(idfa ?? "(null)")_\(networkUserId ?? "(null)")"
        guard latestSentToNetwork != newValueForNetwork else {
            Logger.debug(Strings.attribution.skip_same_attributes)
            return nil
        }

        var newDictToCache = latestAdvertisingIdsByNetworkSent
        newDictToCache[network] = newValueForNetwork
        return newDictToCache
    }

}

extension AttributionPoster: Sendable {}
