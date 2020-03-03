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
        setUpSubscriberAttributes()
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
    private var now = Date()
    private var mockDateProvider: MockDateProvider!
    private var subscriberAttributeHeight: RCSubscriberAttribute!
    private var subscriberAttributeWeight: RCSubscriberAttribute!

    private func setUpSubscriberAttributes() {
        self.mockDateProvider = MockDateProvider(stubbedNow: now)
        self.subscriberAttributeHeight = RCSubscriberAttribute(key: "height",
                                                               value: "183",
                                                               dateProvider: mockDateProvider)
        self.subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                               value: "160",
                                                               dateProvider: mockDateProvider)
    }

    func testStoreSubscriberAttributeStoresCorrectly() {
        self.deviceCache.store(subscriberAttributeHeight, appUserID: "waldo")

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[self.subscriberAttributeHeight.key] as? NSDictionary) ==
            subscriberAttributeHeight.asDictionary() as NSDictionary
    }

    func testStoreSubscriberAttributeDoesNotModifyExistingValuesWithDifferentKeys() {
        self.deviceCache.store(subscriberAttributeHeight, appUserID: "waldo")

        expect(self.mockUserDefaults.mockValues.count) == 1

        let subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                              value: "160",
                                                              dateProvider: mockDateProvider)
        self.deviceCache.store(subscriberAttributeWeight, appUserID: "waldo")
        expect(self.mockUserDefaults.mockValues.count) == 1

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[subscriberAttributeWeight.key] as? NSDictionary) ==
            subscriberAttributeWeight.asDictionary() as NSDictionary

        expect(storedDict[self.subscriberAttributeHeight.key] as? NSDictionary) ==
            subscriberAttributeHeight.asDictionary() as NSDictionary
    }

    func testStoreSubscriberAttributeUpdatesExistingValue() {
        let oldSubscriberAttribute = RCSubscriberAttribute(key: "height",
                                                           value: "183",
                                                           dateProvider: mockDateProvider)
        self.deviceCache.store(oldSubscriberAttribute, appUserID: "waldo")

        let newSubscriberAttribute = RCSubscriberAttribute(key: "height",
                                                           value: "250",
                                                           dateProvider: mockDateProvider)
        self.deviceCache.store(newSubscriberAttribute, appUserID: "waldo")

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

    func testStoreSubscriberAttributesStoresCorrectly() {
        self.deviceCache.storeSubscriberAttributes([subscriberAttributeHeight.key: subscriberAttributeHeight,
                                                    subscriberAttributeWeight.key: subscriberAttributeWeight],
                                                   appUserID: "waldo")

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[self.subscriberAttributeHeight.key] as? NSDictionary) ==
            subscriberAttributeHeight.asDictionary() as NSDictionary
        expect(storedDict[self.subscriberAttributeWeight.key] as? NSDictionary) ==
            subscriberAttributeWeight.asDictionary() as NSDictionary
    }

    func testStoreSubscriberAttributesNoOpIfAttributesDictIsEmpty() {
        self.deviceCache.storeSubscriberAttributes([:], appUserID: "waldo")

        expect(self.mockUserDefaults.setObjectForKeyCalledValue).to(beNil())
        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    func testStoreSubscriberAttributesDoesNotModifyExistingValuesWithDifferentKeys() {
        let otherSubscriberAttribute = RCSubscriberAttribute(key: "age",
                                                             value: "46",
                                                             dateProvider: mockDateProvider)
        self.deviceCache.store(otherSubscriberAttribute, appUserID: "waldo")

        self.deviceCache.storeSubscriberAttributes([subscriberAttributeHeight.key: subscriberAttributeHeight,
                                                    subscriberAttributeWeight.key: subscriberAttributeWeight],
                                                   appUserID: "waldo")

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[self.subscriberAttributeHeight.key] as? NSDictionary) ==
            subscriberAttributeHeight.asDictionary() as NSDictionary
        expect(storedDict[self.subscriberAttributeWeight.key] as? NSDictionary) ==
            subscriberAttributeWeight.asDictionary() as NSDictionary

        expect(storedDict[otherSubscriberAttribute.key] as? NSDictionary) ==
            otherSubscriberAttribute.asDictionary() as NSDictionary
    }

    func testStoreSubscriberAttributesUpdatesExistingValue() {
        self.deviceCache.store(subscriberAttributeHeight, appUserID: "waldo")

        let subscriberAttributeNewHeight = RCSubscriberAttribute(key: "height",
                                                                 value: "460",
                                                                 dateProvider: mockDateProvider)

        self.deviceCache.storeSubscriberAttributes([subscriberAttributeNewHeight.key: subscriberAttributeNewHeight,
                                                    subscriberAttributeWeight.key: subscriberAttributeWeight],
                                                   appUserID: "waldo")

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes.waldo"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }
        expect(storedDict[self.subscriberAttributeHeight.key] as? NSDictionary) ==
            subscriberAttributeNewHeight.asDictionary() as NSDictionary
        expect(storedDict[subscriberAttributeNewHeight.key] as? NSDictionary) ==
            subscriberAttributeNewHeight.asDictionary() as NSDictionary

        expect(storedDict[self.subscriberAttributeWeight.key] as? NSDictionary) ==
            subscriberAttributeWeight.asDictionary() as NSDictionary
    }

    func testSubscriberAttributeWithKeyReturnsCorrectly() {
        self.deviceCache.store(subscriberAttributeHeight, appUserID: "waldo")

        let storedAttribute = self.deviceCache.subscriberAttribute(withKey: subscriberAttributeHeight.key,
                                                                   appUserID: "waldo")

        expect(storedAttribute).toNot(beNil())

        expect(storedAttribute).to(equal(subscriberAttributeHeight))
    }

    func testSubscriberAttributeWithKeyReturnsNilIfNotFound() {
        expect(self.deviceCache.subscriberAttribute(withKey: "doesn't exist", appUserID: "whoever")).to(beNil())
    }

    func testUnsyncedAttributesByKeyReturnsEmptyIfNoneStored() {
        expect(self.deviceCache.unsyncedAttributesByKey(forAppUserID: "waldo")).to(beEmpty())
    }

    func testUnsyncedAttributesByKeyReturnsEmptyIfNoneUnsynced() {
        subscriberAttributeHeight.isSynced = true
        self.deviceCache.store(subscriberAttributeHeight, appUserID: "waldo")
        expect(self.deviceCache.unsyncedAttributesByKey(forAppUserID: "waldo")).to(beEmpty())
    }

    func testUnsyncedAttributesByKeyReturnsCorrectlyWhenFound() {
        let subscriberAttribute1 = RCSubscriberAttribute(key: "height",
                                                         value: "460",
                                                         isSynced: true,
                                                         setTime: now)

        let subscriberAttribute2 = RCSubscriberAttribute(key: "weight",
                                                         value: "120",
                                                         isSynced: false,
                                                         setTime: now)

        let subscriberAttribute3 = RCSubscriberAttribute(key: "age",
                                                         value: "66",
                                                         isSynced: false,
                                                         setTime: now)
        let subscriberAttribute4 = RCSubscriberAttribute(key: "device",
                                                         value: "iPhone",
                                                         isSynced: true,
                                                         setTime: now)

        self.deviceCache.storeSubscriberAttributes([
                                                       subscriberAttribute1.key: subscriberAttribute1,
                                                       subscriberAttribute2.key: subscriberAttribute2,
                                                       subscriberAttribute3.key: subscriberAttribute3,
                                                       subscriberAttribute4.key: subscriberAttribute4
                                                   ],
                                                   appUserID: "waldo")
        let receivedUnsyncedAttributes = self.deviceCache.unsyncedAttributesByKey(forAppUserID: "waldo")
        expect(receivedUnsyncedAttributes).toNot(beEmpty())
        expect(receivedUnsyncedAttributes.count) == 2
        expect(receivedUnsyncedAttributes[subscriberAttribute2.key]).to(equal(subscriberAttribute2))
        expect(receivedUnsyncedAttributes[subscriberAttribute3.key]).to(equal(subscriberAttribute3))
    }

    func testNumberOfUnsyncedAttributesReturnsEmptyIfNoneStored() {
        expect(self.deviceCache.numberOfUnsyncedAttributes(forAppUserID: "waldo")) == 0
    }

    func testNumberOfUnsyncedAttributesReturnsEmptyIfNoneUnsynced() {
        subscriberAttributeHeight.isSynced = true
        self.deviceCache.store(subscriberAttributeHeight, appUserID: "waldo")
        expect(self.deviceCache.numberOfUnsyncedAttributes(forAppUserID: "waldo")) == 0
    }

    func testNumberOfUnsyncedAttributesReturnsCorrectlyWhenFound() {
        let subscriberAttribute1 = RCSubscriberAttribute(key: "height",
                                                         value: "460",
                                                         isSynced: true,
                                                         setTime: now)

        let subscriberAttribute2 = RCSubscriberAttribute(key: "weight",
                                                         value: "120",
                                                         isSynced: false,
                                                         setTime: now)

        let subscriberAttribute3 = RCSubscriberAttribute(key: "age",
                                                         value: "66",
                                                         isSynced: false,
                                                         setTime: now)
        let subscriberAttribute4 = RCSubscriberAttribute(key: "device",
                                                         value: "iPhone",
                                                         isSynced: true,
                                                         setTime: now)

        self.deviceCache.storeSubscriberAttributes([
                                                       subscriberAttribute1.key: subscriberAttribute1,
                                                       subscriberAttribute2.key: subscriberAttribute2,
                                                       subscriberAttribute3.key: subscriberAttribute3,
                                                       subscriberAttribute4.key: subscriberAttribute4
                                                   ],
                                                   appUserID: "waldo")
        expect(self.deviceCache.numberOfUnsyncedAttributes(forAppUserID: "waldo")) == 2
    }
}
