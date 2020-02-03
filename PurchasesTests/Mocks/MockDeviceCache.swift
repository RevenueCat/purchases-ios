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
    var clearCachesCalledUserID: String? = nil

    override func clearCaches(forAppUserID appUserId: String) {
        clearCachesCalledUserID = appUserId
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
    var purchaserInfoCacheResetCount = 0
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

    override func isPurchaserInfoCacheStale() -> Bool {
        return stubbedIsPurchaserInfoCacheStale
    }

    override func clearPurchaserInfoCacheTimestamp() {
        clearPurchaserInfoCacheTimestampCount += 1
    }

    override func setPurchaserInfoCacheTimestampToNow() {
        setPurchaserInfoCacheTimestampToNowCount += 1
    }

    // MARK: offerings

    var cacheOfferingsCount = 0
    var cachedOfferingsCount = 0
    var offeringsCacheResetCount = 0
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

    override func isOfferingsCacheStale() -> Bool {
        return stubbedIsOfferingsCacheStale
    }

    override func clearOfferingsCacheTimestamp() {
        clearOfferingsCacheTimestampCount += 1
    }

    override func setOfferingsCacheTimestampToNow() {
        setOfferingsCacheTimestampToNowCount += 1
    }
}