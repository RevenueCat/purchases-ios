//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class DeviceCacheTests: TestCase {

    private let subscriberAttributesKey = "com.revenuecat.userdefaults.subscriberAttributes"

    private var sandboxEnvironmentDetector: MockSandboxEnvironmentDetector! = nil
    private var mockUserDefaults: MockUserDefaults! = nil
    private var deviceCache: DeviceCache! = nil

    override func setUp() {
        self.sandboxEnvironmentDetector = MockSandboxEnvironmentDetector(isSandbox: false)
        self.mockUserDefaults = MockUserDefaults()
        self.deviceCache = self.create()
    }

    func testLegacyCachedUserIDUsesRightKey() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "cesar"

        // `DeviceCache` caches the ID in memory.
        // Modifying the data under the hood won't be detected
        // so re-create `DeviceCache` to force it to read it again.
        let deviceCache = self.create()

        expect(deviceCache.cachedLegacyAppUserID) == "cesar"
    }

    func testCachedUserIDUsesRightKey() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = "cesar"

        // `DeviceCache` caches the user ID in memory.
        // Modifying the data under the hood won't be detected
        // so re-create `DeviceCache` to force it to read it again.
        let deviceCache = self.create()

        expect(deviceCache.cachedAppUserID) == "cesar"
    }

    func testCacheUserIDUsesRightKey() {
        let userID = "cesar"
        self.deviceCache.cache(appUserID: userID)
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] as? String)
            .to(equal(userID))
    }

    func testCacheUserIDUpdatesCache() {
        let userID = "cesar"
        self.deviceCache.cache(appUserID: userID)
        expect(self.deviceCache.cachedAppUserID) == userID
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedCustomerInfo() {
        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")
        let expectedCacheKey = "com.revenuecat.userdefaults.purchaserInfo.cesar"
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains(expectedCacheKey)).to(beTrue())
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
        self.deviceCache.setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: appUserID)
        self.deviceCache.clearCaches(oldAppUserID: appUserID, andSaveWithNewUserID: "newUser")
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID, isAppBackgrounded: false)).to(beTrue())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDUpdatesCachedAppUserID() {
        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] as? String) == "newUser"
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"]).to(beNil())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDUpdatesCaches() {
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID"] = "cesar"
        self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = "cesar"

        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")

        expect(self.deviceCache.cachedAppUserID) == "newUser"
        expect(self.deviceCache.cachedLegacyAppUserID).to(beNil())
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDDoesntRemoveCachedSubscriberAttributesIfUnsynced() {
        let userID = "andy"
        let key = "band"
        let unsyncedSubscriberAttribute = SubscriberAttribute(withKey: key,
                                                              value: "La Renga",
                                                              isSynced: false,
                                                              setTime: Date()).asDictionary()
        let mockAttributes: [String: [String: [String: NSObject]]] = [
            userID: [key: unsyncedSubscriberAttribute]
        ]
        mockUserDefaults.mockValues[self.subscriberAttributesKey] = mockAttributes

        self.deviceCache.clearCaches(oldAppUserID: userID, andSaveWithNewUserID: "newUser")
        let mockValues = self.mockUserDefaults.mockValues[self.subscriberAttributesKey]
        expect(mockValues as? [String: [String: [String: NSObject]]]) == mockAttributes
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedSubscriberAttributesIfSynced() {
        let userID = "andy"
        let key = "band"
        let unsyncedSubscriberAttribute = SubscriberAttribute(withKey: key,
                                                              value: "La Renga",
                                                              isSynced: true,
                                                              setTime: Date()).asDictionary()

        mockUserDefaults.mockValues[self.subscriberAttributesKey] = [
            userID: [key: unsyncedSubscriberAttribute]
        ]

        expect(self.mockUserDefaults.mockValues[self.subscriberAttributesKey] as? [String: NSObject]).notTo(beEmpty())

        self.deviceCache.clearCaches(oldAppUserID: userID, andSaveWithNewUserID: "newUser")

        expect(self.mockUserDefaults.mockValues[self.subscriberAttributesKey] as? [String: NSObject]).to(beEmpty())

    }

    func testSetCustomerInfoCacheTimestampToNow() {
        let appUserID = "user"
        let isBackgrounded = false

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: isBackgrounded)) == true

        self.deviceCache.setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: isBackgrounded)) == false
    }

    func testCustomerInfoCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: "user", isAppBackgrounded: false)).to(beTrue())
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

    func testCustomerInfoCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults)
        let appUserID = "waldo"
        deviceCache.cache(customerInfo: Data(), appUserID: appUserID)
        let isAppBackgrounded = false

        self.deviceCache.setCustomerInfoCache(timestamp: oldDate, appUserID: appUserID)
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: isAppBackgrounded)) == true

        self.deviceCache.setCustomerInfoCache(timestamp: Date(), appUserID: appUserID)
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: isAppBackgrounded)) == false
    }

    func testOfferingsCacheIsStaleIfCachedObjectIsStale() {
        let mockCachedObject = MockInMemoryCachedOfferings<Offerings>()
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject)
        let offerings = Offerings(offerings: [:], currentOfferingID: "")
        self.deviceCache.cache(offerings: offerings)
        let isAppBackgrounded = false

        mockCachedObject.stubbedIsCacheStaleResult = false
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded)).to(beFalse())

        mockCachedObject.stubbedIsCacheStaleResult = true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded)).to(beTrue())
    }

    func testCustomerInfoIsProperlyCached() {
        let data = Data()
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: "cesar", isAppBackgrounded: false)) == true

        self.deviceCache.cache(customerInfo: data, appUserID: "cesar")

        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfo.cesar"] as? Data)
            .to(equal(data))
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: "cesar")) == data
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: "cesar", isAppBackgrounded: false)) == false
    }

    func testOfferingsAreProperlyCached() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct)
        ]

        let offeringIdentifier = "offering_a"
        let serverDescription = "This is the base offering"

        let offeringsJSON = """
            {
                "identifier": "\(offeringIdentifier)",
                "description": "\(serverDescription)",
                "packages": [
                    {"identifier": "$rc_monthly",
                     "platform_product_identifier": "com.myproduct.monthly"},
                    {"identifier": "$rc_annual",
                     "platform_product_identifier": "com.myproduct.annual"},
                    {"identifier": "$rc_six_month",
                     "platform_product_identifier": "com.myproduct.sixMonth"}
                ]
            }
        """
        let offeringsData: OfferingsResponse.Offering = try JSONDecoder.default.decode(
            jsonData: offeringsJSON.asData
        )

        let offering = try XCTUnwrap(
            OfferingsFactory().createOffering(from: products, offering: offeringsData)
        )
        let expectedOfferings = Offerings(offerings: ["offering1": offering], currentOfferingID: "base")
        self.deviceCache.cache(offerings: expectedOfferings)

        expect(self.deviceCache.cachedOfferings) === expectedOfferings
    }

    func testAssertionHappensWhenAppUserIDIsDeleted() {
        let mockNotificationCenter = MockNotificationCenter()
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = "Rage Against the Machine"

        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)

        expectNoFatalError { mockNotificationCenter.fireNotifications() }

        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = nil

        // swiftlint:disable:next line_length
        let expectedMessage = "[\(Logger.frameworkDescription)] - Cached appUserID has been deleted from user defaults.\n" +
        "This leaves the SDK in an undetermined state. Please make sure that RevenueCat\n" +
        "entries in user defaults don\'t get deleted by anything other than the SDK.\n" +
        "More info: https://rev.cat/userdefaults-crash"
        expectFatalError(expectedMessage: expectedMessage) { mockNotificationCenter.fireNotifications() }
    }

    func testDoesntCrashIfOtherSettingIsDeletedAndAppUserIDHadntBeenSet() {
        let mockNotificationCenter = MockNotificationCenter()
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.appUserID.new"] = nil
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)

        expectNoFatalError { mockNotificationCenter.fireNotifications() }
    }

    func testNoAssertionIfModifyingRevenueCatUserDefaultsSuite() {
        let userDefaults: UserDefaults = .revenueCatSuite
        let mockNotificationCenter = MockNotificationCenter()

        userDefaults.set("User", forKey: "com.revenuecat.userdefaults.appUserID.new")

        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: userDefaults,
                                       notificationCenter: mockNotificationCenter)

        userDefaults.set(nil, forKey: "com.revenuecat.userdefaults.appUserID.new")

        expectNoFatalError { mockNotificationCenter.fireNotifications() }
    }

    func testNewDeviceCacheInstanceWithExistingValidCustomerInfoCacheIsntStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        let fourMinutesAgo = Calendar.current.date(byAdding: .minute, value: -4, to: Date())
        let cackeKey = "com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"
        mockUserDefaults.mockValues[cackeKey] = fourMinutesAgo
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == false
    }

    func testNewDeviceCacheInstanceWithExistingInvalidCustomerInfoCacheIsStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"] = fourDaysAgo
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true
    }

    func testNewDeviceCacheInstanceWithNoCachedCustomerInfoCacheIsStale() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true
    }

    func testIsCustomerInfoCacheStaleForBackground() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)
        let outdatedCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: outdatedCacheDateForBackground, appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: true)) == true

        let validCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -15, to: Date())!
        deviceCache.setCustomerInfoCache(timestamp: validCacheDateForBackground, appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: true)) == false
    }

    func testIsCustomerInfoCacheStaleForForeground() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)
        let outdatedCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -25, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: outdatedCacheDateForForeground, appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true

        let validCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: validCacheDateForForeground, appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: true)) == false
    }

    func testIsCustomerInfoCacheWithCachedInfoButNoTimestamp() {
        let mockNotificationCenter = MockNotificationCenter()
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)

        let data = Data()
        self.deviceCache.cache(customerInfo: data, appUserID: appUserID)
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == false

        self.deviceCache.clearCustomerInfoCacheTimestamp(appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true
    }

    func testIsCustomerInfoCacheStaleForDifferentAppUserID() {
        let mockNotificationCenter = MockNotificationCenter()
        let otherAppUserID = "some other user"
        let currentAppUserID = "myUser"
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       notificationCenter: mockNotificationCenter)
        let validCacheDate = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: validCacheDate, appUserID: otherAppUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: currentAppUserID,
                                                         isAppBackgrounded: true)) == true
    }

    func testIsOfferingsCacheStaleDifferentCacheLengthsForBackgroundAndForeground() {
        let mockNotificationCenter = MockNotificationCenter()
        let mockCachedObject = InMemoryCachedObject<Offerings>()

        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
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

    func testClearCachedOfferings() {
        let mockCachedObject = MockInMemoryCachedOfferings<Offerings>()
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                                       userDefaults: self.mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject)

        self.deviceCache.clearCachedOfferings()

        expect(mockCachedObject.invokedClearCache) == true
    }

    func testSetLatestAdvertisingIdsByNetworkSentMapsAttributionNetworksToStringKeys() {
        let userId = "asdf"
        let token = "token"
        let latestAdIdsByNetworkSent = [AttributionNetwork.adServices: token]
        self.deviceCache.set(latestAdvertisingIdsByNetworkSent: latestAdIdsByNetworkSent, appUserID: userId)

        let key = "com.revenuecat.userdefaults.attribution." + userId
        expect(self.mockUserDefaults.object(forKey: key) as? [String: String] ?? [:]) ==
            [String(AttributionNetwork.adServices.rawValue): token]
    }

    func testSetLatestAdvertisingIdsByNetworkSentMapsStringKeysToAttributionNetworks() {
        let userId = "asdf"
        let token = "token"
        let key = "com.revenuecat.userdefaults.attribution." + userId
        let cachedValue = [String(AttributionNetwork.adServices.rawValue): token]

        self.mockUserDefaults.mockValues = [key: cachedValue]

        expect(self.deviceCache.latestAdvertisingIdsByNetworkSent(appUserID: userId)) ==
            [AttributionNetwork.adServices: token]
    }

    func testCopySubscriberAttributesDoesNothingIfOldUserIdHasNoUnsyncedAttributes() {
        let oldAppUserId = "test-user-id"
        let newAppUserId = "new-test-user-id"
        let key = "band"
        let unsyncedSubscriberAttribute = SubscriberAttribute(withKey: key,
                                                              value: "La Renga",
                                                              isSynced: true,
                                                              setTime: Date()).asDictionary()
        let mockAttributes: [String: [String: [String: NSObject]]] = [
            oldAppUserId: [key: unsyncedSubscriberAttribute]
        ]
        self.mockUserDefaults.mockValues[self.subscriberAttributesKey] = mockAttributes

        self.deviceCache.copySubscriberAttributes(oldAppUserID: oldAppUserId, newAppUserID: newAppUserId)

        expect(self.mockUserDefaults.setObjectForKeyCalledValue).to(beNil())
    }

    func testCopySubscriberAttributesCopiesAttributesAndDeletesOldAttributesIfOldUserIdHasUnsyncedAttributes() {
        let oldAppUserId = "test-user-id"
        let newAppUserId = "new-test-user-id"
        let key = "band"
        let unsyncedSubscriberAttribute = SubscriberAttribute(withKey: key,
                                                              value: "La Renga",
                                                              isSynced: false,
                                                              setTime: Date()).asDictionary()
        let originalAttributesSet: [String: [String: [String: NSObject]]] = [
            oldAppUserId: [key: unsyncedSubscriberAttribute]
        ]
        let expectedAttributesSet: [String: [String: [String: NSObject]]] = [
            newAppUserId: [key: unsyncedSubscriberAttribute]
        ]
        self.mockUserDefaults.mockValues[self.subscriberAttributesKey] = originalAttributesSet

        self.deviceCache.copySubscriberAttributes(oldAppUserID: oldAppUserId, newAppUserID: newAppUserId)

        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == self.subscriberAttributesKey
        let storedAttributes = self.mockUserDefaults.mockValues[self.subscriberAttributesKey]
        expect(storedAttributes as? [String: [String: [String: NSObject]]]) == expectedAttributesSet
    }

    func testCacheEmptyProductEntitlementMapping() {
        let data = ProductEntitlementMapping(entitlementsByProduct: [:])

        self.deviceCache.store(productEntitlementMapping: data)
        expect(self.deviceCache.cachedProductEntitlementMapping) == data
    }

    func testCacheProductEntitlementMapping() {
        let data = ProductEntitlementMapping(entitlementsByProduct: [
            "1": ["pro_1"],
            "2": ["pro_2"],
            "3": ["pro_1", "pro_2"]
        ])

        self.deviceCache.store(productEntitlementMapping: data)
        expect(self.deviceCache.cachedProductEntitlementMapping) == data
    }

    func testIsProductEntitlementMappingCacheStaleWithNoDate() {
        expect(self.deviceCache.isProductEntitlementMappingCacheStale) == true
    }

    func testCacheProductEntitlementMappingUpdatesLastUpdatedDate() throws {
        self.deviceCache.store(productEntitlementMapping: .init(entitlementsByProduct: [:]))

        let key = DeviceCache.CacheKeys.productEntitlementMappingLastUpdated.rawValue
        let lastUpdated = try XCTUnwrap(self.mockUserDefaults.mockValues[key] as? Date)

        expect(lastUpdated).to(beCloseTo(Date(), within: 1))
    }

    func testIsProductEntitlementMappingCacheStaleWithRecentUpdate() {
        self.mockUserDefaults.mockValues[DeviceCache.CacheKeys.productEntitlementMappingLastUpdated.rawValue] = Date()
            .addingTimeInterval(DispatchTimeInterval.days(1).seconds * -1) // 1 day ago

        expect(self.deviceCache.isProductEntitlementMappingCacheStale) == false
    }

    func testIsProductEntitlementMappingCacheStaleWithStaleDate() {
        self.mockUserDefaults.mockValues[DeviceCache.CacheKeys.productEntitlementMappingLastUpdated.rawValue] = Date()
            .addingTimeInterval(DispatchTimeInterval.hours(25).seconds * -1)
            .addingTimeInterval(-5) // 5 seconds before

        expect(self.deviceCache.isProductEntitlementMappingCacheStale) == true
    }

}

private extension DeviceCacheTests {

    func create() -> DeviceCache {
        return DeviceCache(sandboxEnvironmentDetector: self.sandboxEnvironmentDetector,
                           userDefaults: self.mockUserDefaults)
    }

}
