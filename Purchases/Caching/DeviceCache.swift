//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeviceCache.swift
//
//  Created by Joshua Liebowitz on 7/13/21.
//

import Foundation

// swiftlint:disable file_length
class DeviceCache {

    // Thread-safe, but don't call from anywhere inside this class.
    var cachedAppUserID: String? {
        self.userDefaults.perform {
            Self.cachedAppUserID($0)
        }
    }
    var cachedLegacyAppUserID: String? {
        self.userDefaults.perform {
            $0.string(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
        }
    }
    var cachedOfferings: Offerings? { offeringsCachedObject.cachedInstance() }

    private let userDefaults: SynchronizedUserDefaults
    private let notificationCenter: NotificationCenter
    private let offeringsCachedObject: InMemoryCachedObject<Offerings>

    /// Keeps track of whether user ID has been set to detect users clearing `UserDefaults`
    /// cleared from under the SDK
    private var appUserIDHasBeenSet: Bool = false

    private static let cacheDurationInSecondsInForeground = 60 * 5.0
    private static let cacheDurationInSecondsInBackground = 60 * 60 * 25.0

    convenience init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.init(userDefaults: userDefaults, offeringsCachedObject: nil, notificationCenter: nil)
    }

    init(userDefaults: UserDefaults = UserDefaults.standard,
         offeringsCachedObject: InMemoryCachedObject<Offerings>? = InMemoryCachedObject(),
         notificationCenter: NotificationCenter? = NotificationCenter.default) {

        self.offeringsCachedObject = offeringsCachedObject ?? InMemoryCachedObject()
        self.notificationCenter = notificationCenter ?? NotificationCenter.default
        self.userDefaults = .init(userDefaults: userDefaults)
        self.appUserIDHasBeenSet = userDefaults.string(forKey: .appUserDefaults) != nil

        self.notificationCenter.addObserver(self,
                                            selector: #selector(self.handleUserDefaultsChanged),
                                            name: UserDefaults.didChangeNotification,
                                            object: userDefaults)
    }

    @objc private func handleUserDefaultsChanged(notification: Notification) {
        guard let userDefaults = notification.object as? UserDefaults else {
            return
        }

        if appUserIDHasBeenSet && Self.cachedAppUserID(userDefaults) == nil {
            fatalError(
                """
                [\(Logger.frameworkDescription)] - Cached appUserID has been deleted from user defaults.
                This leaves the SDK in an undetermined state. Please make sure that RevenueCat
                entries in user defaults don't get deleted by anything other than the SDK.
                More info: https://rev.cat/userdefaults-crash
                """
            )
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - appUserID

    func cache(appUserID: String) {
        self.userDefaults.perform {
            $0.setValue(appUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet = true
        }
    }

    func clearCaches(oldAppUserID: String, andSaveWithNewUserID newUserID: String) {
        self.userDefaults.perform { userDefaults in
            userDefaults.removeObject(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
            userDefaults.removeObject(
                forKey: CacheKeyBases.customerInfoAppUserDefaults + oldAppUserID
            )

            // Clear CustomerInfo cache timestamp for oldAppUserID.
            userDefaults.removeObject(forKey: CacheKeyBases.customerInfoLastUpdated + oldAppUserID)

            // Clear offerings cache.
            self.offeringsCachedObject.clearCache()

            // Delete attributes if synced for the old app user id.
            if Self.unsyncedAttributesByKey(userDefaults, appUserID: oldAppUserID).isEmpty {
                var attributes = Self.storedAttributesForAllUsers(userDefaults)
                attributes.removeValue(forKey: oldAppUserID)
                userDefaults.setValue(attributes, forKey: CacheKeys.subscriberAttributes)
            }

            // Cache new appUserID.
            userDefaults.setValue(newUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet = true
        }
    }

    // MARK: - customerInfo
    func cachedCustomerInfoData(appUserID: String) -> Data? {
        return self.userDefaults.perform {
            $0.data(forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
        }
    }

    func cache(customerInfo: Data, appUserID: String) {
        self.userDefaults.perform {
            $0.set(customerInfo, forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
            Self.setCustomerInfoCacheTimestampToNow($0, appUserID: appUserID)
        }

    }

    func isCustomerInfoCacheStale(appUserID: String, isAppBackgrounded: Bool) -> Bool {
        return self.userDefaults.perform {
            guard let cachesLastUpdated = Self.customerInfoLastUpdated($0, appUserID: appUserID) else {
                return true
            }

            let timeSinceLastCheck = cachesLastUpdated.timeIntervalSinceNow * -1
            let cacheDurationInSeconds = self.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)

            return timeSinceLastCheck >= cacheDurationInSeconds
        }
    }

    func clearCustomerInfoCacheTimestamp(appUserID: String) {
        self.userDefaults.perform {
            Self.clearCustomerInfoCacheTimestamp($0, appUserID: appUserID)
        }
    }

    func setCustomerInfoCache(timestamp: Date, appUserID: String) {
        self.userDefaults.perform {
            Self.setCustomerInfoCache($0, timestamp: timestamp, appUserID: appUserID)
        }
    }

    func clearCustomerInfoCache(appUserID: String) {
        self.userDefaults.perform {
            Self.clearCustomerInfoCacheTimestamp($0, appUserID: appUserID)
            $0.removeObject(forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
        }
    }

    func setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: String) {
        self.userDefaults.perform {
            Self.setCustomerInfoCacheTimestampToNow($0, appUserID: appUserID)
        }
    }

    // MARK: - offerings
    func cache(offerings: Offerings) {
        offeringsCachedObject.cache(instance: offerings)
    }

    func isOfferingsCacheStale(isAppBackgrounded: Bool) -> Bool {
        let cacheDurationInSeconds = cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)
        return offeringsCachedObject.isCacheStale(durationInSeconds: cacheDurationInSeconds)
    }

    func clearOfferingsCacheTimestamp() {
        offeringsCachedObject.clearCacheTimestamp()
    }

    func setOfferingsCacheTimestampToNow() {
        offeringsCachedObject.updateCacheTimestamp(date: Date())
    }

    // MARK: - subscriber attributes

    func store(subscriberAttribute: SubscriberAttribute, appUserID: String) {
        store(subscriberAttributesByKey: [subscriberAttribute.key: subscriberAttribute], appUserID: appUserID)
    }

    func store(subscriberAttributesByKey: [String: SubscriberAttribute], appUserID: String) {
        guard !subscriberAttributesByKey.isEmpty else {
            return
        }

        self.userDefaults.perform {
            var groupedSubscriberAttributes = Self.storedAttributesForAllUsers($0)
            var subscriberAttributesForAppUserID = groupedSubscriberAttributes[appUserID] as? [String: Any] ?? [:]
            for (key, attributes) in subscriberAttributesByKey {
                subscriberAttributesForAppUserID[key] = attributes.asDictionary()
            }
            groupedSubscriberAttributes[appUserID] = subscriberAttributesForAppUserID
            $0.setValue(groupedSubscriberAttributes, forKey: .subscriberAttributes)
        }
    }

    func subscriberAttribute(attributeKey: String, appUserID: String) -> SubscriberAttribute? {
        return self.userDefaults.perform {
            Self.storedSubscriberAttributes($0, appUserID: appUserID)[attributeKey]
        }
    }

    // Threadsafe using accessQueue, however accessQueue is not reentrant. If you're calling this from somewhere
    // that ends up in the accessQueue, it will deadlock. Instead, you'll want to call the version that isn't wrapped
    // in a readCache{} block: threadUnsafeUnsyncedAttributesByKey
    func unsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        return self.userDefaults.perform {
            Self.unsyncedAttributesByKey($0, appUserID: appUserID)
        }
    }

    func numberOfUnsyncedAttributes(appUserID: String) -> Int {
        return self.unsyncedAttributesByKey(appUserID: appUserID).count
    }

    func cleanupSubscriberAttributes() {
        self.userDefaults.perform {
            Self.migrateSubscriberAttributes($0)
            Self.deleteSyncedSubscriberAttributesForOtherUsers($0)
        }
    }

    func unsyncedAttributesForAllUsers() -> [String: [String: SubscriberAttribute]] {
        self.userDefaults.perform {
            let attributesDict = $0.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
            var attributes: [String: [String: SubscriberAttribute]] = [:]
            for (appUserID, attributesDictForUser) in attributesDict {
                var attributesForUser: [String: SubscriberAttribute] = [:]
                let attributesDictForUser = attributesDictForUser as? [String: [String: Any]] ?? [:]
                for (attributeKey, attributeDict) in attributesDictForUser {
                    let attribute = DeviceCache.newAttribute(dictionary: attributeDict)
                    if !attribute.isSynced {
                        attributesForUser[attributeKey] = attribute
                    }
                }
                if attributesForUser.count > 0 {
                    attributes[appUserID] = attributesForUser
                }
            }
            return attributes
        }
    }

    func deleteAttributesIfSynced(appUserID: String) {
        self.userDefaults.perform {
            guard Self.unsyncedAttributesByKey($0, appUserID: appUserID).isEmpty else {
                return
            }
            var groupedAttributes = Self.storedAttributesForAllUsers($0)
            let attibutesForAppUserID = groupedAttributes.removeValue(forKey: appUserID)
            guard attibutesForAppUserID != nil else {
                Logger.warn("Attempt to delete synced attributes for \(appUserID), but there were none to delete")
                return
            }
            $0.setValue(groupedAttributes, forKey: CacheKeys.subscriberAttributes)
        }
    }

    // MARK: - attribution

    func latestNetworkAndAdvertisingIdsSent(appUserID: String) -> [String: String] {
        return self.userDefaults.perform {
            let key = CacheKeyBases.attributionDataDefaults + appUserID
            let latestNetworkAndAdvertisingIdsSent = $0.object(forKey: key) as? [String: String] ?? [:]
            return latestNetworkAndAdvertisingIdsSent
        }
    }

    func set(latestNetworkAndAdvertisingIdsSent: [String: String], appUserID: String) {
        self.userDefaults.perform {
            $0.setValue(latestNetworkAndAdvertisingIdsSent,
                        forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    func clearLatestNetworkAndAdvertisingIdsSent(appUserID: String) {
        self.userDefaults.perform {
            $0.removeObject(forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    private func cacheDurationInSeconds(isAppBackgrounded: Bool) -> Double {
        return isAppBackgrounded
        ? Self.cacheDurationInSecondsInBackground
        : Self.cacheDurationInSecondsInForeground
    }

    // MARK: - Helper functions

    static func newAttribute(dictionary: [String: Any]) -> SubscriberAttribute {
        // swiftlint:disable force_cast
        let key = dictionary[SubscriberAttribute.keyKey] as! String
        let value = dictionary[SubscriberAttribute.valueKey] as? String
        let isSynced = (dictionary[SubscriberAttribute.isSyncedKey] as! NSNumber).boolValue
        let setTime = dictionary[SubscriberAttribute.setTimeKey] as! Date
        // swiftlint:enable force_cast

        return SubscriberAttribute(withKey: key, value: value, isSynced: isSynced, setTime: setTime)
    }

    fileprivate enum CacheKeys: String {

        case legacyGeneratedAppUserDefaults = "com.revenuecat.userdefaults.appUserID"
        case appUserDefaults = "com.revenuecat.userdefaults.appUserID.new"
        case subscriberAttributes = "com.revenuecat.userdefaults.subscriberAttributes"

    }

    fileprivate struct CacheKeyBases {

        static let keyBase = "com.revenuecat.userdefaults."
        static let customerInfoAppUserDefaults = "\(keyBase)purchaserInfo."
        static let customerInfoLastUpdated = "\(keyBase)purchaserInfoLastUpdated."
        static let legacySubscriberAttributes = "\(keyBase)subscriberAttributes."
        static let attributionDataDefaults = "\(keyBase)attribution."

    }

}

// All methods that modify or read from the UserDefaults data source but require external mechanisms for ensuring
// mutual exclusion.
private extension DeviceCache {

    static func appUserIDsWithLegacyAttributes(_ userDefaults: UserDefaults) -> [String] {
        var appUserIDsWithLegacyAttributes: [String] = []

        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for key in userDefaultsDict.keys where key.starts(with: CacheKeyBases.keyBase) {
            let appUserID = key.replacingOccurrences(of: CacheKeyBases.legacySubscriberAttributes, with: "")
            appUserIDsWithLegacyAttributes.append(appUserID)
        }

        return appUserIDsWithLegacyAttributes
    }

    static func cachedAppUserID(_ userDefaults: UserDefaults) -> String? {
        userDefaults.string(forKey: CacheKeys.appUserDefaults.rawValue)
    }

    static func storedAttributesForAllUsers(_ userDefaults: UserDefaults) -> [String: Any] {
        let attributes = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        return attributes
    }

    static func customerInfoLastUpdated(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) -> Date? {
        return userDefaults.object(forKey: CacheKeyBases.customerInfoLastUpdated + appUserID) as? Date
    }

    static func clearCustomerInfoCacheTimestamp(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) {
        userDefaults.removeObject(forKey: CacheKeyBases.customerInfoLastUpdated + appUserID)
    }

    static func unsyncedAttributesByKey(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) -> [String: SubscriberAttribute] {
        let allSubscriberAttributesByKey = Self.storedSubscriberAttributes(
            userDefaults,
            appUserID: appUserID
        )
        var unsyncedAttributesByKey: [String: SubscriberAttribute] = [:]
        for attribute in allSubscriberAttributesByKey.values where !attribute.isSynced {
            unsyncedAttributesByKey[attribute.key] = attribute
        }
        return unsyncedAttributesByKey
    }

    static func setCustomerInfoCache(
        _ userDefaults: UserDefaults,
        timestamp: Date,
        appUserID: String
    ) {
        userDefaults.setValue(timestamp, forKey: CacheKeyBases.customerInfoLastUpdated + appUserID)
    }

    static func setCustomerInfoCacheTimestampToNow(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) {
        Self.setCustomerInfoCache(userDefaults, timestamp: Date(), appUserID: appUserID)
    }

    static func subscriberAttributes(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) -> [String: Any] {
        return Self.storedAttributesForAllUsers(userDefaults)[appUserID] as? [String: Any] ?? [:]
    }

    static func storedSubscriberAttributes(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) -> [String: SubscriberAttribute] {
        let allAttributesObjectsByKey = Self.subscriberAttributes(userDefaults, appUserID: appUserID)
        var allSubscriberAttributesByKey: [String: SubscriberAttribute] = [:]
        for (key, attributeDict) in allAttributesObjectsByKey {

            // swiftlint:disable:next force_cast
            let subscriberAttribute = DeviceCache.newAttribute(dictionary: attributeDict as! [String: Any])
            allSubscriberAttributesByKey[key] = subscriberAttribute
        }

        return allSubscriberAttributesByKey
    }

    static func migrateSubscriberAttributes(_ userDefaults: UserDefaults) {
        let appUserIDsWithLegacyAttributes = Self.appUserIDsWithLegacyAttributes(userDefaults)
        var attributesInNewFormat = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        for appUserID in appUserIDsWithLegacyAttributes {
            let legacyAttributes = userDefaults.dictionary(
                forKey: CacheKeyBases.legacySubscriberAttributes + appUserID) ?? [:]
            let existingAttributes = Self.subscriberAttributes(userDefaults,
                                                               appUserID: appUserID)
            let allAttributesForUser = legacyAttributes.merging(existingAttributes)
            attributesInNewFormat[appUserID] = allAttributesForUser

            let legacyAttributesKey = CacheKeyBases.legacySubscriberAttributes + appUserID
            userDefaults.removeObject(forKey: legacyAttributesKey)

        }
        userDefaults.setValue(attributesInNewFormat, forKey: CacheKeys.subscriberAttributes)
    }

    static func deleteSyncedSubscriberAttributesForOtherUsers(
        _ userDefaults: UserDefaults
    ) {
        let allStoredAttributes: [String: [String: Any]]
        = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes)
        as? [String: [String: Any]] ?? [:]

        var filteredAttributes: [String: Any] = [:]

        let currentAppUserID = Self.cachedAppUserID(userDefaults)!

        filteredAttributes[currentAppUserID] = allStoredAttributes[currentAppUserID]

        for appUserID in allStoredAttributes.keys where appUserID != currentAppUserID {
            var unsyncedAttributesForUser: [String: [String: Any]] = [:]
            let allStoredAttributesForAppUserID = allStoredAttributes[appUserID] as? [String: [String: Any]] ?? [:]
            for (attributeKey, storedAttributesForUser) in allStoredAttributesForAppUserID {
                let attribute = DeviceCache.newAttribute(dictionary: storedAttributesForUser)

                if !attribute.isSynced {
                    unsyncedAttributesForUser[attributeKey] = storedAttributesForUser
                }
            }

            if !unsyncedAttributesForUser.isEmpty {
                filteredAttributes[appUserID] = unsyncedAttributesForUser
            }
        }

        userDefaults.setValue(filteredAttributes, forKey: .subscriberAttributes)
    }

}

fileprivate extension UserDefaults {

    func setValue(_ value: Any?, forKey key: DeviceCache.CacheKeys) {
        self.setValue(value, forKey: key.rawValue)
    }

    func string(forKey defaultName: DeviceCache.CacheKeys) -> String? {
        return self.string(forKey: defaultName.rawValue)
    }

    func removeObject(forKey defaultName: DeviceCache.CacheKeys) {
        removeObject(forKey: defaultName.rawValue)
    }

    func dictionary(forKey defaultName: DeviceCache.CacheKeys) -> [String: Any]? {
        return dictionary(forKey: defaultName.rawValue)
    }

}


// swiftlint:enable file_length
