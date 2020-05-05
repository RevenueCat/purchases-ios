//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class DeviceCacheSubscriberAttributesTests: XCTestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var deviceCache: RCDeviceCache! = nil

    override func setUp() {
        self.mockUserDefaults = MockUserDefaults()
        self.deviceCache = RCDeviceCache(mockUserDefaults)
        setUpSubscriberAttributes()
    }

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
        let appUserID = "waldo"
        self.deviceCache.store(subscriberAttributeHeight, appUserID: appUserID)

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
        self.deviceCache.store(subscriberAttributeHeight, appUserID: appUserID)

        expect(self.mockUserDefaults.mockValues.count) == 1

        let subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                              value: "160",
                                                              dateProvider: mockDateProvider)
        self.deviceCache.store(subscriberAttributeWeight, appUserID: appUserID)
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
        let oldSubscriberAttribute = RCSubscriberAttribute(key: "height",
                                                           value: "183",
                                                           dateProvider: mockDateProvider)
        let appUserID = "waldo"
        self.deviceCache.store(oldSubscriberAttribute, appUserID: appUserID)

        let newSubscriberAttribute = RCSubscriberAttribute(key: "height",
                                                           value: "250",
                                                           dateProvider: mockDateProvider)
        self.deviceCache.store(newSubscriberAttribute, appUserID: appUserID)

        let expectedStoreKey = "com.revenuecat.userdefaults.subscriberAttributes"
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == expectedStoreKey

        guard let storedValue = self.mockUserDefaults.mockValues[expectedStoreKey],
            let storedDict = storedValue as? NSDictionary else {
            fatalError("didn't actually store the value or it wasn't a dictionary")
        }

        expect(self.mockUserDefaults.mockValues.count) == 1

        let expectedStoredDict = [
            appUserID: [
                newSubscriberAttribute.key: newSubscriberAttribute.asDictionary(),
            ]
        ]
        expect(storedDict) == expectedStoredDict as NSDictionary
    }

    func testStoreSubscriberAttributesStoresCorrectly() {
        let appUserID = "waldo"
        self.deviceCache.storeSubscriberAttributes([subscriberAttributeHeight.key: subscriberAttributeHeight,
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
        self.deviceCache.storeSubscriberAttributes([:], appUserID: "waldo")

        expect(self.mockUserDefaults.setObjectForKeyCalledValue).to(beNil())
        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    func testStoreSubscriberAttributesDoesNotModifyExistingValuesWithDifferentKeys() {
        let otherSubscriberAttribute = RCSubscriberAttribute(key: "age",
                                                             value: "46",
                                                             dateProvider: mockDateProvider)
        let appUserID = "waldo"
        self.deviceCache.store(otherSubscriberAttribute, appUserID: appUserID)

        self.deviceCache.storeSubscriberAttributes([subscriberAttributeHeight.key: subscriberAttributeHeight,
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
        self.deviceCache.store(subscriberAttributeHeight, appUserID: appUserID)

        let subscriberAttributeNewHeight = RCSubscriberAttribute(key: "height",
                                                                 value: "460",
                                                                 dateProvider: mockDateProvider)

        self.deviceCache.storeSubscriberAttributes([subscriberAttributeNewHeight.key: subscriberAttributeNewHeight,
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

    // mark: cleanupSubscriberAttributes

    func testCleanupSubscriberAttributesMigratesIfOldAttributesFound() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID1Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "Led Zeppelin").asDictionary(),
            "song": RCSubscriberAttribute(key: "song", value: "Whole Lotta Love").asDictionary()
        ]
        let userID2Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "Metallica").asDictionary(),
            "song": RCSubscriberAttribute(key: "song", value: "Ride the Lightning").asDictionary()
        ]
        let newSubscriberAttributes = [
            userID1: userID1Attributes,
            userID2: userID2Attributes
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes.\(userID1)": userID1Attributes,
            "com.revenuecat.userdefaults.subscriberAttributes.\(userID2)": userID2Attributes,
        ]

        deviceCache.cleanupSubscriberAttributes()
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
            "band": RCSubscriberAttribute(key: "band", value: "Led Zeppelin").asDictionary(),
            "song": RCSubscriberAttribute(key: "song", value: "Whole Lotta Love").asDictionary()
        ]
        let userID2Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "Metallica").asDictionary(),
            "song": RCSubscriberAttribute(key: "song", value: "Ride the Lightning").asDictionary()
        ]

        let valuesBeforeMigration = [
            "com.revenuecat.userdefaults.subscriberAttributes": [
                userID1: userID1Attributes,
                userID2: userID2Attributes
            ]
        ]
        mockUserDefaults.mockValues = valuesBeforeMigration

        deviceCache.cleanupSubscriberAttributes()

        let valuesAfterMigration = self.mockUserDefaults.mockValues as? [String: [String: [String: [String: NSObject]]]]
        expect(valuesBeforeMigration) == valuesAfterMigration
    }

    func testMigrateSubscriberAttributesIfNeededForAppUserDeletesOldFormatAfterFinishing() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID1Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "Led Zeppelin").asDictionary(),
            "song": RCSubscriberAttribute(key: "song", value: "Whole Lotta Love").asDictionary()
        ]
        let userID2Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "Metallica").asDictionary(),
            "song": RCSubscriberAttribute(key: "song", value: "Ride the Lightning").asDictionary()
        ]
        let userID1AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID1)"
        let userID2AttributesKey = "com.revenuecat.userdefaults.subscriberAttributes.\(userID2)"
        mockUserDefaults.mockValues = [
            userID1AttributesKey: userID1Attributes,
            userID2AttributesKey: userID2Attributes,
        ]

        self.deviceCache.cleanupSubscriberAttributes()
        self.deviceCache.cleanupSubscriberAttributes()

        expect(self.mockUserDefaults.mockValues[userID1AttributesKey]).to(beNil())
        expect(self.mockUserDefaults.mockValues[userID2AttributesKey]).to(beNil())
    }

    // mark: unsyncedAttributesForAllUsers

    func testUnsyncedAttributesByKeyForAllUsersReturnsCorrectly() {
        let attributeLedZeppelin = RCSubscriberAttribute(key: "band", value: "Led Zeppelin")
        let attributeWholeLottaLove = RCSubscriberAttribute(key: "song", value: "Whole Lotta Love")
        let attributeMetallica = RCSubscriberAttribute(key: "band", value: "Metallica")
        let attributeRideTheLightning = RCSubscriberAttribute(key: "song", value: "Ride the Lightning")
        let syncedAttribute = RCSubscriberAttribute(key: "album", value: "... And Justice for All", isSynced: true, 
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
            "song": attributeRideTheLightning,
        ]

        expect(receivedUnsyncedAttributes["userID2"]?.keys).notTo(contain("album"))
    }
    
    func testUnsyncedAttributesByKeyForAllUsersOnlyIncludesUsersWithUnsyncedAttributes() {
        let attributeLedZeppelin = RCSubscriberAttribute(key: "band", value: "Led Zeppelin")
        let attributeWholeLottaLove = RCSubscriberAttribute(key: "song", value: "Whole Lotta Love")
        let syncedAttribute = RCSubscriberAttribute(key: "album", value: "... And Justice for All", isSynced: true,
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

    // mark: deleteAttributesIfSyncedForAppUserID

    func testDeleteAttributesIfSyncedForAppUserIDDeletesIfSynced() {
        let userID = "userID"
        let subscriberAttributes = [
            userID: [
                "band": RCSubscriberAttribute(key: "band",
                                              value: "Led Zeppelin",
                                              isSynced: true,
                                              setTime: Date()).asDictionary(),
                "song": RCSubscriberAttribute(key: "song",
                                              value: "Whole Lotta Love",
                                              isSynced: true,
                                              setTime: Date()).asDictionary()
            ]
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": subscriberAttributes
        ]

        self.deviceCache.deleteAttributesIfSynced(forAppUserID: userID)

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
                "band": RCSubscriberAttribute(key: "band",
                                              value: "Led Zeppelin",
                                              isSynced: true,
                                              setTime: Date()).asDictionary(),
                "song": RCSubscriberAttribute(key: "song",
                                              value: "Whole Lotta Love",
                                              isSynced: true,
                                              setTime: Date()).asDictionary()
            ],
            userIDWithUnsyncedAttributes: [
                "band": RCSubscriberAttribute(key: "band",
                                              value: "Metallica").asDictionary()
            ]
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": subscriberAttributes
        ]

        self.deviceCache.deleteAttributesIfSynced(forAppUserID: userIDToDelete)

        let storedAttributes: [String: [String: [String: NSObject]]]? = self.mockUserDefaults.mockValues[
            "com.revenuecat.userdefaults.subscriberAttributes"
            ] as? [String: [String: [String: NSObject]]]
        expect(storedAttributes?[userIDWithUnsyncedAttributes]) == subscriberAttributes[userIDWithUnsyncedAttributes]
    }

    func testDeleteAttributesIfSyncedForAppUserIDDoesntDeleteIfNotSynced() {
        let userID = "userID"
        let subscriberAttributes = [
            userID: [
                "band": RCSubscriberAttribute(key: "band", value: "Led Zeppelin").asDictionary(),
                "song": RCSubscriberAttribute(key: "song", value: "Whole Lotta Love").asDictionary()
            ]
        ]
        mockUserDefaults.mockValues = [
            "com.revenuecat.userdefaults.subscriberAttributes": subscriberAttributes
        ]

        self.deviceCache.deleteAttributesIfSynced(forAppUserID: userID)

        let valuesAfterCallingDelete: [String: [String: [String: NSObject]]]? = mockUserDefaults
            .mockValues["com.revenuecat.userdefaults.subscriberAttributes"] as? [String: [String: [String: NSObject]]]
        expect(valuesAfterCallingDelete) == subscriberAttributes
    }
}
