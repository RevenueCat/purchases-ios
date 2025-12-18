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

    var cachedAppUserID: String? { return self._cachedAppUserID.value }
    var cachedLegacyAppUserID: String? { return self._cachedLegacyAppUserID.value }
    var cachedOfferings: Offerings? { self.offeringsCachedObject.cachedInstance }

    private let sandboxEnvironmentDetector: SandboxEnvironmentDetector
    private let userDefaults: SynchronizedUserDefaults
    private let offeringsCachedObject: InMemoryCachedObject<Offerings>

    private let _cachedAppUserID: Atomic<String?>
    private let _cachedLegacyAppUserID: Atomic<String?>

    private var userDefaultsObserver: NSObjectProtocol?

    init(sandboxEnvironmentDetector: SandboxEnvironmentDetector,
         userDefaults: UserDefaults,
         offeringsCachedObject: InMemoryCachedObject<Offerings> = .init()) {
        self.sandboxEnvironmentDetector = sandboxEnvironmentDetector
        self.offeringsCachedObject = offeringsCachedObject
        self.userDefaults = .init(userDefaults: userDefaults)
        self._cachedAppUserID = .init(userDefaults.string(forKey: CacheKeys.appUserDefaults))
        self._cachedLegacyAppUserID = .init(userDefaults.string(forKey: CacheKeys.legacyGeneratedAppUserDefaults))

        Logger.verbose(Strings.purchase.device_cache_init(self))
    }

    deinit {
        Logger.verbose(Strings.purchase.device_cache_deinit(self))
    }

    // MARK: - generic methods

    func update<Key: DeviceCacheKeyType, Value: Codable>(
        key: Key,
        default defaultValue: Value,
        updater: @Sendable (inout Value) -> Void
    ) {
        self.userDefaults.write {
            var value: Value = $0.value(forKey: key) ?? defaultValue
            updater(&value)
            $0.set(codable: value, forKey: key)
        }
    }

    func value<Key: DeviceCacheKeyType, Value: Codable>(for key: Key) -> Value? {
        self.userDefaults.read {
            $0.value(forKey: key)
        }
    }

    // MARK: - appUserID

    func cache(appUserID: String) {
        self.userDefaults.write {
            $0.set(appUserID, forKey: CacheKeys.appUserDefaults)
        }
        self._cachedAppUserID.value = appUserID
    }

    func clearCaches(oldAppUserID: String, andSaveWithNewUserID newUserID: String) {
        self.userDefaults.write { userDefaults in
            userDefaults.removeObject(forKey: CacheKeys.legacyGeneratedAppUserDefaults)
            userDefaults.removeObject(
                forKey: CacheKey.customerInfo(oldAppUserID)
            )

            // Clear CustomerInfo cache timestamp for oldAppUserID.
            userDefaults.removeObject(forKey: CacheKey.customerInfoLastUpdated(oldAppUserID))

            // Clear offerings cache.
            self.offeringsCachedObject.clearCache()
            userDefaults.removeObject(forKey: CacheKey.offerings(oldAppUserID))

            // Delete attributes if synced for the old app user id.
            if Self.unsyncedAttributesByKey(userDefaults, appUserID: oldAppUserID).isEmpty {
                var attributes = Self.storedAttributesForAllUsers(userDefaults)
                attributes.removeValue(forKey: oldAppUserID)
                userDefaults.set(attributes, forKey: CacheKeys.subscriberAttributes)
            }

            // Cache new appUserID.
            userDefaults.set(newUserID, forKey: CacheKeys.appUserDefaults)
            self._cachedAppUserID.value = newUserID
            self._cachedLegacyAppUserID.value = nil
        }
    }

    // MARK: - CustomerInfo

    func cachedCustomerInfoData(appUserID: String) -> Data? {
        return self.userDefaults.read {
            $0.data(forKey: CacheKey.customerInfo(appUserID))
        }
    }

    func cache(customerInfo: Data, appUserID: String) {
        self.userDefaults.write {
            $0.set(customerInfo, forKey: CacheKey.customerInfo(appUserID))
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
            $0.removeObject(forKey: CacheKey.customerInfo(appUserID))
        }
    }

    // MARK: - Offerings

    func cachedOfferingsResponseData(appUserID: String) -> Data? {
        return self.userDefaults.read {
            $0.data(forKey: CacheKey.offerings(appUserID))
        }
    }

    func cache(offerings: Offerings, appUserID: String) {
        self.cacheInMemory(offerings: offerings)
        self.userDefaults.write {
            $0.set(codable: offerings.response, forKey: CacheKey.offerings(appUserID))
        }
    }

    func cacheInMemory(offerings: Offerings) {
        self.offeringsCachedObject.cache(instance: offerings)
    }

    func clearOfferingsCache(appUserID: String) {
        self.offeringsCachedObject.clearCache()
        self.userDefaults.write {
            $0.removeObject(forKey: CacheKey.offerings(appUserID))
        }
    }

    func isOfferingsCacheStale(isAppBackgrounded: Bool) -> Bool {
        return self.offeringsCachedObject.isCacheStale(
            durationInSeconds: self.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded,
                                                           isSandbox: self.sandboxEnvironmentDetector.isSandbox)
        )
    }

    func clearOfferingsCacheTimestamp() {
        self.offeringsCachedObject.clearCacheTimestamp()
    }

    func offeringsCacheStatus(isAppBackgrounded: Bool) -> CacheStatus {
        if self.offeringsCachedObject.cachedInstance == nil {
            return .notFound
        } else if self.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded) {
            return .stale
        } else {
            return .valid
        }
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
            let key = CacheKey.attributionDataDefaults(appUserID)
            let latestAdvertisingIdsByRawNetworkSent = $0.object(forKey: key.rawValue) as? [String: String] ?? [:]

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
            $0.set(latestAdIdsByRawNetworkStringSent,
                   forKey: CacheKey.attributionDataDefaults(appUserID))
        }
    }

    func clearLatestNetworkAndAdvertisingIdsSent(appUserID: String) {
        self.userDefaults.write {
            $0.removeObject(forKey: CacheKey.attributionDataDefaults(appUserID))
        }
    }

    private func cacheDurationInSeconds(isAppBackgrounded: Bool, isSandbox: Bool) -> TimeInterval {
        return CacheDuration.duration(status: .init(backgrounded: isAppBackgrounded),
                                      environment: .init(sandbox: isSandbox))
    }

    // MARK: - Products Entitlements

    var isProductEntitlementMappingCacheStale: Bool {
        return self.userDefaults.read {
            guard let cacheLastUpdated = Self.productEntitlementMappingLastUpdated($0) else {
                return true
            }

            let cacheAge = Date().timeIntervalSince(cacheLastUpdated)
            return cacheAge > DeviceCache.productEntitlementMappingCacheDuration.seconds
        }
    }

    func store(productEntitlementMapping: ProductEntitlementMapping) {
        self.userDefaults.write {
            Self.store($0, productEntitlementMapping: productEntitlementMapping)
        }
    }

    var cachedProductEntitlementMapping: ProductEntitlementMapping? {
        return self.userDefaults.read(Self.productEntitlementMapping)
    }

    // MARK: - StoreKit 2
    private let cachedSyncedSK2ObserverModeTransactionIDsLock = Lock(.nonRecursive)

    func registerNewSyncedSK2ObserverModeTransactionIDs(_ ids: [UInt64]) {
        cachedSyncedSK2ObserverModeTransactionIDsLock.perform {
            var transactionIDs = self.userDefaults.read { userDefaults in
                userDefaults.array(
                    forKey: CacheKey.syncedSK2ObserverModeTransactionIDs.rawValue) as? [UInt64]
            } ?? []

            transactionIDs.append(contentsOf: ids)

            self.userDefaults.write {
                $0.set(
                    transactionIDs,
                    forKey: CacheKey.syncedSK2ObserverModeTransactionIDs
                )
            }
        }
    }

    func cachedSyncedSK2ObserverModeTransactionIDs() -> [UInt64] {
        cachedSyncedSK2ObserverModeTransactionIDsLock.perform {
            return self.userDefaults.read { userDefaults in
                userDefaults.array(
                    forKey: CacheKey.syncedSK2ObserverModeTransactionIDs.rawValue) as? [UInt64] ?? []
            }
        }
    }

    // MARK: - Helper functions

    internal enum CacheKeys: String, DeviceCacheKeyType {

        case legacyGeneratedAppUserDefaults = "com.revenuecat.userdefaults.appUserID"
        case appUserDefaults = "com.revenuecat.userdefaults.appUserID.new"
        case subscriberAttributes = "com.revenuecat.userdefaults.subscriberAttributes"
        case productEntitlementMapping = "com.revenuecat.userdefaults.productEntitlementMapping"
        case productEntitlementMappingLastUpdated = "com.revenuecat.userdefaults.productEntitlementMappingLastUpdated"

    }

    fileprivate enum CacheKey: DeviceCacheKeyType {

        static let base = "com.revenuecat.userdefaults."
        static let legacySubscriberAttributesBase = "\(Self.base)subscriberAttributes."

        case customerInfo(String)
        case customerInfoLastUpdated(String)
        case offerings(String)
        case legacySubscriberAttributes(String)
        case attributionDataDefaults(String)
        case syncedSK2ObserverModeTransactionIDs

        var rawValue: String {
            switch self {
            case let .customerInfo(userID): return "\(Self.base)purchaserInfo.\(userID)"
            case let .customerInfoLastUpdated(userID): return "\(Self.base)purchaserInfoLastUpdated.\(userID)"
            case let .offerings(userID): return "\(Self.base)offerings.\(userID)"
            case let .legacySubscriberAttributes(userID): return "\(Self.legacySubscriberAttributesBase)\(userID)"
            case let .attributionDataDefaults(userID): return "\(Self.base)attribution.\(userID)"
            case .syncedSK2ObserverModeTransactionIDs:
                return "\(Self.base)syncedSK2ObserverModeTransactionIDs"
            }
        }

    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension DeviceCache: @unchecked Sendable {}

// MARK: -

extension DeviceCache: ProductEntitlementMappingFetcher {

    var productEntitlementMapping: ProductEntitlementMapping? {
        return self.cachedProductEntitlementMapping
    }

}

// MARK: - Private

// All methods that modify or read from the UserDefaults data source but require external mechanisms for ensuring
// mutual exclusion.
private extension DeviceCache {

    static func appUserIDsWithLegacyAttributes(_ userDefaults: UserDefaults) -> [String] {
        var appUserIDsWithLegacyAttributes: [String] = []

        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for key in userDefaultsDict.keys where key.starts(with: CacheKey.base) {
            let appUserID = key.replacingOccurrences(of: CacheKey.legacySubscriberAttributesBase, with: "")
            appUserIDsWithLegacyAttributes.append(appUserID)
        }

        return appUserIDsWithLegacyAttributes
    }

    static func cachedAppUserID(_ userDefaults: UserDefaults) -> String? {
        userDefaults.string(forKey: CacheKeys.appUserDefaults)
    }

    static func storedAttributesForAllUsers(_ userDefaults: UserDefaults) -> [String: Any] {
        let attributes = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes) ?? [:]
        return attributes
    }

    static func customerInfoLastUpdated(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) -> Date? {
        return userDefaults.date(forKey: CacheKey.customerInfoLastUpdated(appUserID))
    }

    static func clearCustomerInfoCacheTimestamp(
        _ userDefaults: UserDefaults,
        appUserID: String
    ) {
        userDefaults.removeObject(forKey: CacheKey.customerInfoLastUpdated(appUserID))
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
        userDefaults.set(groupedSubscriberAttributes, forKey: CacheKeys.subscriberAttributes)
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
        userDefaults.set(groupedAttributes, forKey: CacheKeys.subscriberAttributes)
    }

    static func setCustomerInfoCache(
        _ userDefaults: UserDefaults,
        timestamp: Date,
        appUserID: String
    ) {
        userDefaults.set(timestamp, forKey: CacheKey.customerInfoLastUpdated(appUserID))
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
                forKey: CacheKey.legacySubscriberAttributes(appUserID)) ?? [:]
            let existingAttributes = Self.subscriberAttributes(userDefaults,
                                                               appUserID: appUserID)
            let allAttributesForUser = legacyAttributes.merging(existingAttributes)
            attributesInNewFormat[appUserID] = allAttributesForUser

            userDefaults.removeObject(forKey: CacheKey.legacySubscriberAttributes(appUserID))

        }
        userDefaults.set(attributesInNewFormat, forKey: CacheKeys.subscriberAttributes)
    }

    static func deleteSyncedSubscriberAttributesForOtherUsers(
        _ userDefaults: UserDefaults
    ) {
        let allStoredAttributes: [String: [String: Any]]
        = userDefaults.dictionary(forKey: CacheKeys.subscriberAttributes)
        as? [String: [String: Any]] ?? [:]

        var filteredAttributes: [String: Any] = [:]

        // swiftlint:disable:next force_unwrapping
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

        userDefaults.set(filteredAttributes, forKey: CacheKeys.subscriberAttributes)
    }

    static func productEntitlementMappingLastUpdated(_ userDefaults: UserDefaults) -> Date? {
        return userDefaults.date(forKey: CacheKeys.productEntitlementMappingLastUpdated)
    }

    static func productEntitlementMapping(_ userDefaults: UserDefaults) -> ProductEntitlementMapping? {
        return userDefaults.value(forKey: CacheKeys.productEntitlementMapping)
    }

    static func store(
        _ userDefaults: UserDefaults,
        productEntitlementMapping mapping: ProductEntitlementMapping
    ) {
        if userDefaults.set(codable: mapping,
                            forKey: CacheKeys.productEntitlementMapping) {
            userDefaults.set(Date(), forKey: CacheKeys.productEntitlementMappingLastUpdated)
        }
    }

}

fileprivate extension UserDefaults {

    /// - Returns: whether the value could be saved
    @discardableResult
    func set<T: Codable>(codable: T, forKey key: DeviceCacheKeyType) -> Bool {
        guard let data = try? JSONEncoder.default.encode(value: codable, logErrors: true) else {
            return false
        }

        self.set(data, forKey: key)
        return true
    }

    func value<T: Decodable>(forKey key: DeviceCacheKeyType) -> T? {
        guard let data = self.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder.default.decode(jsonData: data, logErrors: true)
    }

    func set(_ value: Any?, forKey key: DeviceCacheKeyType) {
        self.set(value, forKey: key.rawValue)
    }

    func string(forKey defaultName: DeviceCacheKeyType) -> String? {
        return self.string(forKey: defaultName.rawValue)
    }

    func removeObject(forKey defaultName: DeviceCacheKeyType) {
        self.removeObject(forKey: defaultName.rawValue)
    }

    func dictionary(forKey defaultName: DeviceCacheKeyType) -> [String: Any]? {
        return self.dictionary(forKey: defaultName.rawValue)
    }

    func date(forKey defaultName: DeviceCacheKeyType) -> Date? {
        return self.object(forKey: defaultName.rawValue) as? Date
    }

    func data(forKey key: DeviceCacheKeyType) -> Data? {
        return self.data(forKey: key.rawValue)
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

    static let productEntitlementMappingCacheDuration: DispatchTimeInterval = .hours(25)

}

protocol DeviceCacheKeyType {

    var rawValue: String { get }

}
