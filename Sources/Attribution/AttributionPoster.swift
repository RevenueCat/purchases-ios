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
            postSubscriberAttributes(newData: newData,
                                     network: network,
                                     appUserID: currentAppUserID,
                                     newDictToCache: newDictToCache)
        }
    }

    // should match OS availability in https://developer.apple.com/documentation/ad_services
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func postAdServicesTokenIfNeeded() {
        let latestTokenSent = latestNetworkIdAndAdvertisingIdentifierSent(network: .adServices)
        guard latestTokenSent == nil else {
            return
        }

        guard let attributionToken = attributionFetcher.adServicesToken else {
            return
        }

        Logger.debug("Logging attribution token for now to avoid lint warning: \(attributionToken)")
        // post
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
