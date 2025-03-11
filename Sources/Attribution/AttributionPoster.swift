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
    private let systemInfo: SystemInfo

    private static var postponedAttributionData: [AttributionData]?

    init(deviceCache: DeviceCache,
         currentUserProvider: CurrentUserProvider,
         backend: Backend,
         attributionFetcher: AttributionFetcher,
         subscriberAttributesManager: SubscriberAttributesManager,
         systemInfo: SystemInfo) {
        self.deviceCache = deviceCache
        self.currentUserProvider = currentUserProvider
        self.backend = backend
        self.attributionFetcher = attributionFetcher
        self.subscriberAttributesManager = subscriberAttributesManager
        self.systemInfo = systemInfo
    }

    func post(attributionData data: [String: Any],
              fromNetwork network: AttributionNetwork,
              networkUserId: String?) {
        guard !self.systemInfo.dangerousSettings.uiPreviewMode else {
            return
        }

        Logger.debug(Strings.attribution.instance_configured_posting_attribution)
        if data[AttributionKey.AppsFlyer.id.rawValue] != nil {
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
            newData[AttributionKey.idfa.rawValue] = identifierForAdvertisers
        } else {
            newData.removeValue(forKey: AttributionKey.idfa.rawValue)
        }

        if let identifierForVendor = attributionFetcher.identifierForVendor {
            newData[AttributionKey.idfv.rawValue] = identifierForVendor
        } else {
            newData.removeValue(forKey: AttributionKey.idfv.rawValue)
        }

        if let networkUserId = networkUserId {
            newData[AttributionKey.networkID.rawValue] = networkUserId
        } else {
            newData.removeValue(forKey: AttributionKey.networkID.rawValue)
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

    // should match OS availability in https://developer.apple.com/documentation/ad_services
    @available(iOS 14.3, tvOS 14.3, watchOS 6.2, macOS 11.1, macCatalyst 14.3, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func postAdServicesTokenOncePerInstallIfNeeded(completion: ((Error?) -> Void)? = nil) {
        Task.detached(priority: .background) {
            guard let attributionToken = await self.adServicesTokenToPostIfNeeded else {
                completion?(nil)
                return
            }

            self.post(adServicesToken: attributionToken, completion: completion)
        }
    }

    var adServicesTokenToPostIfNeeded: String? {
        get async {
            #if os(tvOS) || os(watchOS)
            return nil
            #else
            guard #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) else {
                return nil
            }

            guard self.latestNetworkIdAndAdvertisingIdentifierSent(network: .adServices) == nil else {
                return nil
            }

            return await self.attributionFetcher.adServicesToken
            #endif
        }
    }

    @discardableResult
    func markAdServicesToken(_ token: String, asSyncedFor userID: String) -> [AttributionNetwork: String] {
        Logger.info(Strings.attribution.adservices_marking_as_synced(appUserID: userID))

        var newDictToCache = self.deviceCache.latestAdvertisingIdsByNetworkSent(appUserID: userID)
        newDictToCache[AttributionNetwork.adServices] = token

        self.deviceCache.set(latestAdvertisingIdsByNetworkSent: newDictToCache, appUserID: userID)

        return newDictToCache
    }

    func postPostponedAttributionDataIfNeeded() {
        if let postponedAttributionData = Self.postponedAttributionData,
           !systemInfo.dangerousSettings.uiPreviewMode {

            for attributionData in postponedAttributionData {
                post(attributionData: attributionData.data,
                     fromNetwork: attributionData.network,
                     networkUserId: attributionData.networkUserId)
            }
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

    private func post(adServicesToken: String, completion: ((Error?) -> Void)? = nil) {
        let currentAppUserID = self.currentUserProvider.currentAppUserID

        // set the cache in advance to avoid multiple post calls
        var newDictToCache = self.markAdServicesToken(adServicesToken, asSyncedFor: currentAppUserID)

        self.backend.post(adServicesToken: adServicesToken, appUserID: currentAppUserID) { error in
             guard let error = error else {
                 Logger.debug(Strings.attribution.adservices_token_post_succeeded)
                 completion?(nil)
                 return
             }
             Logger.warn(Strings.attribution.adservices_token_post_failed(error: error))

            // if there's an error, reset the cache
            newDictToCache[AttributionNetwork.adServices] = nil
            self.deviceCache.set(latestAdvertisingIdsByNetworkSent: newDictToCache, appUserID: currentAppUserID)

            completion?(error)
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
