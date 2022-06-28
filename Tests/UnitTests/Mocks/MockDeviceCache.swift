//
//  Created by RevenueCat.
//  Copyright © 2020 RevenueCat. All rights reserved.
//

@testable import RevenueCat

class MockDeviceCache: DeviceCache {

    // MARK: appUserID

    var stubbedAppUserID: String?
    var stubbedLegacyAppUserID: String?
    var userIDStoredInCache: String?
    var stubbedAnonymous: Bool = false
    var clearCachesCalledOldUserID: String?
    var clearCachesCalleNewUserID: String?
    var invokedClearCachesForAppUserID: Bool = false

    override func clearCaches(oldAppUserID: String, andSaveWithNewUserID newUserID: String) {
        clearCachesCalledOldUserID = oldAppUserID
        clearCachesCalleNewUserID = newUserID
        userIDStoredInCache = newUserID
        invokedClearCachesForAppUserID = true
    }

    override var cachedLegacyAppUserID: String? {
        return stubbedLegacyAppUserID
    }

    override var cachedAppUserID: String? {
        if stubbedAppUserID != nil {
            return stubbedAppUserID
        } else {
            return userIDStoredInCache
        }
    }

    override func cache(appUserID: String) {
        userIDStoredInCache = appUserID
    }

    // MARK: customerInfo
    var cacheCustomerInfoCount = 0
    var cachedCustomerInfoCount = 0
    var clearCustomerInfoCacheTimestampCount = 0
    var setCustomerInfoCacheTimestampToNowCount = 0
    var stubbedIsCustomerInfoCacheStale = false
    var cachedCustomerInfo = [String: Data]()

    override func cache(customerInfo: Data, appUserID: String) {
        cacheCustomerInfoCount += 1
        cachedCustomerInfo[appUserID] = customerInfo as Data?
    }

    override func cachedCustomerInfoData(appUserID: String) -> Data? {
        cachedCustomerInfoCount += 1
        return cachedCustomerInfo[appUserID]
    }

    override func isCustomerInfoCacheStale(appUserID: String, isAppBackgrounded: Bool) -> Bool {
        return stubbedIsCustomerInfoCacheStale
    }

    override func clearCustomerInfoCacheTimestamp(appUserID: String) {
        clearCustomerInfoCacheTimestampCount += 1
    }

    override func setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: String) {
        setCustomerInfoCacheTimestampToNowCount += 1
    }

    // MARK: offerings

    var cacheOfferingsCount = 0
    var clearCachedOfferingsCount = 0
    var clearOfferingsCacheTimestampCount = 0
    var setOfferingsCacheTimestampToNowCount = 0
    var stubbedIsOfferingsCacheStale = false
    var stubbedOfferings: Offerings?

    override var cachedOfferings: Offerings? {
        return stubbedOfferings
    }

    override func cache(offerings: Offerings) {
        cacheOfferingsCount += 1
    }

    override func isOfferingsCacheStale(isAppBackgrounded: Bool) -> Bool {
        return stubbedIsOfferingsCacheStale
    }

    override func clearOfferingsCacheTimestamp() {
        clearOfferingsCacheTimestampCount += 1
    }

    override func setOfferingsCacheTimestampToNow() {
        setOfferingsCacheTimestampToNowCount += 1
    }

    override func clearCachedOfferings() {
        clearCachedOfferingsCount += 1
    }

    // MARK: SubscriberAttributes

    var invokedStore = false
    var invokedStoreCount = 0
    var invokedStoreParameters: (attribute: SubscriberAttribute, appUserID: String)?
    var invokedStoreParametersList = [(attribute: SubscriberAttribute, appUserID: String)]()

    override func store(subscriberAttribute: SubscriberAttribute, appUserID: String) {
        invokedStore = true
        invokedStoreCount += 1
        invokedStoreParameters = (subscriberAttribute, appUserID)
        invokedStoreParametersList.append((subscriberAttribute, appUserID))
    }

    var invokedStoreSubscriberAttributes = false
    var invokedStoreSubscriberAttributesCount = 0
    var invokedStoreSubscriberAttributesParameters: (attributesByKey: [String: SubscriberAttribute], appUserID: String)?
    var invokedStoreSubscriberAttributesParametersList = [(attributesByKey: [String: SubscriberAttribute],
        appUserID: String)]()

    override func store(subscriberAttributesByKey: [String: SubscriberAttribute], appUserID: String) {
        invokedStoreSubscriberAttributes = true
        invokedStoreSubscriberAttributesCount += 1
        invokedStoreSubscriberAttributesParameters = (subscriberAttributesByKey, appUserID)
        invokedStoreSubscriberAttributesParametersList.append((subscriberAttributesByKey, appUserID))
    }

    var invokedSubscriberAttribute = false
    var invokedSubscriberAttributeCount = 0
    var invokedSubscriberAttributeParameters: (attributeKey: String, appUserID: String)?
    var invokedSubscriberAttributeParametersList = [(attributeKey: String, appUserID: String)]()
    var stubbedSubscriberAttributeResult: SubscriberAttribute!

    override func subscriberAttribute(attributeKey: String, appUserID: String) -> SubscriberAttribute? {
        invokedSubscriberAttribute = true
        invokedSubscriberAttributeCount += 1
        invokedSubscriberAttributeParameters = (attributeKey, appUserID)
        invokedSubscriberAttributeParametersList.append((attributeKey, appUserID))
        return stubbedSubscriberAttributeResult
    }

    var invokedUnsyncedAttributesByKey = false
    var invokedUnsyncedAttributesByKeyCount = 0
    var invokedUnsyncedAttributesByKeyParameters: (appUserID: String, Void)?
    var invokedUnsyncedAttributesByKeyParametersList = [(appUserID: String, Void)]()
    var stubbedUnsyncedAttributesByKeyResult: [String: SubscriberAttribute]! = [:]

    override func unsyncedAttributesByKey(appUserID: String) -> [String: SubscriberAttribute] {
        invokedUnsyncedAttributesByKey = true
        invokedUnsyncedAttributesByKeyCount += 1
        invokedUnsyncedAttributesByKeyParameters = (appUserID, ())
        invokedUnsyncedAttributesByKeyParametersList.append((appUserID, ()))
        return stubbedUnsyncedAttributesByKeyResult
    }

    var invokedCleanupSubscriberAttributes = false
    var invokedCleanupSubscriberAttributesCount = 0

    override func cleanupSubscriberAttributes() {
        invokedCleanupSubscriberAttributes = true
        invokedCleanupSubscriberAttributesCount += 1
    }

    var invokedNumberOfUnsyncedAttributes = false
    var invokedNumberOfUnsyncedAttributesCount = 0
    var invokedNumberOfUnsyncedAttributesParameters: (appUserID: String, Void)?
    var invokedNumberOfUnsyncedAttributesParametersList = [(appUserID: String, Void)]()
    var stubbedNumberOfUnsyncedAttributesResult: Int! = 0

    override func numberOfUnsyncedAttributes(appUserID: String) -> Int {
        invokedNumberOfUnsyncedAttributes = true
        invokedNumberOfUnsyncedAttributesCount += 1
        invokedNumberOfUnsyncedAttributesParameters = (appUserID, ())
        invokedNumberOfUnsyncedAttributesParametersList.append((appUserID, ()))
        return stubbedNumberOfUnsyncedAttributesResult
    }

    var invokedUnsyncedAttributesForAllUsers = false
    var invokedUnsyncedAttributesForAllUsersCount = 0
    var stubbedUnsyncedAttributesForAllUsersResult: [String: [String: SubscriberAttribute]]!

    override func unsyncedAttributesForAllUsers() -> [String: [String: SubscriberAttribute]] {
        invokedUnsyncedAttributesForAllUsers = true
        invokedUnsyncedAttributesForAllUsersCount += 1
        return stubbedUnsyncedAttributesForAllUsersResult
    }

    var invokedDeleteAttributesIfSynced = false
    var invokedDeleteAttributesIfSyncedCount = 0
    var invokedDeleteAttributesIfSyncedParameters: (appUserID: String?, Void)?
    var invokedDeleteAttributesIfSyncedParametersList: [String] = []

    override func deleteAttributesIfSynced(appUserID: String) {
        invokedDeleteAttributesIfSynced = true
        invokedDeleteAttributesIfSyncedCount += 1
        invokedDeleteAttributesIfSyncedParameters = (appUserID, ())
        invokedDeleteAttributesIfSyncedParametersList.append(appUserID)
    }

    var invokedClearCustomerInfoCache = false
    var invokedClearCustomerInfoCacheCount = 0
    var invokedClearCustomerInfoCacheParameters: (appUserID: String, Void)?
    var invokedClearCustomerInfoCacheParametersList = [(appUserID: String, Void)]()

    override func clearCustomerInfoCache(appUserID: String) {
        cachedCustomerInfo.removeValue(forKey: appUserID)
        invokedClearCustomerInfoCache = true
        invokedClearCustomerInfoCacheCount += 1
        invokedClearCustomerInfoCacheParameters = (appUserID, ())
        invokedClearCustomerInfoCacheParametersList.append((appUserID, ()))
    }

    var invokedClearLatestNetworkAndAdvertisingIdsSent = false
    var invokedClearLatestNetworkAndAdvertisingIdsSentCount = 0
    var invokedClearLatestNetworkAndAdvertisingIdsSentParameters: (appUserID: String?, Void)?
    var invokedClearLatestNetworkAndAdvertisingIdsSentParametersList = [(appUserID: String?, Void)]()

    override func clearLatestNetworkAndAdvertisingIdsSent(appUserID: String?) {
        invokedClearLatestNetworkAndAdvertisingIdsSent = true
        invokedClearLatestNetworkAndAdvertisingIdsSentCount += 1
        invokedClearLatestNetworkAndAdvertisingIdsSentParameters = (appUserID, ())
        invokedClearLatestNetworkAndAdvertisingIdsSentParametersList.append((appUserID, ()))
    }

    var invokedSetLatestNetworkAndAdvertisingIdsSent = false
    var invokedSetLatestNetworkAndAdvertisingIdsSentCount = 0
    var invokedSetLatestNetworkAndAdvertisingIdsSentParameters:
        (adIdsByNetwork: [AttributionNetwork: String], appUserID: String?)?
    var invokedSetLatestNetworkAndAdvertisingIdsSentParametersList =
        [(adIdsByNetwork: [AttributionNetwork: String], appUserID: String?)]()

    override func set(latestAdvertisingIdsByNetworkSent: [AttributionNetwork: String], appUserID: String) {
        invokedSetLatestNetworkAndAdvertisingIdsSent = true
        invokedSetLatestNetworkAndAdvertisingIdsSentCount += 1
        invokedSetLatestNetworkAndAdvertisingIdsSentParameters = (latestAdvertisingIdsByNetworkSent, appUserID)
        invokedSetLatestNetworkAndAdvertisingIdsSentParametersList.append(
            (latestAdvertisingIdsByNetworkSent, appUserID)
        )
    }

    override func latestAdvertisingIdsByNetworkSent(appUserID: String) -> [AttributionNetwork: String] {
        return invokedSetLatestNetworkAndAdvertisingIdsSentParameters?.adIdsByNetwork ?? [:]
    }

}
