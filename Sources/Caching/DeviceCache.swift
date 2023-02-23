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

// swiftlint:disable file_length type_body_length
class DeviceCache {

    var cachedAppUserID: String? {
        self.userDefaults.read(Self.cachedAppUserID)
    }
    var cachedLegacyAppUserID: String? {
        self.userDefaults.read {
            $0.string(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
        }
    }
    var cachedOfferings: Offerings? { self.offeringsCachedObject.cachedInstance() }

    private let sandboxEnvironmentDetector: SandboxEnvironmentDetector
    private let userDefaults: SynchronizedUserDefaults
    private let notificationCenter: NotificationCenter
    private let offeringsCachedObject: InMemoryCachedObject<Offerings>

    /// Keeps track of whether user ID has been set to detect users clearing `UserDefaults`
    /// cleared from under the SDK
    private let appUserIDHasBeenSet: Atomic<Bool> = false

    private var userDefaultsObserver: NSObjectProtocol?

    convenience init(sandboxEnvironmentDetector: SandboxEnvironmentDetector,
                     userDefaults: UserDefaults) {
        self.init(sandboxEnvironmentDetector: sandboxEnvironmentDetector,
                  userDefaults: userDefaults,
                  offeringsCachedObject: nil,
                  notificationCenter: nil)
    }

    init(sandboxEnvironmentDetector: SandboxEnvironmentDetector,
         userDefaults: UserDefaults,
         offeringsCachedObject: InMemoryCachedObject<Offerings>? = InMemoryCachedObject(),
         notificationCenter: NotificationCenter? = NotificationCenter.default) {
        self.sandboxEnvironmentDetector = sandboxEnvironmentDetector
        self.offeringsCachedObject = offeringsCachedObject ?? InMemoryCachedObject()
        self.notificationCenter = notificationCenter ?? NotificationCenter.default
        self.userDefaults = .init(userDefaults: userDefaults)
        self.appUserIDHasBeenSet.value = userDefaults.string(forKey: .appUserDefaults) != nil

        Logger.verbose(Strings.purchase.device_cache_init(self))

        // Observe `UserDefaults` changes through `handleUserDefaultsChanged`
        // to ensure that users don't remove the data from the SDK, which would
        // leave it in an undetermined state. See https://rev.cat/userdefaults-crash
        // If the user is not using a custom `UserDefaults`, we don't need to
        // because they have no access to it.
        if userDefaults !== UserDefaults.revenueCatSuite {
            self.userDefaultsObserver = self.notificationCenter.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: userDefaults,
                queue: nil, // Run synchronously on the posting thread
                using: { [weak self] notification in
                    self?.handleUserDefaultsChanged(notification: notification)
                }
            )
        }
    }

    @objc private func handleUserDefaultsChanged(notification: Notification) {
        guard let userDefaults = notification.object as? UserDefaults else {
            return
        }

        // Note: this should never use `self.userDefaults` directly because this method
        // might be synchronized, and `Atomic` is not reentrant.
        if self.appUserIDHasBeenSet.value && Self.cachedAppUserID(userDefaults) == nil {
            fatalError(Strings.purchase.cached_app_user_id_deleted.description)
        }
    }

    deinit {
        Logger.verbose(Strings.purchase.device_cache_deinit(self))

        if let observer = self.userDefaultsObserver {
            self.notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - appUserID

    func cache(appUserID: String) {
        self.userDefaults.write {
            $0.setValue(appUserID, forKey: CacheKeys.appUserDefaults)
            self.appUserIDHasBeenSet.value = true
        }
    }

    func clearCaches(oldAppUserID: String, andSaveWithNewUserID newUserID: String) {
        self.userDefaults.write { userDefaults in
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
            self.appUserIDHasBeenSet.value = true
        }
    }

    // MARK: - CustomerInfo

    func cachedCustomerInfoData(appUserID: String) -> Data? {
        return self.userDefaults.read {
            $0.data(forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
        }
    }

    func cache(customerInfo: Data, appUserID: String) {
        self.userDefaults.write {
            $0.set(customerInfo, forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
            Self.setCustomerInfoCacheTimestampToNow($0, appUserID: appUserID)
        }
    }

    func isCustomerInfoCacheStale(appUserID: String, isAppBackgrounded: Bool) -> Bool {
        return self.userDefaults.read {
            guard let cachesLastUpdated = Self.customerInfoLastUpdated($0, appUserID: appUserID) else {
                return true
            }

            let timeSinceLastCheck = cachesLastUpdated.timeIntervalSinceNow * -1
            let cacheDurationInSeconds = self.cacheDurationInSeconds(
                isAppBackgrounded: isAppBackgrounded,
                isSandbox: self.sandboxEnvironmentDetector.isSandbox
            )

            return timeSinceLastCheck >= cacheDurationInSeconds
        }
    }

    func clearCachedOfferings() {
        self.offeringsCachedObject.clearCache()
    }

    func clearCustomerInfoCacheTimestamp(appUserID: String) {
        self.userDefaults.write {
            Self.clearCustomerInfoCacheTimestamp($0, appUserID: appUserID)
        }
    }

    func setCustomerInfoCache(timestamp: Date, appUserID: String) {
        self.userDefaults.write {
            Self.setCustomerInfoCache($0, timestamp: timestamp, appUserID: appUserID)
        }
    }

    func clearCustomerInfoCache(appUserID: String) {
        self.userDefaults.write {
            Self.clearCustomerInfoCacheTimestamp($0, appUserID: appUserID)
            $0.removeObject(forKey: CacheKeyBases.customerInfoAppUserDefaults + appUserID)
        }
    }

    func setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: String) {
        self.userDefaults.write {
            Self.setCustomerInfoCacheTimestampToNow($0, appUserID: appUserID)
        }
    }

    // MARK: - offerings

    func cache(offerings: Offerings) {
        offeringsCachedObject.cache(instance: offerings)
    }

    func isOfferingsCacheStale(isAppBackgrounded: Bool) -> Bool {
        return offeringsCachedObject.isCacheStale(
            durationInSeconds: self.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded,
                                                           isSandbox: self.sandboxEnvironmentDetector.isSandbox)
        )
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

        self.userDefaults.write {
            Self.store($0, subscriberAttributesByKey: subscriberAttributesByKey, appUserID: appUserID)
        }
    }

    func subscriberAttribute(attributeKey: String, appUserID: String) -> SubscriberAttribute? {
        return self.userDefaults.read {
            Self.storedSubscriberAttributes($0, appUserID: appUserID)[attributeKey]
        }
    }

    func unsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        return self.userDefaults.read {
            Self.unsyncedAttributesByKey($0, appUserID: appUserID)
        }
    }

    func numberOfUnsyncedAttributes(appUserID: String) -> Int {
        return self.unsyncedAttributesByKey(appUserID: appUserID).count
    }

    func cleanupSubscriberAttributes() {
        self.userDefaults.write {
            Self.migrateSubscriberAttributes($0)
            Self.deleteSyncedSubscriberAttributesForOtherUsers($0)
        }
    }

    func unsyncedAttributesForAllUsers() -> [String: [String: SubscriberAttribute]] {
        self.userDefaults.read {
            let attributesDict = $0.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
            var attributes: [String: [String: SubscriberAttribute]] = [:]
            for (appUserID, attributesDictForUser) in attributesDict {
                var attributesForUser: [String: SubscriberAttribute] = [:]
                let attributesDictForUser = attributesDictForUser as? [String: [String: Any]] ?? [:]
                for (attributeKey, attributeDict) in attributesDictForUser {
                    if let attribute = SubscriberAttribute(dictionary: attributeDict), !attribute.isSynced {
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
        self.userDefaults.write {
            guard Self.unsyncedAttributesByKey($0, appUserID: appUserID).isEmpty else {
                return
            }
            Self.deleteAllAttributes($0, appUserID: appUserID)
        }
    }

    func copySubscriberAttributes(oldAppUserID: String, newAppUserID: String) {
        self.userDefaults.write {
            let unsyncedAttributesToCopy = Self.unsyncedAttributesByKey($0, appUserID: oldAppUserID)
            guard !unsyncedAttributesToCopy.isEmpty else {
                return
            }

            Logger.info(Strings.attribution.copying_attributes(oldAppUserID: oldAppUserID, newAppUserID: newAppUserID))
            Self.store($0, subscriberAttributesByKey: unsyncedAttributesToCopy, appUserID: newAppUserID)
            Self.deleteAllAttributes($0, appUserID: oldAppUserID)
        }
    }

    // MARK: - attribution

    func latestAdvertisingIdsByNetworkSent(appUserID: String) -> [AttributionNetwork: String] {
        return self.userDefaults.read {
            let key = CacheKeyBases.attributionDataDefaults + appUserID
            let latestAdvertisingIdsByRawNetworkSent = $0.object(forKey: key) as? [String: String] ?? [:]

            let latestSent: [AttributionNetwork: String] =
                 latestAdvertisingIdsByRawNetworkSent.compactMapKeys { networkKey in
                     guard let networkRawValue = Int(networkKey),
                        let attributionNetwork = AttributionNetwork(rawValue: networkRawValue) else {
                            Logger.error(
                                Strings.attribution.latest_attribution_sent_user_defaults_invalid(
                                    networkKey: networkKey
                                )
                            )
                             return nil
                        }
                        return attributionNetwork
                    }

            return latestSent
        }
    }

    func set(latestAdvertisingIdsByNetworkSent: [AttributionNetwork: String], appUserID: String) {
        self.userDefaults.write {
            let latestAdIdsByRawNetworkStringSent = latestAdvertisingIdsByNetworkSent.mapKeys { String($0.rawValue) }
            $0.setValue(latestAdIdsByRawNetworkStringSent,
                        forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    func clearLatestNetworkAndAdvertisingIdsSent(appUserID: String) {
        self.userDefaults.write {
            $0.removeObject(forKey: CacheKeyBases.attributionDataDefaults + appUserID)
        }
    }

    private func cacheDurationInSeconds(isAppBackgrounded: Bool, isSandbox: Bool) -> TimeInterval {
        return CacheDuration.duration(status: .init(backgrounded: isAppBackgrounded),
                                      environment: .init(sandbox: isSandbox))
    }

    // MARK: - Helper functions

    internal enum CacheKeys: String {

        case legacyGeneratedAppUserDefaults = "com.revenuecat.userdefaults.appUserID"
        case appUserDefaults = "com.revenuecat.userdefaults.appUserID.new"
        case subscriberAttributes = "com.revenuecat.userdefaults.subscriberAttributes"

    }

    fileprivate enum CacheKeyBases {

        static let keyBase = "com.revenuecat.userdefaults."
        static let customerInfoAppUserDefaults = "\(keyBase)purchaserInfo."
        static let customerInfoLastUpdated = "\(keyBase)purchaserInfoLastUpdated."
        static let legacySubscriberAttributes = "\(keyBase)subscriberAttributes."
        static let attributionDataDefaults = "\(keyBase)attribution."

    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
// - It contains `NotificationCenter`, which isn't thread-safe as of Swift 5.7.
extension DeviceCache: @unchecked Sendable {}

// MARK: - Private

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

    static func store(
        _ userDefaults: UserDefaults,
        subscriberAttributesByKey: [String: SubscriberAttribute],
        appUserID: String
    ) {
        var groupedSubscriberAttributes = Self.storedAttributesForAllUsers(userDefaults)
        var subscriberAttributesForAppUserID = groupedSubscriberAttributes[appUserID] as? [String: Any] ?? [:]
        for (key, attributes) in subscriberAttributesByKey {
            subscriberAttributesForAppUserID[key] = attributes.asDictionary()
        }
        groupedSubscriberAttributes[appUserID] = subscriberAttributesForAppUserID
        userDefaults.setValue(groupedSubscriberAttributes, forKey: .subscriberAttributes)
    }

    static func deleteAllAttributes(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) {
        var groupedAttributes = Self.storedAttributesForAllUsers(userDefaults)
        let attributesForAppUserID = groupedAttributes.removeValue(forKey: appUserID)
        guard attributesForAppUserID != nil else {
            Logger.warn(Strings.identity.deleting_attributes_none_found)
            return
        }
        userDefaults.setValue(groupedAttributes, forKey: .subscriberAttributes)
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
            if let dictionary = attributeDict as? [String: Any],
                let attribute = SubscriberAttribute(dictionary: dictionary) {
                allSubscriberAttributesByKey[key] = attribute
            }
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
                if let attribute = SubscriberAttribute(dictionary: storedAttributesForUser), !attribute.isSynced {
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

private extension DeviceCache {

    enum CacheDuration {

        // swiftlint:disable:next nesting
        enum AppStatus {

            case foreground
            case background

            init(backgrounded: Bool) {
                self = backgrounded ? .background : .foreground
            }

        }

        // swiftlint:disable:next nesting
        enum Environment {

            case production
            case sandbox

            init(sandbox: Bool) {
                self = sandbox ? .sandbox : .production
            }

        }

        static func duration(status: AppStatus, environment: Environment) -> TimeInterval {
            switch (environment, status) {
            case (.production, .foreground): return 60 * 5.0
            case (.production, .background): return 60 * 60 * 25.0

            case (.sandbox, .foreground): return 60 * 5.0
            case (.sandbox, .background): return 60 * 5.0
            }
        }

    }

}

// swiftlint:enable file_length
