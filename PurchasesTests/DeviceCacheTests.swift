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
        var removeObjectForKeyCalledValue: String? = nil
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
            removeObjectForKeyCalledValue = defaultName
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

    func testCachedUserIDUsesRightKey() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "cesar"
        let userID: String? = self.deviceCache.cachedAppUserID
        expect(userID).to(equal("cesar"))
    }

    func testCacheUserIDUsesRightKey() {
        let userID = "cesar"
        self.deviceCache.cacheAppUserID(userID, isAnonymous: false)
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] as? String).to(equal(userID))
    }

    func testClearCachesRemovesCachedPurchaserInfo() {
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValue).to(equal("com.revenuecat.userdefaults.purchaserInfo.cesar"))
    }

    func testClearCachesRemovesCachedOfferings() {
        let offerings = Offerings()
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

    func testOldAnonymousAppUserIDIsConsideredRandom() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "anoldrandomid"
        let anonymous: Bool = self.deviceCache.isAnonymous()
        expect(anonymous).to(beTrue())
    }

    func testOldNotAnonymousAppUserIDIsNotConsideredRandom() {
        // No need to save anything in the appUserID user defaults key since
        // before 3.0 we were only saving random ones, and that's what
        // we are testing
        let anonymous: Bool = self.deviceCache.isAnonymous()
        expect(anonymous).to(beFalse())
    }

    func testAnonymousAppUserID() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "$RCAnonymousID:ff68f26e432648369a713849a9f93b58"
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.isAnonymous"] = true
        let anonymous: Bool = self.deviceCache.isAnonymous()
        expect(anonymous).to(beTrue())
    }

    func testNonAnonymousAppUserID() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "cesar"
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.isAnonymous"] = false
        let anonymous: Bool = self.deviceCache.isAnonymous()
        expect(anonymous).to(beFalse())
    }

    func testOldAppUserIDIsStoredAsAnonymous() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "anoldrandomid"
        let _: Bool = self.deviceCache.isAnonymous()
        expect(self.mockUserDefaults.setValueForKeyCalledValue).to(equal("com.revenuecat.userdefaults.isAnonymous"))
        expect((self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.isAnonymous"] as! Bool)).to(beTrue())
    }

    func testOldAppUserIDIsStoredAsNotAnonymous() {
        // No need to save anything in the appUserID user defaults key since
        // before 3.0 we were only saving random ones, and that's what
        // we are testing
        let _: Bool = self.deviceCache.isAnonymous()
        expect(self.mockUserDefaults.setValueForKeyCalledValue).to(equal("com.revenuecat.userdefaults.isAnonymous"))
        expect((self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.isAnonymous"] as! Bool)).to(beFalse())
    }

}