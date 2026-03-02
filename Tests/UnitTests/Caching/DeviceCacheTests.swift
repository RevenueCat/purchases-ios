//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class DeviceCacheTests: TestCase {

    private let subscriberAttributesKey = "com.revenuecat.userdefaults.subscriberAttributes"

    private var systemInfo: MockSystemInfo! = nil
    private var preferredLocalesProvider: PreferredLocalesProvider! = nil
    private var mockUserDefaults: MockUserDefaults! = nil
    private var mockFileCache: MockSimpleCache! = nil
    private var deviceCache: DeviceCache! = nil
    private var mockVirtualCurrenciesData: Data!
    private let fileManager = FileManager.default

    override func setUp() {
        super.setUp()

        if let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let oldDirectory = documentsDirectoryURL.appendingPathComponent("RevenueCat")
            try? fileManager.removeItem(at: oldDirectory)
        }

        if let cacheURL = DirectoryHelper.baseUrl(for: .cache) {
            try? fileManager.removeItem(at: cacheURL)
        }

        self.preferredLocalesProvider = .mock(locales: ["en-US"])
        self.systemInfo = MockSystemInfo(finishTransactions: false,
                                         preferredLocalesProvider: self.preferredLocalesProvider)
        self.systemInfo.stubbedIsSandbox = false
        self.mockUserDefaults = MockUserDefaults()
        self.mockFileCache = MockSimpleCache()

        let mockVirtualCurrencies = VirtualCurrencies(virtualCurrencies: [
            "USD": VirtualCurrency(balance: 100, name: "US Dollar", code: "USD", serverDescription: "dollar"),
            "EUR": VirtualCurrency(balance: 200, name: "Euro", code: "EUR", serverDescription: "euro")
        ])
        // swiftlint:disable:next force_try
        self.mockVirtualCurrenciesData = try! JSONEncoder().encode(mockVirtualCurrencies)

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
        let offerings: Offerings = .empty
        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))
        self.deviceCache.cache(offerings: offerings, preferredLocales: ["en-US"], appUserID: "cesar")
        expect(self.deviceCache.cachedOfferings) == offerings

        self.deviceCache.clearCaches(oldAppUserID: "cesar", andSaveWithNewUserID: "newUser")

        expect(self.deviceCache.cachedOfferings).to(beNil())
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues).to(contain([
            "com.revenuecat.userdefaults.offerings.cesar"
        ]))
    }

    func testClearCachesForAppUserIDAndSaveNewUserIDClearsCachesTimestamp() {
        let appUserID = "cesar"
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

    func testCustomerInfoCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: "user", isAppBackgrounded: false)).to(beTrue())
    }

    func testOfferingsCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)).to(beTrue())
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)).to(beTrue())
    }

    func testOfferingsCacheStatusReturnsNotFoundIfNoCachedObject() {
        expect(self.deviceCache.offeringsCacheStatus(isAppBackgrounded: true)) == .notFound
        expect(self.deviceCache.offeringsCacheStatus(isAppBackgrounded: false)) == .notFound
    }

    func testOfferingsCacheStatusReturnsStaleOrValidDependingOnCacheStaleness() {
        let mockCachedObject = MockInMemoryCachedOfferings<Offerings>()
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject)
        self.deviceCache.cache(offerings: .empty, preferredLocales: ["en-US"], appUserID: "user")

        mockCachedObject.stubbedCachedInstanceResult = .empty

        mockCachedObject.stubbedIsCacheStaleResult = false
        expect(self.deviceCache.offeringsCacheStatus(isAppBackgrounded: true)) == .valid

        mockCachedObject.stubbedIsCacheStaleResult = true
        expect(self.deviceCache.offeringsCacheStatus(isAppBackgrounded: true)) == .stale
    }

    func testCustomerInfoCacheIsStaleIfLongerThanFiveMinutes() {
        let oldDate: Date! = Calendar.current.date(byAdding: .minute, value: -(6), to: Date())
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
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
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject)
        self.deviceCache.cache(offerings: .empty, preferredLocales: ["en-US"], appUserID: "user")
        let isAppBackgrounded = false

        mockCachedObject.stubbedIsCacheStaleResult = false
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded)) == false

        mockCachedObject.stubbedIsCacheStaleResult = true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded)) == true
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
        let expectedOfferings = try Self.createSampleOfferings()

        mockFileCache
            .stubSaveData(
                with: .success(.init(data: try expectedOfferings.response.jsonEncodedData, url: .mockFileLocation))
            )

        expect(self.mockFileCache.saveDataInvocations.count) == 0

        self.deviceCache.cache(offerings: expectedOfferings, preferredLocales: ["en-US"], appUserID: "user")

        expect(self.deviceCache.cachedOfferings) === expectedOfferings
        expect(self.mockFileCache.saveDataInvocations.count) == 1
    }

    func testCacheOfferingsInMemory() throws {
        let offerings = try Self.createSampleOfferings()

        self.deviceCache.cacheInMemory(offerings: offerings)

        expect(self.deviceCache.cachedOfferings) === offerings
        expect(self.mockUserDefaults.mockValues).to(beEmpty())
    }

    func testNewDeviceCacheInstanceWithExistingValidCustomerInfoCacheIsntStale() {
        let appUserID = "myUser"
        let fourMinutesAgo = Calendar.current.date(byAdding: .minute, value: -4, to: Date())
        let cackeKey = "com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"
        mockUserDefaults.mockValues[cackeKey] = fourMinutesAgo
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == false
    }

    func testNewDeviceCacheInstanceWithExistingInvalidCustomerInfoCacheIsStale() {
        let appUserID = "myUser"
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())
        mockUserDefaults.mockValues["com.revenuecat.userdefaults.purchaserInfoLastUpdated.\(appUserID)"] = fourDaysAgo
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true
    }

    func testNewDeviceCacheInstanceWithNoCachedCustomerInfoCacheIsStale() {
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true
    }

    func testIsCustomerInfoCacheStaleForBackground() {
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)
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
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)
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
        let appUserID = "myUser"
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)

        let data = Data()
        self.deviceCache.cache(customerInfo: data, appUserID: appUserID)
        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == false

        self.deviceCache.clearCustomerInfoCacheTimestamp(appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                         isAppBackgrounded: false)) == true
    }

    func testIsCustomerInfoCacheStaleForDifferentAppUserID() {
        let otherAppUserID = "some other user"
        let currentAppUserID = "myUser"
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)
        let validCacheDate = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: validCacheDate, appUserID: otherAppUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(appUserID: currentAppUserID,
                                                         isAppBackgrounded: true)) == true
    }

    func testIsOfferingsCacheStaleDifferentCacheLengthsForBackgroundAndForeground() {
        let mockCachedObject = InMemoryCachedObject<Offerings>()

        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults,
                                       offeringsCachedObject: mockCachedObject)
        self.deviceCache.cache(offerings: .empty,
                               preferredLocales: self.preferredLocalesProvider.preferredLocales,
                               appUserID: "user")

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

    func testIsOfferingsCacheStaleIfPreferredLocalesChange() throws {
        let sampleOfferings = try Self.createSampleOfferings()
        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))

        self.deviceCache.cache(offerings: sampleOfferings, preferredLocales: ["en-US"], appUserID: "user")

        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == false
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == false

        self.preferredLocalesProvider.overridePreferredLocale("es-ES")
        // preferred locales changed to ["es-ES", "en-US"]

        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == true

        self.mockFileCache.stubSaveData(at: 1, with: .success(.init(data: .init(), url: .mockFileLocation)))
        self.deviceCache.cache(offerings: .empty, preferredLocales: ["es-ES", "en-US"], appUserID: "user")

        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == false
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == false

        self.preferredLocalesProvider.overridePreferredLocale(nil)
        // preferred locales changed back to ["en-US"]

        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: false)) == true
        expect(self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: true)) == true
    }

    func testClearCachedOfferings() {
        let mockCachedObject = MockInMemoryCachedOfferings<Offerings>()
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults,
                                       cache: self.mockFileCache,
                                       fileManager: self.fileManager,
                                       offeringsCachedObject: mockCachedObject)

        self.deviceCache.clearOfferingsCache(appUserID: "user")

        expect(mockCachedObject.invokedClearCache) == true
        expect(self.mockFileCache.removeInvocations.count) == 1
    }

    func testClearCachesRemovesOfferingsFromLargeItemCache() throws {
        let appUserID = "testUser"
        let offerings = try Self.createSampleOfferings()

        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))
        self.deviceCache.cache(offerings: offerings, preferredLocales: ["en-US"], appUserID: appUserID)

        expect(self.mockFileCache.removeInvocations.count) == 0

        self.deviceCache.clearCaches(oldAppUserID: appUserID, andSaveWithNewUserID: "newUser")

        // Verify that removeObject was called on the file cache with the correct key
        expect(self.mockFileCache.removeInvocations.count) == 1
        let expectedURL = self.mockFileCache.cacheDirectory?
            .appendingPathComponent("device-cache")
            .appendingPathComponent("com.revenuecat.userdefaults.offerings.\(appUserID)")
        expect(self.mockFileCache.removeInvocations.first) == expectedURL
    }

    func testCachedOfferingsContentsRemovesOldUserDefaultsCache() throws {
        let appUserID = "testUser"
        let offerings = try Self.createSampleOfferings()
        let offeringsKey = "com.revenuecat.userdefaults.offerings.\(appUserID)"

        // Put some data in UserDefaults to simulate old cached data
        self.mockUserDefaults.mockValues[offeringsKey] = try offerings.contents.jsonEncodedData

        self.mockFileCache.stubLoadFile(with: .success(try offerings.contents.jsonEncodedData))

        // Call cachedOfferingsContents
        _ = self.deviceCache.cachedOfferingsContents(appUserID: appUserID)

        // Verify that the old UserDefaults cache was removed
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues).to(contain(offeringsKey))
    }

    func testCachedOfferingsContentsReturnsSameContentAsSaved() throws {
        let appUserID = "testUser"
        let offerings = try Self.createSampleOfferings()

        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))
        self.mockFileCache.stubCachedContentExists(with: true)
        self.mockFileCache.stubLoadFile(with: .success(try offerings.contents.jsonEncodedData))

        // Cache the offerings
        self.deviceCache.cache(offerings: offerings, preferredLocales: ["en-US"], appUserID: appUserID)

        // Retrieve the cached offerings contents
        let cachedContents: Offerings.Contents? = self.deviceCache.cachedOfferingsContents(appUserID: appUserID)

        // Verify that the cached contents match what was saved
        expect(cachedContents).toNot(beNil())
        expect(cachedContents?.response.currentOfferingId) == offerings.contents.response.currentOfferingId
        expect(cachedContents?.response.offerings.count) == offerings.contents.response.offerings.count
    }

    func testOfferingsAreNeverSavedToUserDefaults() throws {
        let appUserID = "testUser"
        let offerings = try Self.createSampleOfferings()
        let offeringsKey = "com.revenuecat.userdefaults.offerings.\(appUserID)"

        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))

        // Cache the offerings
        self.deviceCache.cache(offerings: offerings, preferredLocales: ["en-US"], appUserID: appUserID)

        // Verify that offerings were NOT saved to UserDefaults
        expect(self.mockUserDefaults.mockValues[offeringsKey]).to(beNil())

        // Verify that offerings WERE saved to the file cache
        expect(self.mockFileCache.saveDataInvocations.count) == 1
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

    func testCacheEmptyProductEntitlementMapping() throws {
        let data = ProductEntitlementMapping(entitlementsByProduct: [:])
        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))
        self.mockFileCache.stubCachedContentExists(with: true)
        self.mockFileCache.stubLoadFile(with: .success(try data.jsonEncodedData))
        self.deviceCache.store(productEntitlementMapping: data)
        expect(self.deviceCache.cachedProductEntitlementMapping) == data
    }

    func testCacheProductEntitlementMapping() throws {
        let data = ProductEntitlementMapping(entitlementsByProduct: [
            "1": ["pro_1"],
            "2": ["pro_2"],
            "3": ["pro_1", "pro_2"]
        ])
        self.mockFileCache.stubSaveData(with: .success(.init(data: .init(), url: .mockFileLocation)))
        self.mockFileCache.stubCachedContentExists(with: true)
        self.mockFileCache.stubLoadFile(with: .success(try data.jsonEncodedData))
        self.deviceCache.store(productEntitlementMapping: data)
        expect(self.deviceCache.cachedProductEntitlementMapping) == data
    }

    func testIsProductEntitlementMappingCacheStaleWithNoDate() {
        expect(self.deviceCache.isProductEntitlementMappingCacheStale) == true
    }

    func testCacheProductEntitlementMappingUpdatesLastUpdatedDate() throws {
        self.mockFileCache.stubSaveData(with: .success(.init(data: Data(), url: .mockFileLocation)))
        self.deviceCache.store(productEntitlementMapping: .init(entitlementsByProduct: [:]))

        let key = DeviceCache.CacheKeys.productEntitlementMappingLastUpdated.rawValue
        let lastUpdated = try XCTUnwrap(self.mockUserDefaults.mockValues[key] as? Date)

        expect(lastUpdated).to(beCloseToNow())
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

    // MARK: - Virtual Currencies
    func testClearCachesForAppUserIDAndSaveNewUserIDRemovesCachedVirtualCurrencies() throws {
        let oldUserID =  "oldUserID"
        self.deviceCache.cache(virtualCurrencies: mockVirtualCurrenciesData, appUserID: oldUserID)

        self.deviceCache.clearCaches(oldAppUserID: oldUserID, andSaveWithNewUserID: "newUser")

        let expectedVCCacheKey = "com.revenuecat.userdefaults.virtualCurrencies.\(oldUserID)"
        expect(self.mockUserDefaults.removeObjectForKeyCalledValues.contains(expectedVCCacheKey)).to(beTrue())
    }

    func testVirtualCurrenciesCacheIsStaleIfNoCaches() {
        expect(self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: "user", isAppBackgrounded: false)).to(beTrue())
    }

    func testVirtualCurrenciesCacheIsStaleIfLongerThanFiveMinutes() {
        let sixMinutesAgo = Calendar.current.date(byAdding: .minute, value: -6, to: Date())!

        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )
        let appUserID = "userID"
        deviceCache.cache(virtualCurrencies: Data(), appUserID: appUserID)
        let isAppBackgrounded = false

        // Test with 6-minute old cache
        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(timestamp: sixMinutesAgo, appUserID: appUserID)
        let sixMinuteStale = self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded
        )

        expect(sixMinuteStale) == true
    }

    func testVirtualCurrenciesCacheIsNotStaleIfShorterThanFiveMinutes() {
        let oneMinuteAgo = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
        let appUserID = "appUserID"
        let isAppBackgrounded = false

        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(timestamp: oneMinuteAgo, appUserID: appUserID)

        let oneMinuteStale = self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded
        )

        expect(oneMinuteStale) == false
    }

    func testVirtualCurrenciesIsProperlyCached() throws {
        let appUserID = "appUserID"
        expect(self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID, isAppBackgrounded: false)) == true

        self.deviceCache.cache(virtualCurrencies: mockVirtualCurrenciesData, appUserID: appUserID)

        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrencies.\(appUserID)"] as? Data)
            .to(equal(mockVirtualCurrenciesData))
        expect(self.deviceCache.cachedVirtualCurrenciesData(forAppUserID: appUserID)) == mockVirtualCurrenciesData
        expect(self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID, isAppBackgrounded: false)) == false
    }

    func testNewDeviceCacheInstanceWithExistingValidVirtualCurrenciesCacheIsntStale() {
        let appUserID = "appUserID"
        let fourMinutesAgo = Calendar.current.date(byAdding: .minute, value: -4, to: Date())
        let cackeKey = "com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID)"
        mockUserDefaults.mockValues[cackeKey] = fourMinutesAgo
        self.deviceCache = DeviceCache(systemInfo: self.systemInfo,
                                       userDefaults: self.mockUserDefaults)

        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: false
        )) == false
    }

    func testNewDeviceCacheInstanceWithExistingInvalidVirtualCurrenciesCacheIsStale() {
        let appUserID = "appUserID"
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())
        mockUserDefaults.mockValues[
            "com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID)"
        ] = fourDaysAgo
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )

        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: false
        )) == true
    }

    func testNewDeviceCacheInstanceWithNoCachedVirtualCurrenciesCacheIsStale() {
        let appUserID = "appUserID"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )

        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: false
        )) == true
    }

    func testIsVirtualCurrenciesCacheStaleForBackground() {
        let appUserID = "appUserID"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )
        let outdatedCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(
            timestamp: outdatedCacheDateForBackground,
            appUserID: appUserID
        )

        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: true
        )) == true

        let validCacheDateForBackground = Calendar.current.date(byAdding: .hour, value: -15, to: Date())!
        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(
            timestamp: validCacheDateForBackground,
            appUserID: appUserID
        )

        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: true
        )) == false
    }

    func testIsVirtualCurrenciesCacheStaleForForeground() {
        let appUserID = "appUserID"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )
        let outdatedCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -25, to: Date())!
        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(
            timestamp: outdatedCacheDateForForeground,
            appUserID: appUserID
        )

        expect(self.deviceCache.isCustomerInfoCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: false
        )) == true

        let validCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(
            timestamp: validCacheDateForForeground,
            appUserID: appUserID
        )

        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: true
        )) == false
    }

    func testIsVirtualCurrenciesCacheWithCachedVCsButNoTimestamp() {
        let appUserID = "appUserID"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )

        self.deviceCache.cache(virtualCurrencies: mockVirtualCurrenciesData, appUserID: appUserID)
        expect(self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: false
        )) == false

        self.deviceCache.clearVirtualCurrenciesCacheLastUpdatedTimestamp(appUserID: appUserID)

        expect(self.deviceCache.isCustomerInfoCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: false
        )) == true
    }

    func testIsVirtualCurrenciesCacheStaleForDifferentAppUserID() {
        let otherAppUserID = "some other user"
        let currentAppUserID = "appUserID"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )
        let validCacheDate = Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
        self.deviceCache.setVirtualCurrenciesCacheLastUpdatedTimestamp(
            timestamp: validCacheDate,
            appUserID: otherAppUserID
        )

        expect(self.deviceCache.isCustomerInfoCacheStale(
            appUserID: currentAppUserID,
            isAppBackgrounded: true
        )) == true
    }

    func testClearVirtualCurrenciesCacheWorks() {
        let appUserID = "appUserID"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )

        // Cache some virtual currencies
        self.deviceCache.cache(virtualCurrencies: mockVirtualCurrenciesData, appUserID: appUserID)

        // Ensure that the VCs and last updated date were cached
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrencies.\(appUserID)"] as? Data)
            .to(equal(mockVirtualCurrenciesData))
        expect(self.deviceCache.cachedVirtualCurrenciesData(forAppUserID: appUserID)) == mockVirtualCurrenciesData
        expect(
            self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID, isAppBackgrounded: false)
        ).to(beFalse())
        expect(
            self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID)"]
        ).toNot(beNil())

        deviceCache.clearVirtualCurrenciesCache(appUserID: appUserID)

        // Ensure that cached values were removed
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrencies.\(appUserID)"] as? Data)
            .to(beNil())
        expect(
            self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID)"]
        ).to(beNil())
        expect(
            self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID, isAppBackgrounded: false)
        ).to(beTrue())
    }

    func testClearVirtualCurrenciesForOneUserDoesntClearCacheOfAnotherUser() {
        let appUserID = "appUserID"
        let appUserID2 = "appUserID2"
        self.deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults
        )

        // Cache some virtual currencies
        self.deviceCache.cache(virtualCurrencies: mockVirtualCurrenciesData, appUserID: appUserID)
        self.deviceCache.cache(virtualCurrencies: mockVirtualCurrenciesData, appUserID: appUserID2)

        // Ensure that the VCs and last updated date were cached for appUserID
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrencies.\(appUserID)"] as? Data)
            .to(equal(mockVirtualCurrenciesData))
        expect(self.deviceCache.cachedVirtualCurrenciesData(forAppUserID: appUserID)) == mockVirtualCurrenciesData
        expect(
            self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID, isAppBackgrounded: false)
        ).to(beFalse())
        expect(
            self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID)"]
        ).toNot(beNil())

        // Ensure that the VCs and last updated date were cached for appUserID2
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrencies.\(appUserID2)"] as? Data)
            .to(equal(mockVirtualCurrenciesData))
        expect(self.deviceCache.cachedVirtualCurrenciesData(forAppUserID: appUserID2)) == mockVirtualCurrenciesData
        expect(
            self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID2, isAppBackgrounded: false)
        ).to(beFalse())
        expect(
            self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID2)"]
        ).toNot(beNil())

        deviceCache.clearVirtualCurrenciesCache(appUserID: appUserID)

        // Ensure that cached values were not removed for appUserID2
        expect(self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrencies.\(appUserID2)"] as? Data)
            .to(equal(mockVirtualCurrenciesData))
        expect(self.deviceCache.cachedVirtualCurrenciesData(forAppUserID: appUserID2)) == mockVirtualCurrenciesData
        expect(
            self.deviceCache.isVirtualCurrenciesCacheStale(appUserID: appUserID2, isAppBackgrounded: false)
        ).to(beFalse())
        expect(
            self.mockUserDefaults.mockValues["com.revenuecat.userdefaults.virtualCurrenciesLastUpdated.\(appUserID2)"]
        ).toNot(beNil())
    }

    // MARK: - Migration Tests

    func testMigratesOfferingsFromOldDocumentsDirectory() throws {
        let appUserID1 = "test-user1"
        let appUserID2 = "test-user2"

        // Create old directory in documents
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let oldDirectory = documentsURL.appendingPathComponent("RevenueCat")
        let oldFileURL1 = oldDirectory.appendingPathComponent(DeviceCache.CacheKey.offerings(appUserID1).rawValue)
        let oldFileURL2 = oldDirectory.appendingPathComponent(DeviceCache.CacheKey.offerings(appUserID2).rawValue)

        // Create old documents directory and file
        try fileManager.createDirectory(
            at: oldDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let testOfferings = try Self.createSampleOfferings()
        let offeringsData = try JSONEncoder.default.encode(testOfferings.contents)
        try offeringsData.write(to: oldFileURL1)
        try offeringsData.write(to: oldFileURL2)

        // Verify old files exist
        XCTAssertTrue(fileManager.fileExists(atPath: oldFileURL1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: oldFileURL2.path))

        // swiftlint:disable:next line_length
        let newDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: .cache)?.appendingPathComponent("device-cache"))

        // Verify new directory does not exist yet
        XCTAssertFalse(fileManager.fileExists(atPath: newDirectoryURL.path))

        // Create local DeviceCache with FileManager
        let deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.makeIsolatedUserDefaults(),
            cache: fileManager
        )

        // Verify new directory is created on init of DeviceCache
        XCTAssertTrue(fileManager.fileExists(atPath: newDirectoryURL.path))

        // Retrieve cached offerings 1, old file should be removed but directory should still exist
        var cachedOfferings1: Offerings.Contents? = deviceCache.cachedOfferingsContents(appUserID: appUserID1)
        expect(cachedOfferings1).toNot(beNil())
        XCTAssertFalse(fileManager.fileExists(atPath: oldFileURL1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: oldDirectory.path))

        // Retrieve cached offerings 2, old file should be removed and old directory should be removed now
        var cachedOfferings2: Offerings.Contents? = deviceCache.cachedOfferingsContents(appUserID: appUserID2)
        expect(cachedOfferings2).toNot(beNil())
        XCTAssertFalse(fileManager.fileExists(atPath: oldFileURL2.path))
        XCTAssertFalse(fileManager.fileExists(atPath: oldDirectory.path))

        // Try fetching them from the new location
        cachedOfferings1 = deviceCache.cachedOfferingsContents(appUserID: appUserID1)
        cachedOfferings2 = deviceCache.cachedOfferingsContents(appUserID: appUserID2)
        expect(cachedOfferings1).toNot(beNil())
        expect(cachedOfferings2).toNot(beNil())
    }

    func testMigratesProductEntitlementMappingFromOldDocumentsDirectory() throws {
        // Create old directory in documents
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let oldDirectoryURL = documentsURL.appendingPathComponent("RevenueCat")

        // swiftlint:disable:next line_length
        let oldFileURL = oldDirectoryURL.appendingPathComponent(DeviceCache.CacheKeys.productEntitlementMapping.rawValue)

        // Create directory and file
        try fileManager.createDirectory(
            at: oldDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let testMapping = ProductEntitlementMapping(entitlementsByProduct: ["product1": ["entitlement1"]])
        let mappingData = try JSONEncoder.default.encode(testMapping)
        try mappingData.write(to: oldFileURL)

        // Verify old file exists
        XCTAssertTrue(fileManager.fileExists(atPath: oldFileURL.path))

        // swiftlint:disable:next line_length
        let newDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: .cache)?.appendingPathComponent("device-cache"))

        // Verify new directory does not exist yet
        XCTAssertFalse(fileManager.fileExists(atPath: newDirectoryURL.path))

        // Create local DeviceCache with FileManager
        let deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.makeIsolatedUserDefaults(),
            cache: fileManager
        )

        // Verify new directory is created on init of DeviceCache
        XCTAssertTrue(fileManager.fileExists(atPath: newDirectoryURL.path))

        // Access product entitlement mapping - should trigger migration
        let cachedMapping = deviceCache.cachedProductEntitlementMapping

        // Verify mapping was migrated and can be read
        expect(cachedMapping).toNot(beNil())
        expect(cachedMapping?.entitlementsByProduct) == testMapping.entitlementsByProduct

        // Verify old file and directory is removed since it's empty
        XCTAssertFalse(fileManager.fileExists(atPath: oldFileURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: oldDirectoryURL.path))
    }

    func testWritingOfferingsDeletesOldFileFromDocumentsDirectory() throws {
        let appUserID = "test-user"

        // Create old directory in documents
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let oldDirectory = documentsURL.appendingPathComponent("RevenueCat")
        let oldFileURL = oldDirectory.appendingPathComponent(DeviceCache.CacheKey.offerings(appUserID).rawValue)

        // Create directory and file
        try fileManager.createDirectory(
            at: oldDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let oldOfferings = try Self.createSampleOfferings()
        let oldOfferingsData = try JSONEncoder.default.encode(oldOfferings.contents)
        try oldOfferingsData.write(to: oldFileURL)

        // Verify old file exists
        XCTAssertTrue(fileManager.fileExists(atPath: oldFileURL.path))

        // Create local DeviceCache with fileManager
        let deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.makeIsolatedUserDefaults(),
            cache: fileManager
        )

        // Write new offerings, should delete old file
        let newOfferings = try Self.createSampleOfferings()
        deviceCache.cache(offerings: newOfferings, preferredLocales: ["en-US"], appUserID: appUserID)

        // Verify old file and directory is removed since it's empty
        XCTAssertFalse(fileManager.fileExists(atPath: oldFileURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: oldDirectory.path))
    }

    func testClearCachesDeletesOldOfferingsFileIfExists() throws {
        let appUserID = "test_user"
        let newUserID = "new_user"

        // Create old documents directory structure
        let documentsURL = try XCTUnwrap(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first)
        let oldDirectory = documentsURL.appendingPathComponent("RevenueCat")

        // Create offerings file for this user and another file to ensure we only delete the offerings
        let offeringsKey = DeviceCache.CacheKey.offerings(appUserID).rawValue
        let offeringsFile = oldDirectory.appendingPathComponent(offeringsKey)
        let otherFile = oldDirectory.appendingPathComponent("other-file.txt")

        try fileManager.createDirectory(at: oldDirectory, withIntermediateDirectories: true, attributes: nil)
        try "offerings data".write(to: offeringsFile, atomically: true, encoding: .utf8)
        try "other data".write(to: otherFile, atomically: true, encoding: .utf8)

        // Verify files exist
        XCTAssertTrue(fileManager.fileExists(atPath: offeringsFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: otherFile.path))

        // Call clearCaches
        let deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.makeIsolatedUserDefaults(),
            cache: fileManager
        )
        deviceCache.clearCaches(oldAppUserID: appUserID, andSaveWithNewUserID: newUserID)

        // Verify only the offerings file is deleted, other file remains
        XCTAssertFalse(fileManager.fileExists(atPath: offeringsFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: otherFile.path))
    }

    func testClearOfferingsCacheDeletesOldOfferingsFileIfExists() throws {
        let appUserID = "test_user"

        // Create old documents directory structure
        let documentsURL = try XCTUnwrap(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first)
        let oldDirectory = documentsURL.appendingPathComponent("RevenueCat")

        // Create offerings file for this user and another file to ensure we only delete the offerings
        let offeringsKey = DeviceCache.CacheKey.offerings(appUserID).rawValue
        let offeringsFile = oldDirectory.appendingPathComponent(offeringsKey)
        let otherFile = oldDirectory.appendingPathComponent("other-file.txt")

        try fileManager.createDirectory(at: oldDirectory, withIntermediateDirectories: true, attributes: nil)
        try "offerings data".write(to: offeringsFile, atomically: true, encoding: .utf8)
        try "other data".write(to: otherFile, atomically: true, encoding: .utf8)

        // Verify files exist
        XCTAssertTrue(fileManager.fileExists(atPath: offeringsFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: otherFile.path))

        // Call clearOfferingsCache
        let deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.makeIsolatedUserDefaults(),
            cache: fileManager
        )
        deviceCache.clearOfferingsCache(appUserID: appUserID)

        // Verify only the offerings file is deleted, other file remains
        XCTAssertFalse(fileManager.fileExists(atPath: offeringsFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: otherFile.path))
    }

    func testMigrationOnConcurrentReadsIsThreadSafe() throws {
        let appUserID = "test_user"

        // Create old directory in documents
        let documentsURL = try XCTUnwrap(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first)
        let oldDirectoryURL = documentsURL.appendingPathComponent("RevenueCat")
        let oldFileURL = oldDirectoryURL.appendingPathComponent(DeviceCache.CacheKey.offerings(appUserID).rawValue)

        // Create directory and file
        try fileManager.createDirectory(
            at: oldDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let testOfferings = try Self.createSampleOfferings()
        let offeringsData = try JSONEncoder.default.encode(testOfferings.contents)
        try offeringsData.write(to: oldFileURL)

        // Verify old file exists
        XCTAssertTrue(fileManager.fileExists(atPath: oldFileURL.path))

        // Create DeviceCache instance
        let deviceCache = DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.makeIsolatedUserDefaults(),
            cache: fileManager
        )

        let newDirectoryURL = try XCTUnwrap(
            DirectoryHelper.baseUrl(for: .cache)?.appendingPathComponent("device-cache")
        )
        let newFileURL = newDirectoryURL.appendingPathComponent(DeviceCache.CacheKey.offerings(appUserID).rawValue)

        // Verify new directory exists but file doesn't yet
        XCTAssertTrue(fileManager.fileExists(atPath: newDirectoryURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: newFileURL.path))

        // Trigger concurrent concurrent reads from multiple threads
        let expectation = XCTestExpectation(description: "All concurrent migrations complete")
        expectation.expectedFulfillmentCount = 10

        let dispatchGroup = DispatchGroup()

        for _ in 0..<10 {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                // Each thread tries to access the cached offerings, triggering migration (but should only migrate once)
                let cachedOfferings = deviceCache.cachedOfferingsContents(appUserID: appUserID)

                // Verify we got valid data
                expect(cachedOfferings).toNot(beNil())

                expectation.fulfill()
                dispatchGroup.leave()
            }
        }

        // Wait for all concurrent operations to complete
        let result = dispatchGroup.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success, "Concurrent migrations should complete within timeout")

        wait(for: [expectation], timeout: 5.0)

        // Verify migration succeeded
        XCTAssertTrue(fileManager.fileExists(atPath: newFileURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: oldFileURL.path))

        // Verify we can still read the migrated data
        let finalOfferings = deviceCache.cachedOfferingsContents(appUserID: appUserID)
        expect(finalOfferings).toNot(beNil())
    }
}

private extension DeviceCacheTests {

    func create() -> DeviceCache {
        return DeviceCache(
            systemInfo: self.systemInfo,
            userDefaults: self.mockUserDefaults,
            cache: self.mockFileCache
        )
    }

    func makeIsolatedUserDefaults(file: StaticString = #fileID,
                                  function: StaticString = #function,
                                  line: UInt = #line) -> UserDefaults {
        let suiteName = "DeviceCacheTests.\(file).\(function).\(line).\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        self.addTeardownBlock {
            userDefaults.removePersistentDomain(forName: suiteName)
            userDefaults.removeSuite(named: suiteName)
        }

        return userDefaults
    }

    static func createSampleOfferings() throws -> Offerings {
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
                ],
                "current_offering_ids_by_placement": {"placement_identifier": "\(offeringIdentifier)"},
            }
        """
        let offeringsData: OfferingsResponse.Offering = try JSONDecoder.default.decode(
            jsonData: offeringsJSON.asData
        )

        let offering = try XCTUnwrap(
            OfferingsFactory().createOffering(from: products,
                                              offering: offeringsData,
                                              uiConfig: nil)
        )
        return Offerings(
            offerings: [offeringIdentifier: offering],
            currentOfferingID: "base",
            placements: nil,
            targeting: nil,
            contents: Offerings.Contents(response: OfferingsResponse(currentOfferingId: "base",
                                                                     offerings: [offeringsData],
                                                                     placements: nil,
                                                                     targeting: nil,
                                                                     uiConfig: nil),
                                         httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

}

private extension Offerings {

    static let empty: Offerings = .init(
        offerings: [:],
        currentOfferingID: "",
        placements: nil,
        targeting: nil,
        contents: Offerings.Contents(response: OfferingsResponse(
            currentOfferingId: "",
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        ),
                                     httpResponseOriginalSource: .mainServer),
        loadedFromDiskCache: false
    )

}

private extension URL {
    static let mockFileLocation: URL = URL(string: "data:mock-file-location").unsafelyUnwrapped
}
