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

    func testClearCachesRemovesCachedPurchaserInfo() {
        self.deviceCache.clearCaches(forAppUserID: "cesar")
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.purchaserInfo.cesar"))
            .to(beTrue())
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
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.appUserID.new"))
            .to(beTrue())
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains("com.revenuecat.userdefaults.appUserID"))
            .to(beTrue())
    }

    func testClearCachesRemovesCachedSubscriberAttributes() {
        self.deviceCache.clearCaches(forAppUserID: "andy")
        let attributesKey = "com.revenuecat.userdefaults.subscriberAttributes.andy"
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains(attributesKey)).to(beTrue())
    }

    func testSetPurchaserInfoCacheTimestampToNow() {
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())
        self.deviceCache.setPurchaserInfoCacheTimestampToNow()
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beFalse())
    }

    func testPurchaserInfoCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())
    }

    func testSetOfferingsCacheTimestampToNow() {
        expect(self.deviceCache.isOfferingsCacheStale()).to(beTrue())
        self.deviceCache.setOfferingsCacheTimestampToNow()
        expect(self.deviceCache.isOfferingsCacheStale()).to(beFalse())
    }

    func testOfferingsCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isOfferingsCacheStale()).to(beTrue())
    }

    func testPurchaserInfoCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache = RCDeviceCache(mockUserDefaults)
        self.deviceCache.cachePurchaserInfo(Data(), forAppUserID: "waldo")

        self.deviceCache.purchaserInfoCachesLastUpdated = oldDate
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beTrue())

        self.deviceCache.purchaserInfoCachesLastUpdated = Date()
        expect(self.deviceCache.isPurchaserInfoCacheStale()).to(beFalse())
    }

    func testOfferingsCacheIsStaleIfCachedObjectIsStale() {
        let mockCachedObject = MockInMemoryCachedOfferings<Purchases.Offerings>(cacheDurationInSeconds: 5 * 60)
        self.deviceCache = RCDeviceCache(mockUserDefaults, offeringsCachedObject: mockCachedObject)
        let offerings = Purchases.Offerings()
        self.deviceCache.cacheOfferings(offerings)

        mockCachedObject.stubbedIsCacheStaleResult = false
        expect(self.deviceCache.isOfferingsCacheStale()).to(beFalse())

        mockCachedObject.stubbedIsCacheStaleResult = true
        expect(self.deviceCache.isOfferingsCacheStale()).to(beTrue())
    }

    func testPurchaserInfoIsProperlyCached() {
        let data = Data()
        self.deviceCache.cachePurchaserInfo(data, forAppUserID: "cesar")
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfo.cesar"] as? Data)
            .to(equal(data))
        expect(self.deviceCache.cachedPurchaserInfoData(forAppUserID: "cesar")).to(equal(data))
        expect(self.mockUserDefaults.setObjectForKeyCalledValue)
            .to(equal("com.revenuecat.userdefaults.purchaserInfo.cesar"))
    }

    func testOfferingsAreProperlyCached() {
        let products = [
            "com.myproduct.annual": MockSKProduct(mockIdentifier: "com.myproduct.annual"),
            "com.myproduct.monthly": MockSKProduct(mockIdentifier: "com.myproduct.monthly")
        ]
        let offeringIdentifier = "offering_a"
        let serverDescription = "This is the base offering"
        let optionalOffering = RCOfferingsFactory().createOffering(withProducts: products, offeringData: [
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
        let expectedOfferings = Purchases.Offerings(offerings: ["offering1": offering], currentOfferingID: "base")
        self.deviceCache.cacheOfferings(expectedOfferings)

        expect(self.deviceCache.cachedOfferings).to(beIdenticalTo(expectedOfferings))
    }

    // MARK: Subscriber Attributes

    func testStoreSubscriberAttributeStoresCorrectly() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttribute = RCSubscriberAttribute(key: "height",
                                                        value: "183",
                                                        appUserID: "waldo",
                                                        dateProvider: dateProvider)

        self.deviceCache.store(subscriberAttribute)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[subscriberAttribute.key] as? NSDictionary) ==
            subscriberAttribute.asDictionary() as NSDictionary
    }

    func testStoreSubscriberAttributeDoesNotModifyExistingValuesWithDifferentKeys() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttributeHeight = RCSubscriberAttribute(key: "height",
                                                              value: "183",
                                                              appUserID: "waldo",
                                                              dateProvider: dateProvider)
        self.deviceCache.store(subscriberAttributeHeight)

        expect(self.mockUserDefaults.mockValues.count) == 1

        let subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                              value: "160",
                                                              appUserID: "waldo",
                                                              dateProvider: dateProvider)
        self.deviceCache.store(subscriberAttributeWeight)
        expect(self.mockUserDefaults.mockValues.count) == 1

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[subscriberAttributeWeight.key] as? NSDictionary) ==
            subscriberAttributeWeight.asDictionary() as NSDictionary

        expect(storedDict[subscriberAttributeHeight.key] as? NSDictionary) ==
            subscriberAttributeHeight.asDictionary() as NSDictionary
    }

    func testStoreSubscriberAttributeUpdatesExistingValue() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let oldSubscriberAttribute = RCSubscriberAttribute(key: "height",
                                                           value: "183",
                                                           appUserID: "waldo",
                                                           dateProvider: dateProvider)
        self.deviceCache.store(oldSubscriberAttribute)

        let newSubscriberAttribute = RCSubscriberAttribute(key: "height",
                                                           value: "250",
                                                           appUserID: "waldo",
                                                           dateProvider: dateProvider)
        self.deviceCache.store(newSubscriberAttribute)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }

        expect(self.mockUserDefaults.mockValues.count) == 1

        expect(storedDict[newSubscriberAttribute.key] as? NSDictionary) ==
            newSubscriberAttribute.asDictionary() as NSDictionary

        expect(storedDict[oldSubscriberAttribute.key] as? NSDictionary) ==
            newSubscriberAttribute.asDictionary() as NSDictionary
    }
}
