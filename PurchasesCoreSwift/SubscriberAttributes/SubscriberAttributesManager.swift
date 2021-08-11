//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributesManager.swift
//
//  Created by Madeline Beyl on 8/10/21.

import Foundation

// TODO after migration make class and all methods internal
@objc(RCSubscriberAttributesManager) public class SubscriberAttributesManager: NSObject {

    private let backend: Backend
    private let deviceCache: DeviceCache
    private let attributionFetcher: AttributionFetcher
    private let attributionDataMigrator: AttributionDataMigrator

    @objc public init(backend: Backend,
                      deviceCache: DeviceCache,
                      attributionFetcher: AttributionFetcher,
                      attributionDataMigrator: AttributionDataMigrator) {
        self.backend = backend
        self.deviceCache = deviceCache
        self.attributionFetcher = attributionFetcher
        self.attributionDataMigrator = attributionDataMigrator
    }

    @objc public func setAttributes(attributes: [String: String], appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setAttributes"))
        for (key, value) in attributes {
            setAttribute(key: key, value: value, appUserId: appUserId)
        }
    }

    @objc public func setEmail(_ maybeEmail: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setEmail"))
        setAttribute(key: SpecialSubscriberAttributes.email, value: maybeEmail, appUserId: appUserId)
    }

    @objc public func setPhoneNumber(_ maybePhoneNumber: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setPhoneNumber"))
        setAttribute(key: SpecialSubscriberAttributes.phoneNumber, value: maybePhoneNumber, appUserId: appUserId)
    }

    @objc public func setDisplayName(_ maybeDisplayName: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setDisplayName"))
        setAttribute(key: SpecialSubscriberAttributes.displayName, value: maybeDisplayName, appUserId: appUserId)
    }

    @objc public func setPushToken(_ maybePushToken: Data?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setPushToken"))
        let maybePushTokenString = maybePushToken?.rc_asString
        setPushTokenString(maybePushTokenString, appUserId: appUserId)
    }

    @objc public func setPushTokenString(_ maybePushTokenString: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setPushTokenString"))
        setAttribute(key: SpecialSubscriberAttributes.pushToken, value: maybePushTokenString, appUserId: appUserId)
    }

    @objc public func setAdjustId(_ maybeAdjustId: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setAdjustId"))
        setAttribute(key: SpecialSubscriberAttributes.adjustID, value: maybeAdjustId, appUserId: appUserId)
    }

    @objc public func setAppsflyerId(_ maybeAppsflyerId: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setAppsflyerId"))
        setAttribute(key: SpecialSubscriberAttributes.appsFlyerID, value: maybeAppsflyerId, appUserId: appUserId)
    }

    @objc public func setFBAnonymousID(_ maybeFBAnonymousID: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setFBAnonymousID"))
        setAttribute(key: SpecialSubscriberAttributes.fBAnonID, value: maybeFBAnonymousID, appUserId: appUserId)
    }

    @objc public func setMparticleID(_ maybeMparticleID: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setMparticleID"))
        setAttribute(key: SpecialSubscriberAttributes.mpParticleID, value: maybeMparticleID, appUserId: appUserId)
    }

    @objc public func setOnesignalID(_ maybeOnesignalID: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setOnesignalID"))
        setAttribute(key: SpecialSubscriberAttributes.oneSignalID, value: maybeOnesignalID, appUserId: appUserId)
    }

    @objc public func setMediaSource(_ maybeMediaSource: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setMediaSource"))
        setAttribute(key: SpecialSubscriberAttributes.mediaSource, value: maybeMediaSource, appUserId: appUserId)
    }

    @objc public func setCampaign(_ maybeCampaign: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setCampaign"))
        setAttribute(key: SpecialSubscriberAttributes.campaign, value: maybeCampaign, appUserId: appUserId)
    }

    @objc public func setAdGroup(_ maybeAdGroup: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setAdGroup"))
        setAttribute(key: SpecialSubscriberAttributes.adGroup, value: maybeAdGroup, appUserId: appUserId)
    }

    @objc public func setAd(_ maybeAd: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setAd"))
        setAttribute(key: SpecialSubscriberAttributes.ad, value: maybeAd, appUserId: appUserId)
    }

    @objc public func setKeyword(_ maybeKeyword: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setKeyword"))
        setAttribute(key: SpecialSubscriberAttributes.keyword, value: maybeKeyword, appUserId: appUserId)
    }

    @objc public func setCreative(_ maybeCreative: String?, appUserId: String) {
        Logger.debug(String(format: Strings.attribution.method_called, "setCreative"))
        setAttribute(key: SpecialSubscriberAttributes.creative, value: maybeCreative, appUserId: appUserId)
    }

    @objc public func collectDeviceIdentifiersForAppUserID(appUserId: String) {
        Logger.debug("collectDeviceIdentifiers called");
        Logger.debug(String(format: Strings.attribution.method_called, "setAttributes"))
        let identifierForAdvertisers = attributionFetcher.identifierForAdvertisers
        let identifierForVendor = attributionFetcher.identifierForAdvertisers

        setAttribute(key: SpecialSubscriberAttributes.idfa, value: identifierForAdvertisers, appUserId: appUserId)
        setAttribute(key: SpecialSubscriberAttributes.idfv, value: identifierForVendor, appUserId: appUserId)
        setAttribute(key: SpecialSubscriberAttributes.ip, value: "true", appUserId: appUserId)
    }

    @objc public func syncAttributesForAllUsers(currentAppUserId: String) {
        let unsyncedAttributesForAllUsers = unsyncedAttributesByKeyForAllUsers()

        for (syncingAppUserId, attributes) in unsyncedAttributesForAllUsers {
            syncAttributes(attributes: attributes, appUserId: syncingAppUserId) { error  in
                self.handleAttributesSynced(syncingAppUserId: syncingAppUserId, currentAppUserId: currentAppUserId, error: error)
            }
        }
    }

    @objc public func handleAttributesSynced(syncingAppUserId: String, currentAppUserId: String, error: Error?) {
        if (error == nil) {
            Logger.rcSuccess(String(format: Strings.attribution.attributes_sync_success, syncingAppUserId))
            if (syncingAppUserId != currentAppUserId) {
                deviceCache.deleteAttributesIfSynced(appUserID: syncingAppUserId)
            }
        } else {
            // TODO how to get error.userinfo
            Logger.error(String(format: Strings.attribution.attributes_sync_error, error?.localizedDescription ?? ""))
        }
    }

    @objc public func unsyncedAttributesByKey(appUserId: String) -> SubscriberAttributeDict {
        return deviceCache.unsyncedAttributesByKey(appUserID: appUserId)
    }

    @objc public func unsyncedAttributesByKeyForAllUsers() -> [String: SubscriberAttributeDict] {
        return deviceCache.unsyncedAttributesForAllUsers()
    }

    private func setAttribute(key: String, value: String?, appUserId: String) {
        storeAttributeLocallyIfNeeded(key: key, value: value, appUserId: appUserId)
    }

    // TODO confirm whether i want escaping here
    private func syncAttributes(attributes: SubscriberAttributeDict, appUserId: String, completion: @escaping (Error?) -> Void) {
        backend.post(subscriberAttributes: attributes, appUserID: appUserId) { error in
            // TODO confirm this as is correct
            let receivedNSError = error as NSError?
            let didBackendReceiveValues = receivedNSError?.rc_successfullySynced ?? true

            if (didBackendReceiveValues) {
                self.markAttributesAsSynced(attributes: attributes, appUserId: appUserId)
            }
            completion(error)
        }
    }

    private func markAttributesAsSynced(attributes maybeAttributesToSync: SubscriberAttributeDict?, appUserId: String) {
        // TODO use guard?
        guard let attributesToSync = maybeAttributesToSync,
              !attributesToSync.isEmpty else {
            return
        }

        Logger.info(String(format: Strings.attribution.marking_attributes_synced,
                           appUserId,
                           attributesToSync.description))

        // TODO synchronized self
        var unsyncedAttributes = unsyncedAttributesByKey(appUserId: appUserId)
        for (key, attribute) in attributesToSync {
            if let unsyncedAttribute = unsyncedAttributes[key] {
                if (unsyncedAttribute == attribute) {
                    unsyncedAttribute.isSynced = true
                    unsyncedAttributes[key] = unsyncedAttribute
                }
            }
        }
        deviceCache.store(subscriberAttributesByKey: unsyncedAttributes, appUserID: appUserId)
    }

    private func storeAttributeLocallyIfNeeded(key: String, value: String?, appUserId: String) {
        // TODO clean up logic
        guard let currentValue = currentValueForAttribute(key: key, appUserId: appUserId) else {
            storeAttributeLocally(key: key, value: "", appUserId: appUserId)
            return
        }

        if (currentValue != value) {
            storeAttributeLocally(key: key, value: currentValue, appUserId: appUserId)
        }
    }

    private func storeAttributeLocally(key: String, value: String, appUserId: String) {
        let subscriberAttribute = SubscriberAttribute.init(withKey: key, value: value)
        deviceCache.store(subscriberAttribute: subscriberAttribute, appUserID: appUserId)
    }

    private func currentValueForAttribute(key: String, appUserId: String) -> String? {
        let maybeAttribute = deviceCache.subscriberAttribute(attributeKey: key, appUserID: appUserId)
        return maybeAttribute?.value
    }

    private func setAttributionID(networkID: String?, networkKey: String, appUserId: String) {
        collectDeviceIdentifiersForAppUserID(appUserId: appUserId)
        setAttribute(key: networkKey, value: networkID, appUserId: appUserId)
    }

    private func convertAttributionDataAndSetAsSubscriberAttributes(attributionData: [String: Any],
                                                                    network: AttributionNetwork,
                                                                    appUserId: String) {
        let convertedAttribution =
            attributionDataMigrator.convertToSubscriberAttributes(attributionData: attributionData,
        network: network.rawValue)
        setAttributes(attributes: convertedAttribution, appUserId: appUserId)
    }

}
