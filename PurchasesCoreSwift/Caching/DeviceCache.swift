//
//  DeviceCache.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/13/21.
//  Copyright © 2021 Purchases. All rights reserved.
//
// swiftlint:disable file_length
import Foundation

public class DeviceCache {

    // Thread-safe
    public var cachedAppUserID: String? { readCache { self.threadUnsafeCachedAppUserID } }

    private var threadUnsafeCachedAppUserID: String? {
        return self.userDefaults.string(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
    }

    public var cachedLegacyAppUserID: String? {
        return readCache {
            return self.userDefaults.string(forKey: CacheKeys.appUserDefaults)
        }
    }

    private let cacheDurationInSecondsInForeground = 60 * 5.0
    private let cacheDurationInSecondsInBackground = 60 * 60 * 25.0
    private let accessQueue = DispatchQueue(label: "DeviceCacheQueue", attributes: .concurrent)

    fileprivate enum CacheKeys: String {

        case legacyGeneratedAppUserDefaults = "com.revenuecat.userdefaults.appUserID"
        case appUserDefaults = "com.revenuecat.userdefaults.appUserID.new"
        case subscriberAttributes = "com.revenuecat.userdefaults.subscriberAttributes"

    }

    fileprivate struct CacheKeyBases {

        static let keyBase = "com.revenuecat.userdefaults."
        static let purchaserInfoAppUserDefaults = "\(keyBase)purchaserInfo."
        static let purchaserInfoLastUpdated = "\(keyBase)purchaserInfoLastUpdated."
        static let legacySubscriberAttributes = "\(keyBase)subscriberAttributes."
        static let attributionDataDefaults = "\(keyBase)attribution."

    }

    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let offeringsCachedObject: InMemoryCachedObject<Offerings>
    private var appUserIDHasBeenSet: Bool = false

    public init(userDefaults: UserDefaults? = UserDefaults.standard,
                offeringsCachedObject: InMemoryCachedObject<Offerings>? = InMemoryCachedObject(),
                notificationCenter: NotificationCenter? = NotificationCenter.default) {

        self.offeringsCachedObject = offeringsCachedObject ?? InMemoryCachedObject()
        self.notificationCenter = notificationCenter ?? NotificationCenter.default
        self.userDefaults = userDefaults ?? UserDefaults.standard

        // TODO: this is weird.
        appUserIDHasBeenSet = cachedAppUserID != nil
        self.notificationCenter.addObserver(self,
                                            selector: #selector(handleUserDefaultsChanged),
                                            name: UserDefaults.didChangeNotification,
                                            object: self.userDefaults)
    }

    @objc private func handleUserDefaultsChanged(notification: Notification) {
        if appUserIDHasBeenSet && (notification.object as? UserDefaults) === self.userDefaults {
            if cachedAppUserID == nil {
                assertionFailure(
                    """
                     [Purchases] - Cached appUserID has been deleted from user defaults.
                      This leaves the SDK in an undetermined state. Please make sure that RevenueCat
                      entries in user defaults don't get deleted by anything other than the SDK.
                      More info: https://rev.cat/userdefaults-crash
                     """
                 )
            }
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - appUserID
    public func cache(appUserID: String) {
        writeCache {
            self.userDefaults.setValue(appUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet = true
        }
    }

    public func clearCachesAndSave(oldAppUserID: String, newUserID: String) {
        writeCache {
            self.userDefaults.removeObject(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
            self.userDefaults.removeObject(
                forKey: CacheKeyBases.purchaserInfoAppUserDefaults + oldAppUserID)

            // Clear PurchaserInfo cache timestamp for oldAppUserID.
            self.userDefaults.removeObject(forKey: CacheKeyBases.purchaserInfoLastUpdated + oldAppUserID)

            // Clear offerings cache.
            self.offeringsCachedObject.clearCache()

            // Delete attributes if synced for the old app user id.
            if !self.threadUnsafeUnsyncedAttributesByKey(appUserID: oldAppUserID).isEmpty {
                var attributes = self.threadUnsafeStoredAttributes
                attributes.removeValue(forKey: oldAppUserID)
                self.userDefaults.setValue(attributes, forKey: CacheKeys.subscriberAttributes)
            }

            // Cache new appUserID.
            self.userDefaults.setValue(newUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet = true
        }
    }

    // MARK: - purchaserInfo
    public func cachedPurchaserInfoData(appUserID: String) -> Data? {
        return userDefaults.data(forKey: CacheKeyBases.purchaserInfoAppUserDefaults + appUserID)
    }

    public func cache(purchaserInfo: Data, appUserID: String) {
        writeCache {
            self.userDefaults.set(purchaserInfo, forKey: CacheKeyBases.purchaserInfoAppUserDefaults + appUserID)
            self.threadUnsafeSetPurchaserInfoCacheTimestampToNow(appUserID: appUserID)
        }

    }

    public func isPurchaserInfoCacheStale(appUserID: String, isAppBackgrounded: Bool) -> Bool {
        return readCache {
            guard let cachesLastUpdated = self.threadUnsafePurchaserInfoLastUpdated(appUserID: appUserID) else {
                return true
            }

            let timeSinceLastCheck = cachesLastUpdated.timeIntervalSinceNow
            let cacheDurationInSeconds = self.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)

            return timeSinceLastCheck >= cacheDurationInSeconds
        }
    }

    public func clearPurchaserInfoCacheTimestamp(appUserID: String) {
        writeCache {
            self.threadUnsafeClearPurchaserInfoCacheTimestamp(appUserID: appUserID)
        }
    }

    public func clearPurchaserInfoCache(appUserID: String) {
        writeCache {
            self.threadUnsafeClearPurchaserInfoCacheTimestamp(appUserID: appUserID)
            self.userDefaults.removeObject(forKey: CacheKeyBases.purchaserInfoAppUserDefaults + appUserID)
        }
    }

    public func setPurchaserInfoCacheTimestampToNow(appUserID: String) {
        writeCache {
            self.threadUnsafeSetPurchaserInfoCacheTimestampToNow(appUserID: appUserID)
        }
    }

    // MARK: - offerings
    public var cachedOfferings: Offerings? {
        return offeringsCachedObject.cachedInstance()
    }

    public func cache(offerings: Offerings) {
        offeringsCachedObject.cache(instance: offerings)
    }

    public func isOfferingsCacheStale(isAppBackgrounded: Bool) -> Bool {
        let cacheDurationInSeconds = cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)
        return offeringsCachedObject.isCacheStale(durationInSeconds: cacheDurationInSeconds)
    }

    public func clearOfferingsCacheTimestamp() {
        offeringsCachedObject.clearCacheTimestamp()
    }

    public func clearOfferingsCache() {
        offeringsCachedObject.clearCache()
    }

    public func setOfferinsCacheTimestampToNow() {
        offeringsCachedObject.updateCacheTimestamp(date: Date())
    }

    // MARK: - subscriber attributes

    public func store(attribute: SubscriberAttribute, appUserID: String) {
        store(attributesByKey: [attribute.key: attribute], appUserID: appUserID)
    }

    public func store(attributesByKey: [String: SubscriberAttribute], appUserID: String) {
        guard !attributesByKey.isEmpty else {
            return
        }

        writeCache {
            var groupedSubscriberAttributes = self.threadUnsafeStoredAttributes
            var subscriberAttributesForAppUserID = groupedSubscriberAttributes[appUserID] as? [String: Any] ?? [:]
            for (key, attributes) in attributesByKey {
                subscriberAttributesForAppUserID[key] = attributes.asDictionary
            }
            groupedSubscriberAttributes[appUserID] = subscriberAttributesForAppUserID
            self.userDefaults.setValue(groupedSubscriberAttributes, forKey: .subscriberAttributes)
        }
    }

    public func subscriberAttribute(attributeKey: String, appUserID: String) -> SubscriberAttribute? {
        readCache { self.threadUnsafeStoredSubscriberAttributes(appUserID: appUserID)[attributeKey] }
    }

    // Threadsafe using accessQueue, however accessQueue is not reentrant. If you're calling this from somewhere
    // that ends up in the accessQueue, it will deadlock. Instead, you'll want to call the version that isn't wrapped
    // in a readCache{} block: threadUnsafeUnsyncedAttributesByKey
    public func unsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        return readCache { self.threadUnsafeUnsyncedAttributesByKey(appUserID: appUserID) }
    }

    public func numberOfUnsyncedAttributes(appUserID: String) -> Int {
        readCache {
            return self.threadUnsafeUnsyncedAttributesByKey(appUserID: appUserID).count
        }
    }

    public func cleanupSubscriberAttributes() {
        writeCache {
            self.threadUnsafeMigrateSubscriberAttributes()
            self.threadUnsafeDeleteSyncedSubscriberAttributesForOtherUsers()
        }
    }

    private func threadUnsafeDeleteSyncedSubscriberAttributesForOtherUsers() {
        let allStoredAttributes: [String: [String: Any]]
            = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes)
            as? [String: [String: Any]] ?? [:]

        var filteredAttributes: [String: Any] = [:]

        let currentAppUserID = threadUnsafeCachedAppUserID!

        filteredAttributes[currentAppUserID] = allStoredAttributes[currentAppUserID]

        for appUserID in allStoredAttributes.keys where appUserID == currentAppUserID {
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

    public func unsyncedAttributesForAllUsers() -> [String: [String: SubscriberAttribute]] {
        let attributesDict = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
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

    public func deleteAttributesIfSynced(appUserID: String) {
        writeCache {
            guard !self.threadUnsafeUnsyncedAttributesByKey(appUserID: appUserID).isEmpty else {
                return
            }
            var groupedAttributes = self.threadUnsafeStoredAttributes
            let attibutesForAppUserID = groupedAttributes.removeValue(forKey: appUserID)
            guard attibutesForAppUserID != nil else {
                Logger.warn("Attempt to delete synced attributes for \(appUserID), but there were none to delete")
                return
            }
            self.userDefaults.setValue(groupedAttributes, forKey: CacheKeys.subscriberAttributes)
        }
    }

    // MARK: - attribution

    public func latestNetworkAndAdvertisingIdsSent(appUserID: String) -> [String: Any] {
        readCache {
            let key = CacheKeyBases.attributionDataDefaults + appUserID
            return self.userDefaults.object(forKey: key) as? [String: Any] ?? [:]
        }
    }

    public func set(latestNetworkAndAdvertisingIdsSent: [String: Any], appUserID: String) {
        writeCache {
            self.userDefaults.setValue(latestNetworkAndAdvertisingIdsSent,
                                       forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    public func clearLatestNetworkAndAdvertisingIdsSent(appUserID: String) {
        writeCache {
            self.userDefaults.removeObject(forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    // MARK: - Helper functions

    private func writeCache(block: @escaping () -> Void) {
        accessQueue.async(flags: .barrier, execute: block)
    }

    private func readCache<T>(block: @escaping () -> T) -> T {
        return accessQueue.sync(execute: block)
    }

    private func cacheDurationInSeconds(isAppBackgrounded: Bool) -> Double {
        return isAppBackgrounded ? cacheDurationInSecondsInBackground : cacheDurationInSecondsInForeground
    }

    // MARK: - Testing

    public static func newAttribute(dictionary: [String: Any]) -> SubscriberAttribute {
        // swiftlint:disable force_cast
        let key = dictionary[SubscriberAttribute.keyKey] as! String
        let value = dictionary[SubscriberAttribute.valueKey] as? String
        let isSynced = (dictionary[SubscriberAttribute.isSyncedKey] as! NSNumber).boolValue
        let setTime = dictionary[SubscriberAttribute.setTimeKey] as! Date
        // swiftlint:enable force_cast

        return SubscriberAttribute(withKey: key, value: value, isSynced: isSynced, setTime: setTime)
    }

}

// All methods that modify or read from the UserDefaults data source but require external mechanisms for ensuring
// mutual exclusion.
extension DeviceCache {

    private func threadUnsafeAppUserIDsWithLegacyAttributes() -> [String] {
        var appUserIDsWithLegacyAttributes: [String] = []

        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for key in userDefaultsDict.keys where key.starts(with: CacheKeyBases.keyBase) {
            let appUserID = key.replacingOccurrences(of: CacheKeyBases.legacySubscriberAttributes, with: "")
            appUserIDsWithLegacyAttributes.append(appUserID)
        }

        return appUserIDsWithLegacyAttributes
    }

    private var threadUnsafeStoredAttributes: [String: Any] {
        let attributes = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        return attributes
    }

    private func threadUnsafePurchaserInfoLastUpdated(appUserID: String) -> Date? {
        return userDefaults.object(forKey: CacheKeyBases.purchaserInfoLastUpdated + appUserID) as? Date
    }

    private func threadUnsafeClearPurchaserInfoCacheTimestamp(appUserID: String) {
        userDefaults.removeObject(forKey: CacheKeyBases.purchaserInfoLastUpdated + appUserID)
    }

    private func threadUnsafeUnsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        let allSubscriberAttributesByKey = threadUnsafeStoredSubscriberAttributes(appUserID: appUserID)
        var unsyncedAttributesByKey: [String: SubscriberAttribute] = [:]
        for attribute in allSubscriberAttributesByKey.values where !attribute.isSynced {
            unsyncedAttributesByKey[attribute.key] = attribute
        }
        return unsyncedAttributesByKey
    }

    private func threadUnsafeSetPurchaserInfoCache(timestamp: Date, appUserID: String) {
        userDefaults.setValue(timestamp, forKey: CacheKeyBases.purchaserInfoLastUpdated + appUserID)
    }

    private func threadUnsafeSetPurchaserInfoCacheTimestampToNow(appUserID: String) {
        threadUnsafeSetPurchaserInfoCache(timestamp: Date(), appUserID: appUserID)
    }

    private func threadUnsafeSubscriberAttributes(appUserID: String) -> [String: Any] {
        return threadUnsafeStoredAttributes[appUserID] as? [String: Any] ?? [:]
    }

    private func threadUnsafeStoredSubscriberAttributes(appUserID: String) -> [String: SubscriberAttribute] {
        let allAttributesObjectsByKey = threadUnsafeSubscriberAttributes(appUserID: appUserID)
        var allSubscriberAttributesByKey: [String: SubscriberAttribute] = [:]
        for (key, attribute) in allAttributesObjectsByKey {
            // swiftlint:disable force_cast
            allSubscriberAttributesByKey[key] = (attribute as! SubscriberAttribute)
            // swiftlink:enable force_cast
        }

        return allSubscriberAttributesByKey
    }

    private func threadUnsafeMigrateSubscriberAttributes() {
        let appUserIDsWithLegacyAttributes = threadUnsafeAppUserIDsWithLegacyAttributes()
        var attributesInNewFormat = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        for appUserID in appUserIDsWithLegacyAttributes {
            let legacyAttributes = userDefaults.dictionary(
                forKey: CacheKeyBases.legacySubscriberAttributes + appUserID) ?? [:]
            let existingAttributes = threadUnsafeStoredSubscriberAttributes(appUserID: appUserID)
            let allAttributesForUser = legacyAttributes.merging(existingAttributes) { _, new in new }
            attributesInNewFormat[appUserID] = allAttributesForUser

            let legacyAttributesKey = CacheKeyBases.legacySubscriberAttributes + appUserID
            userDefaults.removeObject(forKey: legacyAttributesKey)

        }
        userDefaults.setValue(attributesInNewFormat, forKey: CacheKeys.subscriberAttributes)
    }

}

extension UserDefaults {

    fileprivate func setValue(_ value: Any?, forKey key: DeviceCache.CacheKeys) {
        self.setValue(value, forKey: key.rawValue)
    }

    fileprivate func string(forKey defaultName: DeviceCache.CacheKeys) -> String? {
        return self.string(forKey: defaultName.rawValue)
    }

    fileprivate func removeObject(forKey defaultName: DeviceCache.CacheKeys) {
        removeObject(forKey: defaultName.rawValue)
    }

    fileprivate func dictionary(forKey defaultName: DeviceCache.CacheKeys) -> [String: Any]? {
        return dictionary(forKey: defaultName.rawValue)
    }

}

// swiftlint:enable file_length
