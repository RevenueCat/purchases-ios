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

    class MockUserDefaults: UserDefaults {

        var stringForKeyCalledValue: String? = nil
        var setObjectForKeyCalledValue: String? = nil
        var removeObjectForKeyCalledValues: Array<String> = []
        var dataForKeyCalledValue: String? = nil
        var objectForKeyCalledValue: String? = nil
        var setBoolForKeyCalledValue: String? = nil
        var setValueForKeyCalledValue: String? = nil

        var mockValues: [String: Any] = [:]

        override func string(forKey defaultName: String) -> String? {
            stringForKeyCalledValue = defaultName
            return mockValues[defaultName] as? String
        }

        override func removeObject(forKey defaultName: String) {
            removeObjectForKeyCalledValues.append(defaultName)
            mockValues.removeValue(forKey: defaultName)
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            setObjectForKeyCalledValue = defaultName
            mockValues[defaultName] = value
        }

        override func data(forKey defaultName: String) -> Data? {
            dataForKeyCalledValue = defaultName
            return mockValues[defaultName] as? Data
        }

        override func object(forKey defaultName: String) -> Any? {
            objectForKeyCalledValue = defaultName
            return mockValues[defaultName]
        }

        override func set(_ value: Bool, forKey defaultName: String) {
            setValueForKeyCalledValue = defaultName
            mockValues[defaultName] = value
        }
    }

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
        self.deviceCache.resetCachesTimestamp()
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.deviceCache.isCacheStale()).to(beTrue())
    }

    func testClearCachesRemovesCachedAppUserIDs() {
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.appUserID.new")).to(beTrue())
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.appUserID")).to(beTrue())
    }

    func testResetCachesTimestamp() {
        expect(self.deviceCache.isCacheStale()).to(beTrue())
        self.deviceCache.resetCachesTimestamp()
        expect(self.deviceCache.isCacheStale()).to(beFalse())
    }

    func testCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isCacheStale()).to(beTrue())
    }

    func testCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache.cachesLastUpdated = oldDate
        expect(self.deviceCache.isCacheStale()).to(beTrue())
    }

    func testPurchaserInfoIsProperlyCached() {
        let data = Data()
        self.deviceCache.cachePurchaserInfo(data, forAppUserID: "cesar")
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfo.cesar"] as? Data).to(equal(data))
        expect(self.deviceCache.cachedPurchaserInfoData(forAppUserID: "cesar")).to(equal(data))
        expect(self.mockUserDefaults.setObjectForKeyCalledValue).to(equal("com.revenuecat.userdefaults.purchaserInfo.cesar"))
    }

}