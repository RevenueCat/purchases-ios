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

class SubscriberAttributesManager {

    private let backend: Backend
    private let deviceCache: DeviceCache
    private let attributionFetcher: AttributionFetcher
    private let attributionDataMigrator: AttributionDataMigrator
    private let lock = NSRecursiveLock()

    init(backend: Backend,
         deviceCache: DeviceCache,
         attributionFetcher: AttributionFetcher,
         attributionDataMigrator: AttributionDataMigrator) {
        self.backend = backend
        self.deviceCache = deviceCache
        self.attributionFetcher = attributionFetcher
        self.attributionDataMigrator = attributionDataMigrator
    }

    func setAttributes(_ attributes: [String: String], appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        for (key, value) in attributes {
            setAttribute(key: key, value: value, appUserID: appUserID)
        }
    }

    func setEmail(_ maybeEmail: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.email, value: maybeEmail, appUserID: appUserID)
    }

    func setPhoneNumber(_ maybePhoneNumber: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.phoneNumber, value: maybePhoneNumber, appUserID: appUserID)
    }

    func setDisplayName(_ maybeDisplayName: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.displayName, value: maybeDisplayName, appUserID: appUserID)
    }

    func setPushToken(_ maybePushToken: Data?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        let maybePushTokenString = maybePushToken?.asString
        setPushTokenString(maybePushTokenString, appUserID: appUserID)
    }

    func setPushTokenString(_ maybePushTokenString: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.pushToken, value: maybePushTokenString, appUserID: appUserID)
    }

    func setAdjustID(_ maybeAdjustID: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttributionID(networkID: maybeAdjustID,
                         networkKey: SpecialSubscriberAttributes.adjustID,
                         appUserID: appUserID)
    }

    func setAppsflyerID(_ maybeAppsflyerID: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttributionID(networkID: maybeAppsflyerID,
                         networkKey: SpecialSubscriberAttributes.appsFlyerID,
                         appUserID: appUserID)
    }

    func setFBAnonymousID(_ maybeFBAnonymousID: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttributionID(networkID: maybeFBAnonymousID,
                         networkKey: SpecialSubscriberAttributes.fBAnonID,
                         appUserID: appUserID)
    }

    func setMparticleID(_ maybeMparticleID: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttributionID(networkID: maybeMparticleID,
                         networkKey: SpecialSubscriberAttributes.mpParticleID,
                         appUserID: appUserID)
    }

    func setOnesignalID(_ maybeOnesignalID: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttributionID(networkID: maybeOnesignalID,
                         networkKey: SpecialSubscriberAttributes.oneSignalID,
                         appUserID: appUserID)
    }

    func setMediaSource(_ maybeMediaSource: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.mediaSource, value: maybeMediaSource, appUserID: appUserID)
    }

    func setCampaign(_ maybeCampaign: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.campaign, value: maybeCampaign, appUserID: appUserID)
    }

    func setAdGroup(_ maybeAdGroup: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.adGroup, value: maybeAdGroup, appUserID: appUserID)
    }

    func setAd(_ maybeAd: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.ad, value: maybeAd, appUserID: appUserID)
    }

    func setKeyword(_ maybeKeyword: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.keyword, value: maybeKeyword, appUserID: appUserID)
    }

    func setCreative(_ maybeCreative: String?, appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        setAttribute(key: SpecialSubscriberAttributes.creative, value: maybeCreative, appUserID: appUserID)
    }

    func collectDeviceIdentifiers(forAppUserID appUserID: String) {
        logAttributionMethodCalled(functionName: #function)
        let identifierForAdvertisers = attributionFetcher.identifierForAdvertisers
        let identifierForVendor = attributionFetcher.identifierForVendor

        setAttribute(key: SpecialSubscriberAttributes.idfa, value: identifierForAdvertisers, appUserID: appUserID)
        setAttribute(key: SpecialSubscriberAttributes.idfv, value: identifierForVendor, appUserID: appUserID)
        setAttribute(key: SpecialSubscriberAttributes.ip, value: "true", appUserID: appUserID)
    }

    func syncAttributesForAllUsers(currentAppUserID: String) {
        let unsyncedAttributesForAllUsers = unsyncedAttributesByKeyForAllUsers()

        for (syncingAppUserId, attributes) in unsyncedAttributesForAllUsers {
            syncAttributes(attributes: attributes, appUserID: syncingAppUserId) { error in
                self.handleAttributesSynced(syncingAppUserId: syncingAppUserId,
                                            currentAppUserId: currentAppUserID,
                                            error: error)
            }
        }
    }

    func handleAttributesSynced(syncingAppUserId: String, currentAppUserId: String, error: Error?) {
        if error == nil {
            Logger.rcSuccess(Strings.attribution.attributes_sync_success(appUserID: syncingAppUserId))
            if syncingAppUserId != currentAppUserId {
                deviceCache.deleteAttributesIfSynced(appUserID: syncingAppUserId)
            }
        } else {
            let receivedNSError = error as NSError?
            Logger.error(Strings.attribution.attributes_sync_error(details: receivedNSError?.localizedDescription,
                                                                   userInfo: receivedNSError?.userInfo))
        }
    }

    func unsyncedAttributesByKey(appUserID: String) -> SubscriberAttributeDict {
        let unsyncedAttributes = deviceCache.unsyncedAttributesByKey(appUserID: appUserID)
        Logger.debug(Strings.attribution.unsynced_attributes_count(unsyncedAttributesCount: unsyncedAttributes.count,
                                                                   appUserID: appUserID))
        if !unsyncedAttributes.isEmpty {
            Logger.debug(Strings.attribution.unsynced_attributes(unsyncedAttributes: unsyncedAttributes))
        }

        return unsyncedAttributes
    }

    func unsyncedAttributesByKeyForAllUsers() -> [String: SubscriberAttributeDict] {
        return deviceCache.unsyncedAttributesForAllUsers()
    }

    func markAttributesAsSynced(_ maybeAttributesToSync: SubscriberAttributeDict?, appUserID: String) {
        guard let attributesToSync = maybeAttributesToSync,
              !attributesToSync.isEmpty else {
            return
        }

        Logger.info(Strings.attribution.marking_attributes_synced(appUserID: appUserID, attributes: attributesToSync))

        lock.lock()
        var unsyncedAttributes = unsyncedAttributesByKey(appUserID: appUserID)
        for (key, attribute) in attributesToSync {
            if let unsyncedAttribute = unsyncedAttributes[key] {
                if unsyncedAttribute.value == attribute.value {
                    unsyncedAttribute.isSynced = true
                    unsyncedAttributes[key] = unsyncedAttribute
                }
            }
        }
        deviceCache.store(subscriberAttributesByKey: unsyncedAttributes, appUserID: appUserID)
        lock.unlock()
    }

    func setAttributes(fromAttributionData attributionData: [String: Any],
                       network: AttributionNetwork,
                       appUserID: String) {
        let convertedAttribution = attributionDataMigrator.convertToSubscriberAttributes(
            attributionData: attributionData,
            network: network.rawValue)
        setAttributes(convertedAttribution, appUserID: appUserID)
    }
}

private extension SubscriberAttributesManager {

    func storeAttributeLocallyIfNeeded(key: String, value: String?, appUserID: String) {
        let currentValue = currentValueForAttribute(key: key, appUserID: appUserID)
        if currentValue == nil || currentValue != (value ?? "") {
            storeAttributeLocally(key: key, value: value ?? "", appUserID: appUserID)
        }
    }

    func setAttribute(key: String, value: String?, appUserID: String) {
        storeAttributeLocallyIfNeeded(key: key, value: value, appUserID: appUserID)
    }

    func syncAttributes(attributes: SubscriberAttributeDict,
                        appUserID: String,
                        completion: @escaping (Error?) -> Void) {
        backend.post(subscriberAttributes: attributes, appUserID: appUserID) { error in
            let receivedNSError = error as NSError?
            let didBackendReceiveValues = receivedNSError?.successfullySynced ?? true

            if didBackendReceiveValues {
                self.markAttributesAsSynced(attributes, appUserID: appUserID)
            }
            completion(error)
        }
    }

    func storeAttributeLocally(key: String, value: String, appUserID: String) {
        let subscriberAttribute = SubscriberAttribute(withKey: key, value: value)
        Logger.debug(Strings.attribution.attribute_set_locally(attribute: subscriberAttribute.description))
        deviceCache.store(subscriberAttribute: subscriberAttribute, appUserID: appUserID)
    }

    func currentValueForAttribute(key: String, appUserID: String) -> String? {
        let maybeAttribute = deviceCache.subscriberAttribute(attributeKey: key, appUserID: appUserID)
        return maybeAttribute?.value
    }

    func setAttributionID(networkID: String?, networkKey: String, appUserID: String) {
        collectDeviceIdentifiers(forAppUserID: appUserID)
        setAttribute(key: networkKey, value: networkID, appUserID: appUserID)
    }

    func logAttributionMethodCalled(functionName: String) {
        Logger.debug(Strings.attribution.method_called(methodName: functionName))
    }

}
