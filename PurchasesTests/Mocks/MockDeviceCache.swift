//
//  Created by RevenueCat.
//  Copyright © 2020 RevenueCat. All rights reserved.
//

import Purchases

class MockDeviceCache: RCDeviceCache {

    // MARK: appUserID

    var stubbedAppUserID: String? = nil
    var stubbedLegacyAppUserID: String? = nil
    var userIDStoredInCache: String? = nil
    var stubbedAnonymous: Bool = false
    var clearCachesCalledOldUserID: String? = nil
    var clearCachesCalleNewUserID: String? = nil
    var invokedClearCachesForAppUserID: Bool = false

    override func clearCaches(forAppUserID oldUserId: String, andSaveNewUserID newUserID: String) {
        clearCachesCalledOldUserID = oldUserId
        clearCachesCalleNewUserID = newUserID
        userIDStoredInCache = newUserID
        invokedClearCachesForAppUserID = true
    }

    override var cachedLegacyAppUserID: String? {
        return stubbedLegacyAppUserID
    }

    override var cachedAppUserID: String? {
        if (stubbedAppUserID != nil) {
            return stubbedAppUserID
        } else {
            return userIDStoredInCache
        }
    }

    override func cacheAppUserID(_ appUserID: String) {
        userIDStoredInCache = appUserID
    }

    // MARK: purchaserInfo
    var cachePurchaserInfoCount = 0
    var cachedPurchaserInfoCount = 0
    var clearPurchaserInfoCacheTimestampCount = 0
    var setPurchaserInfoCacheTimestampToNowCount = 0
    var stubbedIsPurchaserInfoCacheStale = false
    var cachedPurchaserInfo = [String: Data]()

    override func cachePurchaserInfo(_ data: Data, forAppUserID appUserID: String) {
        cachePurchaserInfoCount += 1
        cachedPurchaserInfo[appUserID] = data as Data?
    }

    override func cachedPurchaserInfoData(forAppUserID appUserID: Swift.String) -> Data? {
        cachedPurchaserInfoCount += 1
        return cachedPurchaserInfo[appUserID];
    }

    override func isPurchaserInfoCacheStale(forAppUserID appUserID: String,
                                            isAppBackgrounded: Bool) -> Bool {
        return stubbedIsPurchaserInfoCacheStale
    }

    override func clearPurchaserInfoCacheTimestamp(forAppUserID appUserID: String) {
        clearPurchaserInfoCacheTimestampCount += 1
    }

    override func setPurchaserInfoCacheTimestampToNowForAppUserID(_ appUserID: String) {
        setPurchaserInfoCacheTimestampToNowCount += 1
    }

    // MARK: offerings

    var cacheOfferingsCount = 0
    var cachedOfferingsCount = 0
    var clearOfferingsCacheTimestampCount = 0
    var setOfferingsCacheTimestampToNowCount = 0
    var stubbedIsOfferingsCacheStale = false
    var stubbedOfferings: Purchases.Offerings?

    override var cachedOfferings: Purchases.Offerings? {
        return stubbedOfferings
    }

    override func cacheOfferings(_ offerings: Purchases.Offerings) {
        cachedOfferingsCount += 1
    }

    override func isOfferingsCacheStale(withIsAppBackgrounded isAppBackgrounded: Bool) -> Bool {
        return stubbedIsOfferingsCacheStale
    }

    override func clearOfferingsCacheTimestamp() {
        clearOfferingsCacheTimestampCount += 1
    }

    override func setOfferingsCacheTimestampToNow() {
        setOfferingsCacheTimestampToNowCount += 1
    }

    // MARK: SubscriberAttributes

    var invokedStore = false
    var invokedStoreCount = 0
    var invokedStoreParameters: (attribute: RCSubscriberAttribute, appUserID: String)?
    var invokedStoreParametersList = [(attribute: RCSubscriberAttribute, appUserID: String)]()

    override func store(_ attribute: RCSubscriberAttribute, appUserID: String) {
        invokedStore = true
        invokedStoreCount += 1
        invokedStoreParameters = (attribute, appUserID)
        invokedStoreParametersList.append((attribute, appUserID))
    }

    var invokedStoreSubscriberAttributes = false
    var invokedStoreSubscriberAttributesCount = 0
    var invokedStoreSubscriberAttributesParameters: (attributesByKey: [String: RCSubscriberAttribute], appUserID: String)?
    var invokedStoreSubscriberAttributesParametersList = [(attributesByKey: [String: RCSubscriberAttribute],
        appUserID: String)]()

    override func storeSubscriberAttributes(_ attributesByKey: [String: RCSubscriberAttribute],
                                            appUserID: String) {
        invokedStoreSubscriberAttributes = true
        invokedStoreSubscriberAttributesCount += 1
        invokedStoreSubscriberAttributesParameters = (attributesByKey, appUserID)
        invokedStoreSubscriberAttributesParametersList.append((attributesByKey, appUserID))
    }

    var invokedSubscriberAttribute = false
    var invokedSubscriberAttributeCount = 0
    var invokedSubscriberAttributeParameters: (attributeKey: String, appUserID: String)?
    var invokedSubscriberAttributeParametersList = [(attributeKey: String, appUserID: String)]()
    var stubbedSubscriberAttributeResult: RCSubscriberAttribute!

    override func subscriberAttribute(withKey attributeKey: String,
                                      appUserID: String) -> RCSubscriberAttribute? {
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
    var stubbedUnsyncedAttributesByKeyResult: [String: RCSubscriberAttribute]! = [:]

    override func unsyncedAttributesByKey(forAppUserID appUserID: String) -> [String: RCSubscriberAttribute] {
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
    var stubbedNumberOfUnsyncedAttributesResult: UInt! = 0

    override func numberOfUnsyncedAttributes(forAppUserID appUserID: String) -> UInt {
        invokedNumberOfUnsyncedAttributes = true
        invokedNumberOfUnsyncedAttributesCount += 1
        invokedNumberOfUnsyncedAttributesParameters = (appUserID, ())
        invokedNumberOfUnsyncedAttributesParametersList.append((appUserID, ()))
        return stubbedNumberOfUnsyncedAttributesResult
    }

    var invokedUnsyncedAttributesForAllUsers = false
    var invokedUnsyncedAttributesForAllUsersCount = 0
    var stubbedUnsyncedAttributesForAllUsersResult: [String: [String: RCSubscriberAttribute]]!

    override func unsyncedAttributesForAllUsers() -> [String: [String: RCSubscriberAttribute]] {
        invokedUnsyncedAttributesForAllUsers = true
        invokedUnsyncedAttributesForAllUsersCount += 1
        return stubbedUnsyncedAttributesForAllUsersResult
    }

    var invokedDeleteAttributesIfSynced = false
    var invokedDeleteAttributesIfSyncedCount = 0
    var invokedDeleteAttributesIfSyncedParameters: (appUserID: String?, Void)?
    var invokedDeleteAttributesIfSyncedParametersList: [String] = []

    override func deleteAttributesIfSynced(forAppUserID appUserID: String) {
        invokedDeleteAttributesIfSynced = true
        invokedDeleteAttributesIfSyncedCount += 1
        invokedDeleteAttributesIfSyncedParameters = (appUserID, ())
        invokedDeleteAttributesIfSyncedParametersList.append(appUserID)
    }

    var invokedClearPurchaserInfoCache = false
    var invokedClearPurchaserInfoCacheCount = 0
    var invokedClearPurchaserInfoCacheParameters: (appUserID: String, Void)?
    var invokedClearPurchaserInfoCacheParametersList = [(appUserID: String, Void)]()

    override func clearPurchaserInfoCache(forAppUserID appUserID: String) {
        cachedPurchaserInfo.removeValue(forKey: appUserID)
        invokedClearPurchaserInfoCache = true
        invokedClearPurchaserInfoCacheCount += 1
        invokedClearPurchaserInfoCacheParameters = (appUserID, ())
        invokedClearPurchaserInfoCacheParametersList.append((appUserID, ()))
    }

    var invokedClearLatestNetworkAndAdvertisingIdsSent = false
    var invokedClearLatestNetworkAndAdvertisingIdsSentCount = 0
    var invokedClearLatestNetworkAndAdvertisingIdsSentParameters: (appUserID: String?, Void)?
    var invokedClearLatestNetworkAndAdvertisingIdsSentParametersList = [(appUserID: String?, Void)]()

    override func clearLatestNetworkAndAdvertisingIdsSent(forAppUserID appUserID: String?) {
        invokedClearLatestNetworkAndAdvertisingIdsSent = true
        invokedClearLatestNetworkAndAdvertisingIdsSentCount += 1
        invokedClearLatestNetworkAndAdvertisingIdsSentParameters = (appUserID, ())
        invokedClearLatestNetworkAndAdvertisingIdsSentParametersList.append((appUserID, ()))
    }
}
