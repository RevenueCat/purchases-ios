//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class DeviceCacheSubscriberAttributesTests: TestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var deviceCache: DeviceCache! = nil

    override func setUp() {
        super.setUp()

        UserDefaults.resetStandardUserDefaults()
        self.mockUserDefaults = MockUserDefaults()
        self.deviceCache = DeviceCache(sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(),
                                       userDefaults: self.mockUserDefaults)

        self.mockDateProvider = MockDateProvider(stubbedNow: self.now)
        self.subscriberAttributeHeight = SubscriberAttribute(withKey: "height",
                                                             value: "183",
                                                             dateProvider: self.mockDateProvider)
        self.subscriberAttributeWeight = SubscriberAttribute(withKey: "weight",
                                                             value: "160",
                                                             dateProvider: self.mockDateProvider)
    }

    private var now = Date(timeIntervalSince1970: 2_000_000_000) // 2033-05-18 03:33:20Z
    private var mockDateProvider: MockDateProvider!
    private var subscriberAttributeHeight: SubscriberAttribute!
    private var subscriberAttributeWeight: SubscriberAttribute!

    func testStoreSubscriberAttributeStoresCorrectly() {
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttribute: subscriberAttributeHeight, appUserID: appUserID)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
              let storedDict = storedValue as? NSDictionary else {
                  fatalError("didn't actually store the value or it wasn't a dictionary")
              }
        let expectedStoredDict = [
            appUserID: [
                self.subscriberAttributeHeight.key: subscriberAttributeHeight.asDictionary()
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testStoreSubscriberAttributeDoesNotModifyExistingValuesWithDifferentKeys() {
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttribute: subscriberAttributeHeight, appUserID: appUserID)

        expect(self.mockUserDefaults.mockValues.count) == 1

        let subscriberAttributeWeight = SubscriberAttribute(withKey: "weight",
                                                            value: "160",
                                                            dateProvider: mockDateProvider)
        self.deviceCache.store(subscriberAttribute: subscriberAttributeWeight, appUserID: appUserID)
        expect(self.mockUserDefaults.mockValues.count) == 1

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
              let storedDict = storedValue as? NSDictionary else {
                  fatalError("didn't actually store the value or it wasn't a dictionary")
              }
        let expectedStoredDict = [
            appUserID: [
                subscriberAttributeWeight.key: subscriberAttributeWeight.asDictionary(),
                subscriberAttributeHeight.key: subscriberAttributeHeight.asDictionary()
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testStoreSubscriberAttributeUpdatesExistingValue() {
        let oldSubscriberAttribute = SubscriberAttribute(withKey: "height",
                                                         value: "183",
                                                         dateProvider: mockDateProvider)
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttribute: oldSubscriberAttribute, appUserID: appUserID)

        let newSubscriberAttribute = SubscriberAttribute(withKey: "height",
                                                         value: "250",
                                                         dateProvider: mockDateProvider)
        self.deviceCache.store(subscriberAttribute: newSubscriberAttribute, appUserID: appUserID)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
              let storedDict = storedValue as? NSDictionary else {
                  fatalError("didn't actually store the value or it wasn't a dictionary")
              }

        expect(self.mockUserDefaults.mockValues.count) == 1

        let expectedStoredDict = [
            appUserID: [
                newSubscriberAttribute.key: newSubscriberAttribute.asDictionary()
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testStoreSubscriberAttributesStoresCorrectly() {
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttributesByKey: [subscriberAttributeHeight.key: subscriberAttributeHeight,
                                                           subscriberAttributeWeight.key: subscriberAttributeWeight],
                               appUserID: appUserID)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
              let storedDict = storedValue as? NSDictionary else {
                  fatalError("didn't actually store the value or it wasn't a dictionary")
              }
        let expectedStoredDict = [
            appUserID: [
                subscriberAttributeWeight.key: subscriberAttributeWeight.asDictionary(),
                subscriberAttributeHeight.key: subscriberAttributeHeight.asDictionary()
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testStoreSubscriberAttributesNoOpIfAttributesDictIsEmpty() {
        self.deviceCache.store(subscriberAttributesByKey: [:], appUserID: "waldo")

        expect(self.mockUserDefaults.setObjectForKeyCalledValue).to(beNil())
        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    func testStoreSubscriberAttributesDoesNotModifyExistingValuesWithDifferentKeys() {
        let otherSubscriberAttribute = SubscriberAttribute(withKey: "age",
                                                           value: "46",
                                                           dateProvider: mockDateProvider)
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttribute: otherSubscriberAttribute, appUserID: appUserID)

        self.deviceCache.store(subscriberAttributesByKey: [subscriberAttributeHeight.key: subscriberAttributeHeight,
                                                           subscriberAttributeWeight.key: subscriberAttributeWeight],
                               appUserID: appUserID)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
              let storedDict = storedValue as? NSDictionary else {
                  fatalError("didn't actually store the value or it wasn't a dictionary")
              }

        let expectedStoredDict = [
            appUserID: [
                subscriberAttributeWeight.key: subscriberAttributeWeight.asDictionary(),
                subscriberAttributeHeight.key: subscriberAttributeHeight.asDictionary(),
                otherSubscriberAttribute.key: otherSubscriberAttribute.asDictionary()
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testStoreSubscriberAttributesUpdatesExistingValue() {
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttribute: subscriberAttributeHeight, appUserID: appUserID)

        let subscriberAttributeNewHeight = SubscriberAttribute(withKey: "height",
                                                               value: "460",
                                                               dateProvider: mockDateProvider)

        self.deviceCache.store(subscriberAttributesByKey:
                                [subscriberAttributeNewHeight.key: subscriberAttributeNewHeight,
                                 subscriberAttributeWeight.key: subscriberAttributeWeight],
                               appUserID: appUserID)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey
        expect(self.mockUserDefaults.mockValues.count) == 1

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
              let storedDict = storedValue as? NSDictionary else {
                  fatalError("didn't actually store the value or it wasn't a dictionary")
              }

        let expectedStoredDict = [
            appUserID: [
                subscriberAttributeWeight.key: subscriberAttributeWeight.asDictionary(),
                subscriberAttributeHeight.key: subscriberAttributeNewHeight.asDictionary()
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testSubscriberAttributeWithKeyReturnsCorrectly() {
        self.deviceCache.store(subscriberAttribute: subscriberAttributeHeight, appUserID: "waldo")

        let storedAttribute = self.deviceCache.subscriberAttribute(attributeKey: subscriberAttributeHeight.key,
                                                                   appUserID: "waldo")

        expect(storedAttribute).toNot(beNil())

        expect(storedAttribute).to(equal(subscriberAttributeHeight))
    }

    func testSubscriberAttributeWithKeyReturnsNilIfNotFound() {
        expect(self.deviceCache.subscriberAttribute(attributeKey: "doesn't exist", appUserID: "whoever")).to(beNil())
    }

    func testUnsyncedAttributesByKeyReturnsEmptyIfNoneStored() {
        expect(self.deviceCache.unsyncedAttributesByKey(appUserID: "waldo")).to(beEmpty())
    }

    func testUnsyncedAttributesByKeyReturnsEmptyIfNoneUnsynced() {
        subscriberAttributeHeight.isSynced = true
        self.deviceCache.store(subscriberAttribute: subscriberAttributeHeight, appUserID: "waldo")
        expect(self.deviceCache.unsyncedAttributesByKey(appUserID: "waldo")).to(beEmpty())
    }

    func testUnsyncedAttributesByKeyReturnsCorrectlyWhenFound() {
        let subscriberAttribute1 = SubscriberAttribute(withKey: "height",
                                                       value: "460",
                                                       isSynced: true,
                                                       setTime: now)

        let subscriberAttribute2 = SubscriberAttribute(withKey: "weight",
                                                       value: "120",
                                                       isSynced: false,
                                                       setTime: now)

        let subscriberAttribute3 = SubscriberAttribute(withKey: "age",
                                                       value: "66",
                                                       isSynced: false,
                                                       setTime: now)
        let subscriberAttribute4 = SubscriberAttribute(withKey: "device",
                                                       value: "iPhone",
                                                       isSynced: true,
                                                       setTime: now)

        self.deviceCache.store(subscriberAttributesByKey: [subscriberAttribute1.key: subscriberAttribute1,
                                                           subscriberAttribute2.key: subscriberAttribute2,
                                                           subscriberAttribute3.key: subscriberAttribute3,
                                                           subscriberAttribute4.key: subscriberAttribute4],
                               appUserID: "waldo")
        let receivedUnsyncedAttributes = self.deviceCache.unsyncedAttributesByKey(appUserID: "waldo")
        expect(receivedUnsyncedAttributes).toNot(beEmpty())
        expect(receivedUnsyncedAttributes.count) == 2
        expect(receivedUnsyncedAttributes[subscriberAttribute2.key]).to(equal(subscriberAttribute2))
        expect(receivedUnsyncedAttributes[subscriberAttribute3.key]).to(equal(subscriberAttribute3))
    }

    func testNumberOfUnsyncedAttributesReturnsEmptyIfNoneStored() {
        expect(self.deviceCache.numberOfUnsyncedAttributes(appUserID: "waldo")) == 0
    }

    func testNumberOfUnsyncedAttributesReturnsEmptyIfNoneUnsynced() {
        subscriberAttributeHeight.isSynced = true
        self.deviceCache.store(subscriberAttribute: subscriberAttributeHeight, appUserID: "waldo")
        expect(self.deviceCache.numberOfUnsyncedAttributes(appUserID: "waldo")) == 0
    }

    func testNumberOfUnsyncedAttributesReturnsCorrectlyWhenFound() {
        let subscriberAttribute1 = SubscriberAttribute(withKey: "height",
                                                       value: "460",
                                                       isSynced: true,
                                                       setTime: now)

        let subscriberAttribute2 = SubscriberAttribute(withKey: "weight",
                                                       value: "120",
                                                       isSynced: false,
                                                       setTime: now)

        let subscriberAttribute3 = SubscriberAttribute(withKey: "age",
                                                       value: "66",
                                                       isSynced: false,
                                                       setTime: now)
        let subscriberAttribute4 = SubscriberAttribute(withKey: "device",
                                                       value: "iPhone",
                                                       isSynced: true,
                                                       setTime: now)

        self.deviceCache.store(subscriberAttributesByKey: [subscriberAttribute1.key: subscriberAttribute1,
                                                           subscriberAttribute2.key: subscriberAttribute2,
                                                           subscriberAttribute3.key: subscriberAttribute3,
                                                           subscriberAttribute4.key: subscriberAttribute4],
                               appUserID: "waldo")
        expect(self.deviceCache.numberOfUnsyncedAttributes(appUserID: "waldo")) == 2
    }

    // MARK: cleanupSubscriberAttributes

    func testCleanupSubscriberAttributesMigratesIfOldAttributesFound() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Led Zeppelin").asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Whole Lotta Love").asDictionary()
        ]
        let userID2Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Metallica").asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Ride the Lightning").asDictionary()
        ]
        let newSubscriberAttributes = [
            userID1: userID1Attributes,
            userID2: userID2Attributes
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes.\(userID1)": userID1Attributes,
            "com.revenuecat.userdefaults.subscriberAttributes.\(userID2)": userID2Attributes,
            "com.revenuecat.userdefaults.appUserID.new": userID1
        ]

        deviceCache.cleanupSubscriberAttributes()

        let storedAttributes = self.mockUserDefaults.mockValues[
            "com.revenuecat.userdefaults.subscriberAttributes"
        ] as? [String: [String: [String: NSObject]]]

        expect(storedAttributes) == newSubscriberAttributes
    }

    func testCleanupSubscriberAttributesSkipsIfNoOldAttributesFound() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Led Zeppelin").asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Whole Lotta Love").asDictionary()
        ]
        let userID2Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Metallica").asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Ride the Lightning").asDictionary()
        ]

        let subscriberAttributesNewKey = "com.revenuecat.userdefaults.subscriberAttributes"
        let appUserIDKey = "com.revenuecat.userdefaults.appUserID.new"
        let valuesBeforeMigration = [
            subscriberAttributesNewKey: [
                userID1: userID1Attributes,
                userID2: userID2Attributes
            ],
            appUserIDKey: userID1
        ] as [String: AnyObject]
        mockUserDefaults.mockValues = valuesBeforeMigration

        deviceCache.cleanupSubscriberAttributes()

        expect(valuesBeforeMigration[subscriberAttributesNewKey] as? [String: [String: NSDictionary]])
        == mockUserDefaults.mockValues[subscriberAttributesNewKey] as? [String: [String: NSDictionary]]

        expect(valuesBeforeMigration[appUserIDKey] as? String) ==
        mockUserDefaults.mockValues[appUserIDKey] as? String
    }

    func testCleanupSubscriberAttributesDeletesOldFormatAfterFinishing() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Led Zeppelin").asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Whole Lotta Love").asDictionary()
        ]
        let userID2Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Metallica").asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Ride the Lightning").asDictionary()
        ]
        let userID1AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID1)"
        let userID2AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID2)"
        mockUserDefaults.mockValues = [
            userID1AttributesKey: userID1Attributes,
            userID2AttributesKey: userID2Attributes,
            "com.revenuecat.userdefaults.appUserID.new": userID1
        ]

        self.deviceCache.cleanupSubscriberAttributes()

        expect(self.mockUserDefaults.mockValues[userID1AttributesKey]).to(beNil())
        expect(self.mockUserDefaults.mockValues[userID2AttributesKey]).to(beNil())
    }

    func testCleanupSubscriberAttributesMergesAttributesInOldAndNewFormat() {
        let userID = "userID"

        let legacyAttributeBand = SubscriberAttribute(withKey: "band", value: "Led Zeppelin")
        let legacyAttributeSong = SubscriberAttribute(withKey: "song", value: "Whole Lotta Love")
        let legacyFormatAttributes = [
            legacyAttributeBand.key: legacyAttributeBand.asDictionary(),
            legacyAttributeSong.key: legacyAttributeSong.asDictionary()
        ]
        let newAttributeBand = SubscriberAttribute(withKey: "band", value: "Metallica")
        let newAttributeDrummer = SubscriberAttribute(withKey: "drummer", value: "Lars Ulrich")
        let newFormatAttributes = [
            newAttributeBand.key: newAttributeBand.asDictionary(),
            newAttributeDrummer.key: newAttributeDrummer.asDictionary()
        ]
        let legacyAttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID)"
        let newAttributesKey = "com.revenuecat.userdefaults.subscriberAttributes"
        let appUserIDKey = "com.revenuecat.userdefaults.appUserID.new"

        mockUserDefaults.mockValues = [
            legacyAttributesKey: legacyFormatAttributes,
            newAttributesKey: [userID: newFormatAttributes],
            appUserIDKey: userID
        ]

        self.deviceCache.cleanupSubscriberAttributes()

        let receivedAttributes: [String: [String: NSObject]]? =
        self.mockUserDefaults.mockValues[newAttributesKey] as? [String: [String: NSObject]]
        expect(receivedAttributes?[userID]).toNot(beNil())

        let expectedAttributes: [String: [String: NSObject]] = [
            newAttributeBand.key: newAttributeBand.asDictionary(),
            newAttributeDrummer.key: newAttributeDrummer.asDictionary(),
            legacyAttributeSong.key: legacyAttributeSong.asDictionary()
        ]

        expect(receivedAttributes?[userID] as? [String: [String: NSObject]]) == expectedAttributes
    }

    func testCleanupSubscriberAttributesDeletesSyncedAttributesForOtherUsers() throws {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let currentUserID = "currentUserID"
        let date = Date()
        let unsyncedAttribute = SubscriberAttribute(
            withKey: "song",
            value: "Ride the Lightning",
            isSynced: false,
            setTime: date
        )
        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Led Zeppelin", isSynced: true, setTime: date)
                .asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Whole Lotta Love", isSynced: true, setTime: date)
                .asDictionary()
        ]
        let userID2Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Metallica", isSynced: true, setTime: date)
                .asDictionary(),
            unsyncedAttribute.key: unsyncedAttribute.asDictionary()
        ]

        let userID1AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID1)"
        let userID2AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID2)"
        mockUserDefaults.mockValues = [
            userID1AttributesKey: userID1Attributes,
            userID2AttributesKey: userID2Attributes,
            "com.revenuecat.userdefaults.appUserID.new": currentUserID
        ]

        self.deviceCache.cleanupSubscriberAttributes()

        let subscriberAttributesNewKey = "com.revenuecat.userdefaults.subscriberAttributes"
        let receivedAttributes = mockUserDefaults.mockValues[subscriberAttributesNewKey]
        let unwrappedAttributes = try XCTUnwrap(receivedAttributes as? [String: [String: NSObject]])

        expect(unwrappedAttributes[userID1]).to(beNil())
        expect(unwrappedAttributes[userID2]).toNot(beNil())
        expect(unwrappedAttributes[userID2]?[unsyncedAttribute.key] as? [String: NSObject]) ==
        unsyncedAttribute.asDictionary()
    }

    func testCleanupSubscriberAttributesDoesntDeleteSyncedAttributesForCurrentUser() throws {
        let userID1 = "userID1"
        let currentUserID = "currentUserID"
        let date = Date()
        let unsyncedAttribute = SubscriberAttribute(
            withKey: "song",
            value: "Ride the Lightning",
            isSynced: false,
            setTime: date
        )
        let syncedAttribute = SubscriberAttribute(withKey: "band", value: "Metallica", isSynced: true, setTime: date)
        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Led Zeppelin", isSynced: true, setTime: date)
                .asDictionary(),
            "song": SubscriberAttribute(withKey: "song", value: "Whole Lotta Love", isSynced: true, setTime: date)
                .asDictionary()
        ]
        let currentUserIDAttributes = [
            syncedAttribute.key: syncedAttribute.asDictionary(),
            unsyncedAttribute.key: unsyncedAttribute.asDictionary()
        ]

        let userID1AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID1)"
        let currentUserIDAttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(currentUserID)"
        mockUserDefaults.mockValues = [
            userID1AttributesKey: userID1Attributes,
            currentUserIDAttributesKey: currentUserIDAttributes,
            "com.revenuecat.userdefaults.appUserID.new": currentUserID
        ]

        self.deviceCache.cleanupSubscriberAttributes()

        let subscriberAttributesNewKey = "com.revenuecat.userdefaults.subscriberAttributes"
        let receivedAttributes = mockUserDefaults.mockValues[subscriberAttributesNewKey]
        let unwrappedAttributes = try XCTUnwrap(receivedAttributes as? [String: [String: NSObject]])

        expect(unwrappedAttributes[userID1]).to(beNil())
        expect(unwrappedAttributes[currentUserID]).toNot(beNil())
        expect(unwrappedAttributes[currentUserID]?[unsyncedAttribute.key] as? [String: NSObject]) ==
        unsyncedAttribute.asDictionary()
        expect(unwrappedAttributes[currentUserID]?[syncedAttribute.key] as? [String: NSObject]) ==
        syncedAttribute.asDictionary()
    }

    // MARK: unsyncedAttributesForAllUsers

    func testUnsyncedAttributesByKeyForAllUsersReturnsCorrectly() {
        let attributeLedZeppelin = SubscriberAttribute(withKey: "band", value: "Led Zeppelin")
        let attributeWholeLottaLove = SubscriberAttribute(withKey: "song", value: "Whole Lotta Love")
        let attributeMetallica = SubscriberAttribute(withKey: "band", value: "Metallica")
        let attributeRideTheLightning = SubscriberAttribute(withKey: "song", value: "Ride the Lightning")
        let syncedAttribute = SubscriberAttribute(withKey: "album", value: "... And Justice for All", isSynced: true,
                                                  setTime: Date())
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": [
                "userID1": [
                    "band": attributeLedZeppelin.asDictionary(),
                    "song": attributeWholeLottaLove.asDictionary()
                ],
                "userID2": [
                    "band": attributeMetallica.asDictionary(),
                    "song": attributeRideTheLightning.asDictionary(),
                    "album": syncedAttribute.asDictionary()
                ]
            ]
        ]
        let receivedUnsyncedAttributes = self.deviceCache.unsyncedAttributesForAllUsers()
        expect(receivedUnsyncedAttributes["userID1"]) == [
            "band": attributeLedZeppelin,
            "song": attributeWholeLottaLove
        ]

        expect(receivedUnsyncedAttributes["userID2"]) == [
            "band": attributeMetallica,
            "song": attributeRideTheLightning
        ]

        expect(receivedUnsyncedAttributes["userID2"]?.keys).notTo(contain("album"))
    }

    func testUnsyncedAttributesByKeyForAllUsersOnlyIncludesUsersWithUnsyncedAttributes() {
        let attributeLedZeppelin = SubscriberAttribute(withKey: "band", value: "Led Zeppelin")
        let attributeWholeLottaLove = SubscriberAttribute(withKey: "song", value: "Whole Lotta Love")
        let syncedAttribute = SubscriberAttribute(withKey: "album", value: "... And Justice for All", isSynced: true,
                                                  setTime: Date())
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": [
                "userID1": [
                    "band": attributeLedZeppelin.asDictionary(),
                    "song": attributeWholeLottaLove.asDictionary()
                ],
                "userID2": [
                    "album": syncedAttribute.asDictionary()
                ]
            ]
        ]
        let receivedUnsyncedAttributes = self.deviceCache.unsyncedAttributesForAllUsers()
        expect(receivedUnsyncedAttributes["userID1"]) == [
            "band": attributeLedZeppelin,
            "song": attributeWholeLottaLove
        ]
        expect(receivedUnsyncedAttributes["userID2"]).to(beNil())
    }

    // MARK: deleteAttributesIfSyncedForAppUserID

    func testDeleteAttributesIfSyncedForAppUserIDDeletesIfSynced() {
        let userID = "userID"
        let subscriberAttributes = [
            userID: [
                "band": SubscriberAttribute(withKey: "band",
                                            value: "Led Zeppelin",
                                            isSynced: true,
                                            setTime: Date()).asDictionary(),
                "song": SubscriberAttribute(withKey: "song",
                                            value: "Whole Lotta Love",
                                            isSynced: true,
                                            setTime: Date()).asDictionary()
            ]
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": subscriberAttributes
        ]

        self.deviceCache.deleteAttributesIfSynced(appUserID: userID)

        let storedAttributes: [String: [String: [String: NSObject]]]? = self.mockUserDefaults.mockValues[
            "com.revenuecat.userdefaults.subscriberAttributes"
        ] as? [String: [String: [String: NSObject]]]
        expect(storedAttributes?["userID"]).to(beNil())
    }

    func testDeleteAttributesIfSyncedForAppUserIDDoesntAffectOtherUserIDs() {
        let userIDToDelete = "userIDToDelete"
        let userIDWithUnsyncedAttributes = "userIDWithUnsyncedAttributes"
        let subscriberAttributes: [String: [String: [String: NSObject]]] = [
            userIDToDelete: [
                "band": SubscriberAttribute(withKey: "band",
                                            value: "Led Zeppelin",
                                            isSynced: true,
                                            setTime: Date()).asDictionary(),
                "song": SubscriberAttribute(withKey: "song",
                                            value: "Whole Lotta Love",
                                            isSynced: true,
                                            setTime: Date()).asDictionary()
            ],
            userIDWithUnsyncedAttributes: [
                "band": SubscriberAttribute(withKey: "band",
                                            value: "Metallica").asDictionary()
            ]
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": subscriberAttributes
        ]

        self.deviceCache.deleteAttributesIfSynced(appUserID: userIDToDelete)

        let storedAttributes: [String: [String: [String: NSObject]]]? = self.mockUserDefaults.mockValues[
            "com.revenuecat.userdefaults.subscriberAttributes"
        ] as? [String: [String: [String: NSObject]]]
        expect(storedAttributes?[userIDWithUnsyncedAttributes]) == subscriberAttributes[userIDWithUnsyncedAttributes]
    }

    func testDeleteAttributesIfSyncedForAppUserIDDoesntDeleteIfNotSynced() {
        let userID = "userID"
        let subscriberAttributes = [
            userID: [
                "band": SubscriberAttribute(withKey: "band", value: "Led Zeppelin").asDictionary(),
                "song": SubscriberAttribute(withKey: "song", value: "Whole Lotta Love").asDictionary()
            ]
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": subscriberAttributes
        ]

        self.deviceCache.deleteAttributesIfSynced(appUserID: userID)

        let valuesAfterCallingDelete: [String: [String: [String: NSObject]]]? = mockUserDefaults
            .mockValues["com.revenuecat.userdefaults.subscriberAttributes"] as? [String: [String: [String: NSObject]]]
        expect(valuesAfterCallingDelete) == subscriberAttributes
    }
}
