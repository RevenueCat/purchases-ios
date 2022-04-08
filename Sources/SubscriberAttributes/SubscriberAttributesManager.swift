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
    private let operationDispatcher: OperationDispatcher
    private let attributionFetcher: AttributionFetcher
    private let attributionDataMigrator: AttributionDataMigrator
    private let lock = Lock()

    init(backend: Backend,
         deviceCache: DeviceCache,
         operationDispatcher: OperationDispatcher,
         attributionFetcher: AttributionFetcher,
         attributionDataMigrator: AttributionDataMigrator) {
        self.backend = backend
        self.deviceCache = deviceCache
        self.operationDispatcher = operationDispatcher
        self.attributionFetcher = attributionFetcher
        self.attributionDataMigrator = attributionDataMigrator
    }

    func setAttributes(_ attributes: [String: String], appUserID: String) {
        Logger.debug(Strings.attribution.setting_attributes(attributes: Array(attributes.keys)))
        for (key, value) in attributes {
            setAttribute(key: key, value: value, appUserID: appUserID)
        }
    }

    func setEmail(_ email: String?, appUserID: String) {
        setReservedAttribute(.email, value: email, appUserID: appUserID)
    }

    func setPhoneNumber(_ phoneNumber: String?, appUserID: String) {
        setReservedAttribute(.phoneNumber, value: phoneNumber, appUserID: appUserID)
    }

    func setDisplayName(_ displayName: String?, appUserID: String) {
        setReservedAttribute(.displayName, value: displayName, appUserID: appUserID)
    }

    func setPushToken(_ pushToken: Data?, appUserID: String) {
        let pushTokenString = pushToken?.asString
        setPushTokenString(pushTokenString, appUserID: appUserID)
    }

    func setPushTokenString(_ pushTokenString: String?, appUserID: String) {
        setReservedAttribute(.pushToken, value: pushTokenString, appUserID: appUserID)
    }

    func setAdjustID(_ adjustID: String?, appUserID: String) {
        setAttributionID(adjustID, forNetworkID: .adjustID, appUserID: appUserID)
    }

    func setAppsflyerID(_ appsflyerID: String?, appUserID: String) {
        setAttributionID(appsflyerID, forNetworkID: .appsFlyerID, appUserID: appUserID)
    }

    func setFBAnonymousID(_ fBAnonymousID: String?, appUserID: String) {
        setAttributionID(fBAnonymousID, forNetworkID: .fBAnonID, appUserID: appUserID)
    }

    func setMparticleID(_ mparticleID: String?, appUserID: String) {
        setAttributionID(mparticleID, forNetworkID: .mpParticleID, appUserID: appUserID)
    }

    func setOnesignalID(_ onesignalID: String?, appUserID: String) {
        setAttributionID(onesignalID, forNetworkID: .oneSignalID, appUserID: appUserID)
    }

    func setAirshipChannelID(_ airshipChannelID: String?, appUserID: String) {
        setAttributionID(airshipChannelID, forNetworkID: .airshipChannelID, appUserID: appUserID)
    }

    func setCleverTapID(_ cleverTapID: String?, appUserID: String) {
        setAttributionID(cleverTapID, forNetworkID: .cleverTapID, appUserID: appUserID)
    }

    func setMixpanelDistinctID(_ mixpanelDistinctID: String?, appUserID: String) {
        setReservedAttribute(.mixpanelDistinctID, value: mixpanelDistinctID, appUserID: appUserID)
    }

    func setMediaSource(_ mediaSource: String?, appUserID: String) {
        setReservedAttribute(.mediaSource, value: mediaSource, appUserID: appUserID)
    }

    func setCampaign(_ campaign: String?, appUserID: String) {
        setReservedAttribute(.campaign, value: campaign, appUserID: appUserID)
    }

    func setAdGroup(_ adGroup: String?, appUserID: String) {
        setReservedAttribute(.adGroup, value: adGroup, appUserID: appUserID)
    }

    // swiftlint:disable:next identifier_name
    func setAd(_ ad: String?, appUserID: String) {
        setReservedAttribute(.ad, value: ad, appUserID: appUserID)
    }

    func setKeyword(_ keyword: String?, appUserID: String) {
        setReservedAttribute(.keyword, value: keyword, appUserID: appUserID)
    }

    func setCreative(_ creative: String?, appUserID: String) {
        setReservedAttribute(.creative, value: creative, appUserID: appUserID)
    }

    func collectDeviceIdentifiers(forAppUserID appUserID: String) {
        let identifierForAdvertisers = attributionFetcher.identifierForAdvertisers
        let identifierForVendor = attributionFetcher.identifierForVendor

        setReservedAttribute(.idfa, value: identifierForAdvertisers, appUserID: appUserID)
        setReservedAttribute(.idfv, value: identifierForVendor, appUserID: appUserID)
        setReservedAttribute(.ip, value: "true", appUserID: appUserID)
    }

    /// - Parameter syncedAttribute: will be called for every attribute that is updated
    /// - Parameter completion: will be called once all attributes have completed syncing
    /// - Returns: the number of attributes that will be synced
    @discardableResult
    func syncAttributesForAllUsers(currentAppUserID: String,
                                   syncedAttribute: ((Error?) -> Void)? = nil,
                                   completion: (() -> Void)? = nil) -> Int {
        let unsyncedAttributesForAllUsers = unsyncedAttributesByKeyForAllUsers()
        let total = unsyncedAttributesForAllUsers.count

        operationDispatcher.dispatchOnWorkerThread {
            let completed: Atomic<Int> = .init(0)

            for (syncingAppUserId, attributes) in unsyncedAttributesForAllUsers {
                self.syncAttributes(attributes: attributes, appUserID: syncingAppUserId) { error in
                    self.handleAttributesSynced(syncingAppUserId: syncingAppUserId,
                                                currentAppUserId: currentAppUserID,
                                                error: error)

                    syncedAttribute?(error)
                    let completedSoFar: Int = completed.modify { $0 += 1; return $0 }

                    if completedSoFar == total {
                        completion?()
                    }
                }
            }

            if total == 0 {
                completion?()
            }
        }

        return total
    }

    func handleAttributesSynced(syncingAppUserId: String, currentAppUserId: String, error: Error?) {
        if error == nil {
            Logger.rcSuccess(Strings.attribution.attributes_sync_success(appUserID: syncingAppUserId))
            if syncingAppUserId != currentAppUserId {
                deviceCache.deleteAttributesIfSynced(appUserID: syncingAppUserId)
            }
        } else {
            let receivedNSError = error as NSError?
            Logger.error(Strings.attribution.attributes_sync_error(error: receivedNSError))
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

    func markAttributesAsSynced(_ attributesToSync: SubscriberAttributeDict?, appUserID: String) {
        guard let attributesToSync = attributesToSync,
              !attributesToSync.isEmpty else {
            return
        }

        Logger.info(Strings.attribution.marking_attributes_synced(appUserID: appUserID, attributes: attributesToSync))

        self.lock.perform {
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
        }
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

    func setReservedAttribute(_ reservedAttribute: ReservedSubscriberAttribute, value: String?, appUserID: String) {
        Logger.debug(Strings.attribution.setting_reserved_attribute(reservedAttribute))
        setAttribute(key: reservedAttribute.key, value: value, appUserID: appUserID)
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
        let attribute = deviceCache.subscriberAttribute(attributeKey: key, appUserID: appUserID)
        return attribute?.value
    }

    func setAttributionID(_ attributionID: String?,
                          forNetworkID networkID: ReservedSubscriberAttribute,
                          appUserID: String) {
        collectDeviceIdentifiers(forAppUserID: appUserID)
        setReservedAttribute(networkID, value: attributionID, appUserID: appUserID)
    }

}
