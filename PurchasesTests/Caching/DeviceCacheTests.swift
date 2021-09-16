//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

@testable import RevenueCat

class DeviceCacheTests: XCTestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var deviceCache: DeviceCache! = nil

    override func setUp() {
        self.mockUserDefaults = MockUserDefaults()
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults)
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
        self.deviceCache.cache(appUserID: userID)
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] as? String)
            .to(equal(userID))
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedPurchaserInfo() {
        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.purchaserInfo.cesar"))
            .to(beTrue())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedOfferings() {
        let offerings = Offerings(offerings: [:], currentOfferingID: "")
        self.deviceCache.cache(offerings: offerings)
        expect(self.deviceCache.cachedOfferings).to(equal(offerings))
        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")
        expect(self.deviceCache.cachedOfferings).to(beNil())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDClearsCachesTimestamp() {
        let appUserID = "cesar"
        self.deviceCache.setCacheTimestampToNowToPreventConcurrentPurchaserInfoUpdates(appUserID: appUserID)
        self.deviceCache.clearCaches(oldAppUserID: appUserID, andSaveWithNewUserID: "newUser")
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID, isAppBackgrounded: false)).to(beTrue())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDUpdatesCachedAppUserID() {
        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] as? String) == "newUser"
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"]).to(beNil())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDDoesntRemoveCachedSubscriberAttributesIfUnsynced() {
        let userID = "andy"
        let attributesKey = "com.revenuecat.userdefaults.subscriberAttributes"
        let key = "band"
        let unsyncedSubscriberAttribute = SubscriberAttribute(withKey: key,
                                                              value: "La Renga",
                                                              isSynced: false,
                                                              setTime: Date()).asDictionary()
        let mockAttributes: [String: [String: [String: NSObject]]] = [
            userID: [key: unsyncedSubscriberAttribute]
        ]
        mockUserDefaults.mockValues[attributesKey] = mockAttributes

        self.deviceCache.clearCaches(oldAppUserID: userID, andSaveWithNewUserID: "newUser")
        let mockValues = self.mockUserDefaults.mockValues[attributesKey]
        expect(mockValues as? [String: [String: [String: NSObject]]]) == mockAttributes
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedSubscriberAttributesIfSynced() {
        let userID = "andy"
        let attributesKey = "com.revenuecat.userdefaults.subscriberAttributes"
        let key = "band"
        let unsyncedSubscriberAttribute = SubscriberAttribute(withKey: key,
                                                              value: "La Renga",
                                                              isSynced: true,
                                                              setTime: Date()).asDictionary()

        mockUserDefaults.mockValues[attributesKey] = [
            userID: [key: unsyncedSubscriberAttribute]
        ]

        expect(self.mockUserDefaults.mockValues[attributesKey] as? [String: NSObject]).notTo(beEmpty())

        self.deviceCache.clearCaches(oldAppUserID: userID, andSaveWithNewUserID: "newUser")

        expect(self.mockUserDefaults.mockValues[attributesKey] as? [String: NSObject]).to(beEmpty())

    }

    func testSetPurchaserInfoCacheTimestampToNow() {
        let appUserID = "user"
        let isBackgrounded = false

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: isBackgrounded)) == true

        self.deviceCache.setCacheTimestampToNowToPreventConcurrentPurchaserInfoUpdates(appUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: isBackgrounded)) == false
    }

    func testPurchaserInfoCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: "user", isAppBackgrounded: false)).to(beTrue())
    }

    func testSetOfferingsCacheTimestampToNow() {
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)).to(beTrue())
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)).to(beTrue())
        self.deviceCache.setOfferingsCacheTimestampToNow()
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)).to(beFalse())
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)).to(beFalse())
    }

    func testOfferingsCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)).to(beTrue())
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)).to(beTrue())
    }

    func testPurchaserInfoCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults)
        let appUserID = "waldo"
        deviceCache.cache(purchaserInfo: Data(), appUserID: appUserID)
        let isAppBackgrounded = false

        self.deviceCache.setPurchaserInfoCache(timestamp: oldDate, appUserID: appUserID)
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: isAppBackgrounded)) == true

        self.deviceCache.setPurchaserInfoCache(timestamp: Date(), appUserID: appUserID)
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: isAppBackgrounded)) == false
    }

    func testOfferingsCacheIsStaleIfCachedObjectIsStale() {
        let mockCachedObject = MockInMemoryCachedOfferings<Offerings>()
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject,
                                       notificationCenter: nil)
        let offerings = Offerings(offerings: [:], currentOfferingID: "")
        self.deviceCache.cache(offerings: offerings)
        let isAppBackgrounded = false

        mockCachedObject.stubbedIsCacheStaleResult = false
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded)).to(beFalse())

        mockCachedObject.stubbedIsCacheStaleResult = true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded)).to(beTrue())
    }

    func testPurchaserInfoIsProperlyCached() {
        let data = Data()
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: "cesar", isAppBackgrounded: false)) == true

        self.deviceCache.cache(purchaserInfo: data, appUserID: "cesar")

        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfo.cesar"] as? Data)
            .to(equal(data))
        expect(self.deviceCache.cachedPurchaserInfoData(appUserID: "cesar")) == data
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: "cesar", isAppBackgrounded: false)) == false
    }

    func testOfferingsAreProperlyCached() {
        let products = [
            "com.myproduct.annual": MockSKProduct(mockProductIdentifier: "com.myproduct.annual"),
            "com.myproduct.monthly": MockSKProduct(mockProductIdentifier: "com.myproduct.monthly")
        ]
        let offeringIdentifier = "offering_a"
        let serverDescription = "This is the base offering"
        let optionalOffering = OfferingsFactory().createOffering(withProducts: products, offeringData: [
            "identifier": offeringIdentifier,
            "description": serverDescription,
            "packages": [
                ["identifier": "$rc_monthly",
                 "platform_product_identifier": "com.myproduct.monthly"],
                ["identifier": "$rc_annual",
                 "platform_product_identifier": "com.myproduct.annual"],
                ["identifier": "$rc_six_month",
                 "platform_product_identifier": "com.myproduct.sixMonth"]
            ]
        ])
        guard let offering = optionalOffering else { fatalError("couldn't create offering for tests") }
        let expectedOfferings = Offerings(offerings: ["offering1": offering], currentOfferingID: "base")
        self.deviceCache.cache(offerings: expectedOfferings)

        expect(self.deviceCache.cachedOfferings).to(beIdenticalTo(expectedOfferings))
    }


    func testAssertionHappensWhenAppUserIDIsDeleted() {
        let mockNotificationCenter = MockNotificationCenter()
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = "Rage Against the Machine"

        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                       offeringsCachedObject: nil,
                                       notificationCenter: mockNotificationCenter)

        expectNoFatalError { mockNotificationCenter.fireNotifications() }

        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = nil

        let expectedMessage = "[Purchases] - Cached appUserID has been deleted from user defaults.\n" +
        "This leaves the SDK in an undetermined state. Please make sure that RevenueCat\n" +
        "entries in user defaults don\'t get deleted by anything other than the SDK.\n" +
        "More info: https://rev.cat/userdefaults-crash"
        expectFatalError(expectedMessage: expectedMessage) { mockNotificationCenter.fireNotifications() }
    }

    func testDoesntCrashIfOtherSettingIsDeletedAndAppUserIDHadntBeenSet() {
        let mockNotificationCenter = MockNotificationCenter()
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = nil
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                       offeringsCachedObject: nil,
                                       notificationCenter: mockNotificationCenter)

        expectNoFatalError() { mockNotificationCenter.fireNotifications() }
    }

    func testNewDeviceCacheInstanceWithExistingValidPurchaserInfoCacheIsntStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        let fourMinutesAgo = Calendar.current.date(byAdding: .minute, value: -4, to: Date())
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"] = fourMinutesAgo
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: false)) == false
    }

    func testNewDeviceCacheInstanceWithExistingInvalidPurchaserInfoCacheIsStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"] = fourDaysAgo
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: false)) == true
    }

    func testNewDeviceCacheInstanceWithNoCachedPurchaserInfoCacheIsStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: false)) == true
    }

    func testIsPurchaserInfoCacheStaleForBackground() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)
        let outdatedCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        self.deviceCache.setPurchaserInfoCache(timestamp: outdatedCacheDateForBackground, appUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: true)) == true

        let validCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -15, to: Date())!
        deviceCache.setPurchaserInfoCache(timestamp: validCacheDateForBackground, appUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: true)) == false
    }

    func testIsPurchaserInfoCacheStaleForForeground() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)
        let outdatedCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -25, to: Date())!
        self.deviceCache.setPurchaserInfoCache(timestamp: outdatedCacheDateForForeground, appUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: false)) == true

        let validCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setPurchaserInfoCache(timestamp: validCacheDateForForeground, appUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: true)) == false
    }

    func testIsPurchaserInfoCacheWithCachedInfoButNoTimestamp() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        let data = Data()
        self.deviceCache.cache(purchaserInfo: data, appUserID: appUserID)
        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: false)) == false

        self.deviceCache.clearPurchaserInfoCacheTimestamp(appUserID: appUserID)


        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                          isAppBackgrounded: false)) == true
    }

    func testIsPurchaserInfoCacheStaleForDifferentAppUserID() {
        let mockNotificationCenter = MockNotificationCenter()
        let otherAppUserID = "some other user"
        let currentAppUserID = "myUser"
        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                       offeringsCachedObject: nil,
                                       notificationCenter: mockNotificationCenter)
        let validCacheDate = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setPurchaserInfoCache(timestamp: validCacheDate, appUserID: otherAppUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(appUserID: currentAppUserID,
                                                          isAppBackgrounded: true)) == true
    }

    func testIsOfferingsCacheStaleDifferentCacheLengthsForBackgroundAndForeground() {
        let mockNotificationCenter = MockNotificationCenter()
        let mockCachedObject = InMemoryCachedObject<Offerings>()

        self.deviceCache = DeviceCache(userDefaults: mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject,
                                       notificationCenter: mockNotificationCenter)

        let outdatedCacheDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        mockCachedObject.updateCacheTimestamp(date: outdatedCacheDate)
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == true

        let cacheDateStaleForForeground = Calendar.current.date(byAdding: .hour, value: -23, to: Date())!
        mockCachedObject.updateCacheTimestamp(date: cacheDateStaleForForeground)
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == false

        let cacheDateValidForBoth = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        mockCachedObject.updateCacheTimestamp(date: cacheDateValidForBoth)
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == false
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == false
    }

    func testInitWithDictionarySetsRightValues() {
        let key = "some key"
        let value = "some value"
        let setTime = NSDate()
        let isSynced = true
        let subscriberDict: [String: NSObject] = [
            "key": NSString(string: key),
            "value": NSString(string: value),
            "setTime": setTime,
            "isSynced": NSNumber(booleanLiteral: isSynced),
        ]

        let subscriberAttribute = DeviceCache.newAttribute(dictionary: subscriberDict)

        expect(subscriberAttribute.key) == key
        expect(subscriberAttribute.value) == value
        expect(subscriberAttribute.setTime as NSDate) == setTime
        expect(subscriberAttribute.isSynced) == isSynced
    }
}
