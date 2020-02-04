//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class DeviceCacheTests: XCTestCase {

    private var mockUserDefaults: MockUserDefaults! = nil

    private var deviceCache: RCDeviceCache! = nil

    override func setUp() {
        self.mockUserDefaults = MockUserDefaults()
        self.deviceCache = RCDeviceCache(mockUserDefaults)
    }

    func testLegacyCachedUserIDUsesRightKey() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "cesar"
        let userID: String? = self.deviceCache.cachedLegacyAppUserID
        expect(userID).to(equal("cesar"))
    }

    func testCachedUserIDUsesRightKey() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = "cesar"
        let userID: String? = self.deviceCache.cachedAppUserID
        expect(userID).to(equal("cesar"))
    }

    func testCacheUserIDUsesRightKey() {
        let userID = "cesar"
        self.deviceCache.cacheAppUserID(userID)
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] as? String).to(equal(userID))
    }

    func testClearCachesRemovesCachedPurchaserInfo() {
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.purchaserInfo.cesar")).to(beTrue())
    }

    func testClearCachesRemovesCachedOfferings() {
        let offerings = Purchases.Offerings()
        self.deviceCache.cacheOfferings(offerings)
        expect(self.deviceCache.cachedOfferings).to(equal(offerings))
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.deviceCache.cachedOfferings).to(beNil())
    }

    func testClearCachesClearsCachesTimestamp() {
        self.deviceCache.setPurchaserInfoCacheTimestampToNow()
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())
    }

    func testClearCachesRemovesCachedAppUserIDs() {
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.appUserID.new")).to(beTrue())
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.appUserID")).to(beTrue())
    }

    func testResetCachesTimestamp() {
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())
        self.deviceCache.setPurchaserInfoCacheTimestampToNow()
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beFalse())
    }

    func testCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())
    }

    func testPurchaserInfoCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache = RCDeviceCache(mockUserDefaults, stubbedNow: oldDate)
        self.deviceCache.cachePurchaserInfo(Data(), forAppUserID: "waldo")

        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beFalse())
        self.deviceCache.stubbedNow = Date()
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())
    }

    func testOfferingsCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        let mockCachedObject = RCInMemoryCachedObject<Purchases.Offerings>(cacheDurationInSeconds: 5 * 60,
                                                                            lastUpdatedAt: oldDate)
        self.deviceCache = RCDeviceCache(mockUserDefaults, stubbedNow: oldDate, offeringsCachedObject: mockCachedObject)
//        self.deviceCache = RCDeviceCache(mockUserDefaults, stubbedNow: oldDate)
        let offerings = Purchases.Offerings()
        self.deviceCache.cacheOfferings(offerings)

        expect(self.deviceCache.isOfferingsCacheStale()).to(beFalse())
        // wip, this needs to be initialized with a mock InMemoryCachedObject
        self.deviceCache.stubbedNow = Date()
        expect(self.deviceCache.isOfferingsCacheStale()).to(beTrue())
    }

    func testPurchaserInfoIsProperlyCached() {
        let data = Data()
        self.deviceCache.cachePurchaserInfo(data, forAppUserID: "cesar")
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfo.cesar"] as? Data).to(equal(data))
        expect(self.deviceCache.cachedPurchaserInfoData(forAppUserID: "cesar")).to(equal(data))
        expect(self.mockUserDefaults.setObjectForKeyCalledValue).to(equal("com.revenuecat.userdefaults.purchaserInfo.cesar"))
    }
}
