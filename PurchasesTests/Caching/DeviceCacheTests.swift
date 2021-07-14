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
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] as? String)
            .to(equal(userID))
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedPurchaserInfo() {
        self.deviceCache.clearCaches(forAppUserID: "cesar", andSaveNewUserID: "newUser")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.purchaserInfo.cesar"))
            .to(beTrue())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedOfferings() {
        let offerings = Offerings(offerings: [:], currentOfferingID: "")
        self.deviceCache.cacheOfferings(offerings)
        expect(self.deviceCache.cachedOfferings).to(equal(offerings))
        self.deviceCache.clearCaches(forAppUserID: "cesar", andSaveNewUserID: "newUser")
        expect(self.deviceCache.cachedOfferings).to(beNil())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDClearsCachesTimestamp() {
        let appUserID = "cesar"
        self.deviceCache.setPurchaserInfoCacheTimestampToNowForAppUserID(appUserID)
        self.deviceCache.clearCaches(forAppUserID: appUserID, andSaveNewUserID: "newUser")
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID, isAppBackgrounded: false)).to(beTrue())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDUpdatesCachedAppUserID() {
        self.deviceCache.clearCaches(forAppUserID: "cesar", andSaveNewUserID: "newUser")
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

        self.deviceCache.clearCaches(forAppUserID: userID, andSaveNewUserID: "newUser")
        expect(self.mockUserDefaults.mockValues[attributesKey] as? [String: [String: [String: NSObject]]])
            == mockAttributes
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

        self.deviceCache.clearCaches(forAppUserID: userID, andSaveNewUserID: "newUser")

        expect(self.mockUserDefaults.mockValues[attributesKey] as? [String: NSObject]).to(beEmpty())

    }

    func testSetPurchaserInfoCacheTimestampToNow() {
        let appUserID = "user"
        let isBackgrounded = false

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: isBackgrounded)) == true

        self.deviceCache.setPurchaserInfoCacheTimestampToNowForAppUserID(appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: isBackgrounded)) == false
    }

    func testPurchaserInfoCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: "user", isAppBackgrounded: false)).to(beTrue())
    }

    func testSetOfferingsCacheTimestampToNow() {
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: false)).to(beTrue())
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: true)).to(beTrue())
        self.deviceCache.setOfferingsCacheTimestampToNow()
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: false)).to(beFalse())
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: true)).to(beFalse())
    }

    func testOfferingsCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: false)).to(beTrue())
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: true)).to(beTrue())
    }

    func testPurchaserInfoCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache = RCDeviceCache(mockUserDefaults)
        let appUserID = "waldo"
        self.deviceCache.cachePurchaserInfo(Data(), forAppUserID: appUserID)
        let isAppBackgrounded = false

        self.deviceCache.setPurchaserInfoCacheTimestamp(oldDate, forAppUserID: appUserID)
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: isAppBackgrounded)) == true

        self.deviceCache.setPurchaserInfoCacheTimestamp(Date(), forAppUserID: appUserID)
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: isAppBackgrounded)) == false
    }

    func testOfferingsCacheIsStaleIfCachedObjectIsStale() {
        let mockCachedObject = MockInMemoryCachedOfferings<Offerings>()
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: mockCachedObject,
                                         notificationCenter: nil)
        let offerings = Offerings(offerings: [:], currentOfferingID: "")
        self.deviceCache.cacheOfferings(offerings)
        let isAppBackgrounded = false

        mockCachedObject.stubbedIsCacheStaleResult = false
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: isAppBackgrounded)).to(beFalse())

        mockCachedObject.stubbedIsCacheStaleResult = true
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: isAppBackgrounded)).to(beTrue())
    }

    func testPurchaserInfoIsProperlyCached() {
        let data = Data()
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: "cesar", isAppBackgrounded: false)) == true

        self.deviceCache.cachePurchaserInfo(data, forAppUserID: "cesar")

        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfo.cesar"] as? Data)
            .to(equal(data))
        expect(self.deviceCache.cachedPurchaserInfoData(forAppUserID: "cesar")) == data
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: "cesar", isAppBackgrounded: false)) == false
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
        self.deviceCache.cacheOfferings(expectedOfferings)

        expect(self.deviceCache.cachedOfferings).to(beIdenticalTo(expectedOfferings))
    }

    func testCrashesWhenAppUserIDIsDeleted() {
        let mockNotificationCenter = MockNotificationCenter()
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = "Rage Against the Machine"

        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expectToNotThrowException { mockNotificationCenter.fireNotifications() }

        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = nil

        expectToThrowException(.parameterAssert) { mockNotificationCenter.fireNotifications() }
    }

    func testDoesntCrashIfOtherSettingIsDeletedAndAppUserIDHadntBeenSet() {
        let mockNotificationCenter = MockNotificationCenter()
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = nil

        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expectToNotThrowException { mockNotificationCenter.fireNotifications() }
    }

    func testNewDeviceCacheInstanceWithExistingValidPurchaserInfoCacheIsntStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        let fourMinutesAgo = Calendar.current.date(byAdding: .minute, value: -4, to: Date())
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"] = fourMinutesAgo
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: false)) == false
    }

    func testNewDeviceCacheInstanceWithExistingInvalidPurchaserInfoCacheIsStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"] = fourDaysAgo
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: false)) == true
    }

    func testNewDeviceCacheInstanceWithNoCachedPurchaserInfoCacheIsStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: false)) == true
    }

    func testIsPurchaserInfoCacheStaleForBackground() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)
        let outdatedCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        self.deviceCache.setPurchaserInfoCacheTimestamp(outdatedCacheDateForBackground, forAppUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: true)) == true

        let validCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -15, to: Date())!
        self.deviceCache.setPurchaserInfoCacheTimestamp(validCacheDateForBackground, forAppUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: true)) == false
    }

    func testIsPurchaserInfoCacheStaleForForeground() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)
        let outdatedCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -25, to: Date())!
        self.deviceCache.setPurchaserInfoCacheTimestamp(outdatedCacheDateForForeground, forAppUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: false)) == true

        let validCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setPurchaserInfoCacheTimestamp(validCacheDateForForeground, forAppUserID: appUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: true)) == false
    }

    func testIsPurchaserInfoCacheWithCachedInfoButNoTimestamp() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)

        let data = Data()
        self.deviceCache.cachePurchaserInfo(data, forAppUserID: appUserID)
        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: false)) == false

        self.deviceCache.clearPurchaserInfoCacheTimestamp(forAppUserID: appUserID)


        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: appUserID,
                                                          isAppBackgrounded: false)) == true
    }

    func testIsPurchaserInfoCacheStaleForDifferentAppUserID() {
        let mockNotificationCenter = MockNotificationCenter()
        let otherAppUserID = "some other user"
        let currentAppUserID = "myUser"
        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: nil,
                                         notificationCenter: mockNotificationCenter)
        let validCacheDate = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setPurchaserInfoCacheTimestamp(validCacheDate, forAppUserID: otherAppUserID)

        expect(self.deviceCache.isPurchaserInfoCacheStale(forAppUserID: currentAppUserID,
                                                          isAppBackgrounded: true)) == true
    }

    func testIsOfferingsCacheStaleDifferentCacheLengthsForBackgroundAndForeground() {
        let mockNotificationCenter = MockNotificationCenter()
        let mockCachedObject = RCInMemoryCachedObject<Offerings>()

        self.deviceCache = RCDeviceCache(mockUserDefaults,
                                         offeringsCachedObject: mockCachedObject,
                                         notificationCenter: mockNotificationCenter)

        let outdatedCacheDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        mockCachedObject.updateCacheTimestamp(with: outdatedCacheDate)
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: false)) == true
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: true)) == true

        let cacheDateStaleForForeground = Calendar.current.date(byAdding: .hour, value: -23, to: Date())!
        mockCachedObject.updateCacheTimestamp(with: cacheDateStaleForForeground)
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: false)) == true
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: true)) == false

        let cacheDateValidForBoth = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        mockCachedObject.updateCacheTimestamp(with: cacheDateValidForBoth)
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: false)) == false
        expect(self.deviceCache.isOfferingsCacheStale(withIsAppBackgrounded: true)) == false
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

        let subscriberAttribute = RCDeviceCache.newAttribute(with: subscriberDict)

        expect(subscriberAttribute.key) == key
        expect(subscriberAttribute.value) == value
        expect(subscriberAttribute.setTime as NSDate) == setTime
        expect(subscriberAttribute.isSynced) == isSynced
    }
}
