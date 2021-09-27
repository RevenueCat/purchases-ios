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
    var cachedAppUserID: String? { readCache { self.threadUnsafeCachedAppUserID } }
    var cachedLegacyAppUserID: String? {
        return readCache {
            return self.userDefaults.string(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
        }
    }
    var cachedOfferings: Offerings? { offeringsCachedObject.cachedInstance() }

    private let cacheDurationInSecondsInForeground = 60 * 5.0
    private let cacheDurationInSecondsInBackground = 60 * 60 * 25.0
    private let accessQueue = DispatchQueue(label: "DeviceCacheQueue")
    private var threadUnsafeCachedAppUserID: String? { userDefaults.string(forKey: CacheKeys.appUserDefaults.rawValue) }
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let offeringsCachedObject: InMemoryCachedObject<Offerings>
    private var appUserIDHasBeenSet: Bool = false

    convenience init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.init(userDefaults: userDefaults, offeringsCachedObject: nil, notificationCenter: nil)
    }

    init(userDefaults: UserDefaults = UserDefaults.standard,
         offeringsCachedObject: InMemoryCachedObject<Offerings>? = InMemoryCachedObject(),
         notificationCenter: NotificationCenter? = NotificationCenter.default) {

        self.offeringsCachedObject = offeringsCachedObject ?? InMemoryCachedObject()
        self.notificationCenter = notificationCenter ?? NotificationCenter.default
        self.userDefaults = userDefaults
        self.appUserIDHasBeenSet = userDefaults.string(forKey: CacheKeys.appUserDefaults) != nil

        self.notificationCenter.addObserver(self,
                                            selector: #selector(handleUserDefaultsChanged),
                                            name: UserDefaults.didChangeNotification,
                                            object: self.userDefaults)
    }

    @objc private func handleUserDefaultsChanged(notification: Notification) {
        guard let notificationObject = notification.object as? UserDefaults,
              notificationObject == self.userDefaults else {
            return
        }

        if appUserIDHasBeenSet && threadUnsafeCachedAppUserID == nil {
            fatalError(
                """
                [Purchases] - Cached appUserID has been deleted from user defaults.
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
        writeCache {
            self.userDefaults.setValue(appUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet = true
        }
    }

    func clearCaches(oldAppUserID: String, andSaveWithNewUserID newUserID: String) {
        writeCache {
            self.userDefaults.removeObject(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
            self.userDefaults.removeObject(
                forKey: CacheKeyBases.customerInfoAppUserDefaults + oldAppUserID)

            // Clear CustomerInfo cache timestamp for oldAppUserID.
            self.userDefaults.removeObject(forKey: CacheKeyBases.customerInfoLastUpdated + oldAppUserID)

            // Clear offerings cache.
            self.offeringsCachedObject.clearCache()

            // Delete attributes if synced for the old app user id.
            if self.threadUnsafeUnsyncedAttributesByKey(appUserID: oldAppUserID).isEmpty {
                var attributes = self.threadUnsafeStoredAttributesForAllUsers
                attributes.removeValue(forKey: oldAppUserID)
                self.userDefaults.setValue(attributes, forKey: CacheKeys.subscriberAttributes)
            }

            // Cache new appUserID.
            self.userDefaults.setValue(newUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet = true
        }
    }

    // MARK: - customerInfo
    func cachedCustomerInfoData(appUserID: String) -> Data? {
        return userDefaults.data(forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
    }

    func cache(customerInfo: Data, appUserID: String) {
        writeCache {
            self.userDefaults.set(customerInfo, forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
            self.threadUnsafeSetCustomerInfoCacheTimestampToNow(appUserID: appUserID)
        }

    }

    func isCustomerInfoCacheStale(appUserID: String, isAppBackgrounded: Bool) -> Bool {
        return readCache {
            guard let cachesLastUpdated = self.threadUnsafeCustomerInfoLastUpdated(appUserID: appUserID) else {
                return true
            }

            let timeSinceLastCheck = cachesLastUpdated.timeIntervalSinceNow * -1
            let cacheDurationInSeconds = self.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)

            return timeSinceLastCheck >= cacheDurationInSeconds
        }
    }

    func clearCustomerInfoCacheTimestamp(appUserID: String) {
        writeCache {
            self.threadUnsafeClearCustomerInfoCacheTimestamp(appUserID: appUserID)
        }
    }

    func setCustomerInfoCache(timestamp: Date, appUserID: String) {
        writeCache {
            self.threadUnsafeSetCustomerInfoCache(timestamp: timestamp, appUserID: appUserID)
        }
    }

    func clearCustomerInfoCache(appUserID: String) {
        writeCache {
            self.threadUnsafeClearCustomerInfoCacheTimestamp(appUserID: appUserID)
            self.userDefaults.removeObject(forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
        }
    }

    func setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: String) {
        writeCache {
            self.threadUnsafeSetCustomerInfoCacheTimestampToNow(appUserID: appUserID)
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

        writeCache {
            var groupedSubscriberAttributes = self.threadUnsafeStoredAttributesForAllUsers
            var subscriberAttributesForAppUserID = groupedSubscriberAttributes[appUserID] as? [String: Any] ?? [:]
            for (key, attributes) in subscriberAttributesByKey {
                subscriberAttributesForAppUserID[key] = attributes.asDictionary()
            }
            groupedSubscriberAttributes[appUserID] = subscriberAttributesForAppUserID
            self.userDefaults.setValue(groupedSubscriberAttributes, forKey: .subscriberAttributes)
        }
    }

    func subscriberAttribute(attributeKey: String, appUserID: String) -> SubscriberAttribute? {
        return readCache { self.threadUnsafeStoredSubscriberAttributes(appUserID: appUserID)[attributeKey] }
    }

    // Threadsafe using accessQueue, however accessQueue is not reentrant. If you're calling this from somewhere
    // that ends up in the accessQueue, it will deadlock. Instead, you'll want to call the version that isn't wrapped
    // in a readCache{} block: threadUnsafeUnsyncedAttributesByKey
    func unsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        return readCache { self.threadUnsafeUnsyncedAttributesByKey(appUserID: appUserID) }
    }

    func numberOfUnsyncedAttributes(appUserID: String) -> Int {
        return readCache {
            return self.threadUnsafeUnsyncedAttributesByKey(appUserID: appUserID).count
        }
    }

    func cleanupSubscriberAttributes() {
        writeCache {
            self.threadUnsafeMigrateSubscriberAttributes()
            self.threadUnsafeDeleteSyncedSubscriberAttributesForOtherUsers()
        }
    }

    func unsyncedAttributesForAllUsers() -> [String: [String: SubscriberAttribute]] {
        return readCache {
            let attributesDict = self.userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
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
        writeCache {
            guard self.threadUnsafeUnsyncedAttributesByKey(appUserID: appUserID).isEmpty else {
                return
            }
            var groupedAttributes = self.threadUnsafeStoredAttributesForAllUsers
            let attibutesForAppUserID = groupedAttributes.removeValue(forKey: appUserID)
            guard attibutesForAppUserID != nil else {
                Logger.warn("Attempt to delete synced attributes for \(appUserID), but there were none to delete")
                return
            }
            self.userDefaults.setValue(groupedAttributes, forKey: CacheKeys.subscriberAttributes)
        }
    }

    // MARK: - attribution

    func latestNetworkAndAdvertisingIdsSent(appUserID: String) -> [String: String] {
        return readCache {
            let key = CacheKeyBases.attributionDataDefaults + appUserID
            let latestNetworkAndAdvertisingIdsSent = self.userDefaults.object(forKey: key) as? [String: String] ?? [:]
            return latestNetworkAndAdvertisingIdsSent
        }
    }

    func set(latestNetworkAndAdvertisingIdsSent: [String: String], appUserID: String) {
        writeCache {
            self.userDefaults.setValue(latestNetworkAndAdvertisingIdsSent,
                                       forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    func clearLatestNetworkAndAdvertisingIdsSent(appUserID: String) {
        writeCache {
            self.userDefaults.removeObject(forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    private func cacheDurationInSeconds(isAppBackgrounded: Bool) -> Double {
        return isAppBackgrounded ? cacheDurationInSecondsInBackground : cacheDurationInSecondsInForeground
    }

    // MARK: - Helper functions

    // Uses the accessQueue to synchronously write to the UserDefaults.
    // Warning: do NOT nest calls to `writeCache`, it will deadlock.
    // Only make calls to functions starting with "threadUnsafe" as those are guaranteed to not have any locking
    // mechanisms.
    private func writeCache(block: @escaping () -> Void) {
        accessQueue.executeByLockingDatasource {
            block()

            // While Apple states `this method is unnecessary and shouldn't be used`
            // https://developer.apple.com/documentation/foundation/userdefaults/1414005-synchronize
            // It didn't become unnecessary until iOS 12 and macOS 10.14 (Mojave):
            // https://developer.apple.com/documentation/macos-release-notes/foundation-release-notes
            // there are reports it is still needed if you save to defaults then immediately kill the app.
            // Also, it has not been marked deprecated... yet.
            self.userDefaults.synchronize()
        }
    }

    // Uses the accessQueue to synchronously read from the UserDefaults which ensures access is threadsafe.
    private func readCache<T>(block: @escaping () -> T) -> T {
        return accessQueue.sync(execute: block)
    }

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

    func threadUnsafeAppUserIDsWithLegacyAttributes() -> [String] {
        var appUserIDsWithLegacyAttributes: [String] = []

        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for key in userDefaultsDict.keys where key.starts(with: CacheKeyBases.keyBase) {
            let appUserID = key.replacingOccurrences(of: CacheKeyBases.legacySubscriberAttributes, with: "")
            appUserIDsWithLegacyAttributes.append(appUserID)
        }

        return appUserIDsWithLegacyAttributes
    }

    var threadUnsafeStoredAttributesForAllUsers: [String: Any] {
        let attributes = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        return attributes
    }

    func threadUnsafeCustomerInfoLastUpdated(appUserID: String) -> Date? {
        return userDefaults.object(forKey: CacheKeyBases.customerInfoLastUpdated + appUserID) as? Date
    }

    func threadUnsafeClearCustomerInfoCacheTimestamp(appUserID: String) {
        userDefaults.removeObject(forKey: CacheKeyBases.customerInfoLastUpdated + appUserID)
    }

    func threadUnsafeUnsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        let allSubscriberAttributesByKey = threadUnsafeStoredSubscriberAttributes(appUserID: appUserID)
        var unsyncedAttributesByKey: [String: SubscriberAttribute] = [:]
        for attribute in allSubscriberAttributesByKey.values where !attribute.isSynced {
            unsyncedAttributesByKey[attribute.key] = attribute
        }
        return unsyncedAttributesByKey
    }

    func threadUnsafeSetCustomerInfoCache(timestamp: Date, appUserID: String) {
        userDefaults.setValue(timestamp, forKey: CacheKeyBases.customerInfoLastUpdated + appUserID)
    }

    func threadUnsafeSetCustomerInfoCacheTimestampToNow(appUserID: String) {
        threadUnsafeSetCustomerInfoCache(timestamp: Date(), appUserID: appUserID)
    }

    func threadUnsafeSubscriberAttributes(appUserID: String) -> [String: Any] {
        return threadUnsafeStoredAttributesForAllUsers[appUserID] as? [String: Any] ?? [:]
    }

    func threadUnsafeStoredSubscriberAttributes(appUserID: String) -> [String: SubscriberAttribute] {
        let allAttributesObjectsByKey = threadUnsafeSubscriberAttributes(appUserID: appUserID)
        var allSubscriberAttributesByKey: [String: SubscriberAttribute] = [:]
        for (key, attributeDict) in allAttributesObjectsByKey {

            // swiftlint:disable force_cast
            let subscriberAttribute = DeviceCache.newAttribute(dictionary: attributeDict as! [String: Any])
            // swiftlint:enable force_cast
            allSubscriberAttributesByKey[key] = subscriberAttribute
        }

        return allSubscriberAttributesByKey
    }

    func threadUnsafeMigrateSubscriberAttributes() {
        let appUserIDsWithLegacyAttributes = threadUnsafeAppUserIDsWithLegacyAttributes()
        var attributesInNewFormat = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        for appUserID in appUserIDsWithLegacyAttributes {
            let legacyAttributes = userDefaults.dictionary(
                forKey: CacheKeyBases.legacySubscriberAttributes + appUserID) ?? [:]
            let existingAttributes = threadUnsafeSubscriberAttributes(appUserID: appUserID)
            let allAttributesForUser = legacyAttributes.merging(existingAttributes)
            attributesInNewFormat[appUserID] = allAttributesForUser

            let legacyAttributesKey = CacheKeyBases.legacySubscriberAttributes + appUserID
            userDefaults.removeObject(forKey: legacyAttributesKey)

        }
        userDefaults.setValue(attributesInNewFormat, forKey: CacheKeys.subscriberAttributes)
    }

    func threadUnsafeDeleteSyncedSubscriberAttributesForOtherUsers() {
        let allStoredAttributes: [String: [String: Any]]
            = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes)
            as? [String: [String: Any]] ?? [:]

        var filteredAttributes: [String: Any] = [:]

        let currentAppUserID = threadUnsafeCachedAppUserID!

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

        self.userDefaults.setValue(filteredAttributes, forKey: .subscriberAttributes)
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

private extension DispatchQueue {

    func executeByLockingDatasource<T>(execute work: () throws -> T) rethrows -> T {
        // .barrier is not needed here because we're using `.sync` instead of the normal .async multi-reader
        // single-writer dispatch queue synchronization pattern.
        return try sync(execute: work)
    }

}

// swiftlint:enable file_length
