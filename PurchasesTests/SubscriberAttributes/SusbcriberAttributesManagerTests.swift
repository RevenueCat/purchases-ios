//
// Created by RevenueCat on 2/28/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class SubscriberAttributesManagerTests: XCTestCase {
    var mockBackend: MockBackend!
    var mockDeviceCache: MockDeviceCache!
    var mockAttributionFetcher: MockAttributionFetcher!
    var subscriberAttributesManager: RCSubscriberAttributesManager!
    var subscriberAttributeHeight: RCSubscriberAttribute!
    var subscriberAttributeWeight: RCSubscriberAttribute!
    var mockAttributes: [String: RCSubscriberAttribute]!

    override func setUp() {
        super.setUp()
        self.mockDeviceCache = MockDeviceCache()
        self.mockBackend = MockBackend()
        self.mockAttributionFetcher = MockAttributionFetcher()
        self.subscriberAttributesManager = RCSubscriberAttributesManager(
                backend: mockBackend,
                deviceCache: mockDeviceCache,
                attributionFetcher: mockAttributionFetcher)
        self.subscriberAttributeHeight = RCSubscriberAttribute(key: "height",
                                                               value: "183")
        self.subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                               value: "160")
        self.mockAttributes = [
            subscriberAttributeHeight.key: subscriberAttributeHeight,
            subscriberAttributeWeight.key: subscriberAttributeWeight
        ]
    }

    func testInitializerCrashesIfNilParams() {
        expect(expression: {
            RCSubscriberAttributesManager(backend: nil,
                                          deviceCache: self.mockDeviceCache,
                                          attributionFetcher: self.mockAttributionFetcher)
        }
        ).to(raiseException())

        expect(expression: {
            RCSubscriberAttributesManager(backend: self.mockBackend,
                                          deviceCache: nil,
                                          attributionFetcher: self.mockAttributionFetcher)
        }).to(raiseException())

        expect(expression: {
            RCSubscriberAttributesManager(backend: self.mockBackend,
                                          deviceCache: self.mockDeviceCache,
                                          attributionFetcher: nil)
        }).to(raiseException())
    }

    // MARK: setting attributes

    func testSetAttributes() {
        self.subscriberAttributesManager.setAttributes(["genre": "blues",
                                                        "instrument": "guitar"], appUserID: "Stevie Ray Vaughan")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(beEmpty())
        var attributesByKey: [String: RCSubscriberAttribute] = [:]
        for (attribute, _) in invokedParams {
            attributesByKey[attribute.key] = attribute
        }

        expect(attributesByKey["genre"]?.key) == "genre"
        expect(attributesByKey["genre"]?.value) == "blues"
        expect(attributesByKey["genre"]?.isSynced) == false

        expect(attributesByKey["instrument"]?.key) == "instrument"
        expect(attributesByKey["instrument"]?.value) == "guitar"
        expect(attributesByKey["instrument"]?.isSynced) == false
    }

    func testSetAttributesSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "genre",
                                                                                      value: "blues")

        self.subscriberAttributesManager.setAttributes(["genre": "blues",
                                                        "instrument": "guitar"], appUserID: "Stevie Ray Vaughan")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "instrument"
        expect(receivedAttribute.value) == "guitar"
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAttributesUpdatesIfDifferentValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "genre",
                                                                                      value: "texas blues")

        self.subscriberAttributesManager.setAttributes(["genre": "blues",
                                                        "instrument": "guitar"], appUserID: "Stevie Ray Vaughan")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(beEmpty())
        var attributesByKey: [String: RCSubscriberAttribute] = [:]
        for (attribute, _) in invokedParams {
            attributesByKey[attribute.key] = attribute
        }

        expect(attributesByKey["genre"]?.key) == "genre"
        expect(attributesByKey["genre"]?.value) == "blues"
        expect(attributesByKey["genre"]?.isSynced) == false

        expect(attributesByKey["instrument"]?.key) == "instrument"
        expect(attributesByKey["instrument"]?.value) == "guitar"
        expect(attributesByKey["instrument"]?.isSynced) == false
    }

    func testSetEmail() {
        self.subscriberAttributesManager.setEmail("kratos@sparta.com", appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$email"
        expect(receivedAttribute.value) == "kratos@sparta.com"
        expect(receivedAttribute.isSynced) == false
    }

    func testSetEmailSetsEmptyIfNil() {
        self.subscriberAttributesManager.setEmail("kratos@sparta.com", appUserID: "kratos")

        self.subscriberAttributesManager.setEmail(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$email"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetEmailSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$email",
                                                                                      value: "kratos@sparta.com")

        self.subscriberAttributesManager.setEmail("kratos@sparta.com", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetEmailOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$email",
                                                                                      value: "kratos@sparta.com",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setEmail("kratos@protonmail.com", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$email"
        expect(receivedAttribute.value) == "kratos@protonmail.com"
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetPhoneNumber() {
        self.subscriberAttributesManager.setPhoneNumber("+0238320812", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$phoneNumber"
        expect(receivedAttribute.value) == "+0238320812"
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPhoneNumberSetsEmptyIfNil() {
        self.subscriberAttributesManager.setPhoneNumber("0238320812", appUserID: "kratos")

        self.subscriberAttributesManager.setPhoneNumber(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$phoneNumber"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPhoneNumberSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$displayName",
                                                                                      value: "Kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPhoneNumberOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$phoneNumber",
                                                                                      value: "9823523",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setPhoneNumber("25235325", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$phoneNumber"
        expect(receivedAttribute.value) == "25235325"
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetDisplayName() {
        self.subscriberAttributesManager.setDisplayName("Kratos", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$displayName"
        expect(receivedAttribute.value) == "Kratos"
        expect(receivedAttribute.isSynced) == false
    }

    func testSetDisplayNameSetsEmptyIfNil() {
        self.subscriberAttributesManager.setDisplayName("Kratos", appUserID: "kratos")

        self.subscriberAttributesManager.setDisplayName(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$displayName"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetDisplayNameSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: "Kratos")

        self.subscriberAttributesManager.setDisplayName("Kratos", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetDisplayNameOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$displayName",
                                                                                      value: "Kratos",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setDisplayName("Ghost of Sparta", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$displayName"
        expect(receivedAttribute.value) == "Ghost of Sparta"
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetPushToken() {
        let tokenData = "ligai32g32ig".data(using: .utf8)!
        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"

        let tokenString = (tokenData as NSData).asString()
        expect(receivedAttribute.value) == tokenString
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPushTokenSetsEmptyIfNil() {
        let tokenData = "ligai32g32ig".data(using: .utf8)!
        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        self.subscriberAttributesManager.setPushToken(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPushTokenSkipsIfSameValue() {
        let tokenData = "ligai32g32ig".data(using: .utf8)!
        let tokenString = (tokenData as NSData).asString()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: tokenString)

        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPushTokenOverwritesIfNewValue() {
        let tokenData = "ligai32g32ig".data(using: .utf8)!
        let tokenString = (tokenData as NSData).asString()
        let oldSyncTime = Date()

        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: "other value",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == tokenString
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetPushTokenString() {
        let tokenString = "oiag023jkgsop"
        self.subscriberAttributesManager.setPushTokenString(tokenString, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"

        expect(receivedAttribute.value) == tokenString
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPushTokenStringSetsEmptyIfNil() {
        let tokenString = "oiag023jkgsop"
        self.subscriberAttributesManager.setPushTokenString(tokenString, appUserID: "kratos")

        self.subscriberAttributesManager.setPushTokenString(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPushTokenStringSkipsIfSameValue() {
        let tokenString = "oiag023jkgsop"
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: tokenString)

        self.subscriberAttributesManager.setPushTokenString(tokenString, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPushTokenStringOverwritesIfNewValue() {
        let tokenString = "oiag023jkgsop"
        let oldSyncTime = Date()

        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: "other value",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setPushTokenString(tokenString, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == tokenString
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    // MARK: syncing

    func testUnsyncedAttributesByKeyReturnsResultFromDeviceCache() {
        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = [:]
        expect(self.subscriberAttributesManager.unsyncedAttributesByKey(forAppUserID: "waldo")) == [:]

        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        expect(self.subscriberAttributesManager.unsyncedAttributesByKey(forAppUserID: "waldo")) == mockAttributes
    }

    func testMarkAttributesAsSynced() {
        self.mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        self.subscriberAttributesManager.markAttributes(asSynced: mockAttributes, appUserID: "waldo")
        assertMockAttributesSynced()
    }

    func testMarkAttributesAsSyncedSkipsIfEmpty() {
        self.subscriberAttributesManager.markAttributes(asSynced: [:], appUserID: "waldo")
        expect(self.mockDeviceCache.invokedStoreSubscriberAttributesCount) == 0
    }

    // mark - sync attributes for all users

    func testSyncAttributesForAllUsersSyncsForEveryUserWithUnsyncedAttributes() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID3 = "userID3"

        let userID1Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "The Doors"),
            "song": RCSubscriberAttribute(key: "song", value: "Riders on the storm"),
            "album": RCSubscriberAttribute(key: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": RCSubscriberAttribute(key: "instrument", value: "Guitar"),
            "name": RCSubscriberAttribute(key: "name", value: "Robert Krieger")
        ]
        let userID3Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "Dire Straits"),
            "song": RCSubscriberAttribute(key: "song", value: "Sultans of Swing"),
            "album": RCSubscriberAttribute(key: "album", value: "Dire Straits")
        ]
        let allAttributes: [String: [String: RCSubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes,
            userID3: userID3Attributes,
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        subscriberAttributesManager.syncAttributesForAllUsers(withCurrentAppUserID: userID1)
        expect(self.mockBackend.invokedPostSubscriberAttributesCount) == 3

        expect(self.mockBackend.invokedPostSubscriberAttributesParametersList).to(contain(
            MockBackend.InvokedPostSubscriberAttributesParameters(subscriberAttributes: userID1Attributes,
                                                                  appUserID: userID1)))
        expect(self.mockBackend.invokedPostSubscriberAttributesParametersList).to(contain(
            MockBackend.InvokedPostSubscriberAttributesParameters(subscriberAttributes: userID2Attributes,
                                                                  appUserID: userID2)))
        expect(self.mockBackend.invokedPostSubscriberAttributesParametersList).to(contain(
            MockBackend.InvokedPostSubscriberAttributesParameters(subscriberAttributes: userID3Attributes,
                                                                  appUserID: userID3)))
    }

    func testSyncAttributesForAllUsersSyncsDeletesAttributesForOtherUsersIfSynced() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let currentUserID = "userID3"

        let userID1Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "The Doors"),
            "song": RCSubscriberAttribute(key: "song", value: "Riders on the storm"),
            "album": RCSubscriberAttribute(key: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": RCSubscriberAttribute(key: "instrument", value: "Guitar"),
            "name": RCSubscriberAttribute(key: "name", value: "Robert Krieger")
        ]
        let allAttributes: [String: [String: RCSubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes,
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        self.subscriberAttributesManager.syncAttributesForAllUsers(withCurrentAppUserID: currentUserID)
        expect(self.mockDeviceCache.invokedDeleteAttributesIfSyncedCount).toEventually(equal(2))
        expect(Set(self.mockDeviceCache.invokedDeleteAttributesIfSyncedParametersList)) == Set([userID1, userID2])
    }

    func testSyncAttributesForAllUsersDoesntDeleteAttributesForOtherUsersIfSyncFailed() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let currentUserID = "userID3"

        let userID1Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "The Doors"),
            "song": RCSubscriberAttribute(key: "song", value: "Riders on the storm"),
            "album": RCSubscriberAttribute(key: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": RCSubscriberAttribute(key: "instrument", value: "Guitar"),
            "name": RCSubscriberAttribute(key: "name", value: "Robert Krieger")
        ]
        let allAttributes: [String: [String: RCSubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes,
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        let mockError = NSError(domain: Purchases.ErrorDomain, code: 123, userInfo: [:])
        mockBackend.stubbedPostSubscriberAttributesCompletionResult = (mockError, ())

        self.subscriberAttributesManager.syncAttributesForAllUsers(withCurrentAppUserID: currentUserID)
        expect(self.mockDeviceCache.invokedDeleteAttributesIfSyncedCount).toEventually(equal(0))
    }

    func testSyncAttributesForAllUsersDoesntDeleteForCurrentUser() {
        let currentUserID = "userID1"
        let otherUserID = "userID2"

        let userID1Attributes = [
            "band": RCSubscriberAttribute(key: "band", value: "The Doors"),
            "song": RCSubscriberAttribute(key: "song", value: "Riders on the storm"),
            "album": RCSubscriberAttribute(key: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": RCSubscriberAttribute(key: "instrument", value: "Guitar"),
            "name": RCSubscriberAttribute(key: "name", value: "Robert Krieger")
        ]
        let allAttributes: [String: [String: RCSubscriberAttribute]] = [
            currentUserID: userID1Attributes,
            otherUserID: userID2Attributes,
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        self.subscriberAttributesManager.syncAttributesForAllUsers(withCurrentAppUserID: currentUserID)
        expect(self.mockDeviceCache.invokedDeleteAttributesIfSyncedCount).toEventually(equal(1))
        expect(Set(self.mockDeviceCache.invokedDeleteAttributesIfSyncedParametersList)) == Set([otherUserID])
    }
    // region AdjustID
    func testSetAdjustID() {
        let adjustID = "adjustID"
        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$adjustId"
        expect(receivedAttribute.value) == adjustID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAdjustIDSetsEmptyIfNil() {
        let adjustID = "adjustID"
        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")

        self.subscriberAttributesManager.setAdjustID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 6
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$adjustId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAdjustIDSkipsIfSameValue() {
        let adjustID = "adjustID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$adjustId", value: adjustID)

        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")


        expect(self.mockDeviceCache.invokedStoreCount) == 2
    }

    func testSetAdjustIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let adjustID = "adjustID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$adjustId",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$adjustId"
        expect(receivedAttribute.value) == adjustID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetAdjustIDSetsDeviceIdentifiers() {
        let adjustID = "adjustID"
        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 3
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList

        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region AppsflyerID
    func testSetAppsflyerID() {
        let appsflyerID = "appsflyerID"
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$appsflyerId"
        expect(receivedAttribute.value) == appsflyerID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAppsflyerIDSetsEmptyIfNil() {
        let appsflyerID = "appsflyerID"
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")

        self.subscriberAttributesManager.setAppsflyerID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 6
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$appsflyerId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetAppsflyerIDSkipsIfSameValue() {
        let appsflyerID = "appsflyerID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$appsflyerId", value: appsflyerID)
        
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
    }
    
    func testSetAppsflyerIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let appsflyerID = "appsflyerID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$appsflyerId",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$appsflyerId"
        expect(receivedAttribute.value) == appsflyerID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    
    func testSetAppsflyerIDSetsDeviceIdentifiers() {
        let appsflyerID = "appsflyerID"
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        
        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 3
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        
        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region FBAnonymousID
    func testSetFBAnonymousID() {
        let fbAnonID = "fbAnonID"
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$fbAnonId"
        expect(receivedAttribute.value) == fbAnonID
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetFBAnonymousIDSetsEmptyIfNil() {
        let fbAnonID = "fbAnonID"
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        
        self.subscriberAttributesManager.setFBAnonymousID(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 6
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$fbAnonId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetFBAnonymousIDSkipsIfSameValue() {
        let fbAnonID = "fbAnonID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$fbAnonId", value: fbAnonID)
        
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
    }
    
    func testSetFBAnonymousIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let fbAnonID = "fbAnonID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$fbAnonId",
                                                                                      value: "old_adjust_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$fbAnonId"
        expect(receivedAttribute.value) == fbAnonID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    
    func testSetFBAnonymousIDSetsDeviceIdentifiers() {
        let fbAnonID = "fbAnonID"
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        
        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 3
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        
        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region mParticle
    func testSetMparticleID() {
        let mparticleID = "mparticleID"
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$mparticleId"
        expect(receivedAttribute.value) == mparticleID
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetMparticleIDSetsEmptyIfNil() {
        let mparticleID = "mparticleID"
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        
        self.subscriberAttributesManager.setMparticleID(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 6
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$mparticleId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetMparticleIDSkipsIfSameValue() {
        let mparticleID = "mparticleID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$mparticleId", value: mparticleID)
        
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
    }
    
    func testSetMparticleIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let mparticleID = "mparticleID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$mparticleId",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$mparticleId"
        expect(receivedAttribute.value) == mparticleID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    
    func testSetMparticleIDSetsDeviceIdentifiers() {
        let mparticleID = "mparticleID"
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        
        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 3
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        
        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region OnesignalID
    func testSetOnesignalID() {
        let onesignalID = "onesignalID"
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalId"
        expect(receivedAttribute.value) == onesignalID
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetOnesignalIDSetsEmptyIfNil() {
        let onesignalID = "onesignalID"
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        
        self.subscriberAttributesManager.setOnesignalID(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 6
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetOnesignalIDSkipsIfSameValue() {
        let onesignalID = "onesignalID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$onesignalId", value: onesignalID)
        
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
    }
    
    func testSetOnesignalIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let onesignalID = "onesignalID"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$onesignalId",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalId"
        expect(receivedAttribute.value) == onesignalID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    
    func testSetOnesignalIDSetsDeviceIdentifiers() {
        let onesignalID = "onesignalID"
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 3
        
        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 3
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        
        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region Media source
    func testSetMediaSource() {
        let mediaSource = "mediaSource"
        self.subscriberAttributesManager.setMediaSource(mediaSource, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$mediaSource"
        expect(receivedAttribute.value) == mediaSource
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetMediaSourceSetsEmptyIfNil() {
        let mediaSource = "mediaSource"
        self.subscriberAttributesManager.setMediaSource(mediaSource, appUserID: "kratos")
        
        self.subscriberAttributesManager.setMediaSource(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$mediaSource"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetMediaSourceSkipsIfSameValue() {
        let mediaSource = "mediaSource"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$mediaSource", value: mediaSource)
        
        self.subscriberAttributesManager.setMediaSource(mediaSource, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }
    
    func testSetMediaSourceOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let mediaSource = "mediaSource"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$mediaSource",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setMediaSource(mediaSource, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$mediaSource"
        expect(receivedAttribute.value) == mediaSource
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    // endregion
    // region Campaign
    func testSetCampaign() {
        let campaign = "campaign"
        self.subscriberAttributesManager.setCampaign(campaign, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$campaign"
        expect(receivedAttribute.value) == campaign
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetCampaignSetsEmptyIfNil() {
        let campaign = "campaign"
        self.subscriberAttributesManager.setCampaign(campaign, appUserID: "kratos")
        
        self.subscriberAttributesManager.setCampaign(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$campaign"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetCampaignSkipsIfSameValue() {
        let campaign = "campaign"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$campaign", value: campaign)
        
        self.subscriberAttributesManager.setCampaign(campaign, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }
    
    func testSetCampaignOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let campaign = "campaign"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$campaign",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setCampaign(campaign, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$campaign"
        expect(receivedAttribute.value) == campaign
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    // endregion
    // region Ad group
    func testSetAdGroup() {
        let adGroup = "adGroup"
        self.subscriberAttributesManager.setAdGroup(adGroup, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$adGroup"
        expect(receivedAttribute.value) == adGroup
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetAdGroupSetsEmptyIfNil() {
        let adGroup = "adGroup"
        self.subscriberAttributesManager.setAdGroup(adGroup, appUserID: "kratos")
        
        self.subscriberAttributesManager.setAdGroup(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$adGroup"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetAdGroupSkipsIfSameValue() {
        let adGroup = "adGroup"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$adGroup", value: adGroup)
        
        self.subscriberAttributesManager.setAdGroup(adGroup, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }
    
    func testSetAdGroupOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let adGroup = "adGroup"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$adGroup",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setAdGroup(adGroup, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$adGroup"
        expect(receivedAttribute.value) == adGroup
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    // endregion
    // region Ad
    func testSetAd() {
        let ad = "ad"
        self.subscriberAttributesManager.setAd(ad, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$ad"
        expect(receivedAttribute.value) == ad
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetAdSetsEmptyIfNil() {
        let ad = "ad"
        self.subscriberAttributesManager.setAd(ad, appUserID: "kratos")
        
        self.subscriberAttributesManager.setAd(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$ad"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetAdSkipsIfSameValue() {
        let ad = "ad"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$ad", value: ad)
        
        self.subscriberAttributesManager.setAd(ad, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }
    
    func testSetAdOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let ad = "ad"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$ad",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setAd(ad, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$ad"
        expect(receivedAttribute.value) == ad
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    // endregion
    // region Keyword
    func testSetKeyword() {
        let keyword = "keyword"
        self.subscriberAttributesManager.setKeyword(keyword, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$keyword"
        expect(receivedAttribute.value) == keyword
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetKeywordSetsEmptyIfNil() {
        let keyword = "keyword"
        self.subscriberAttributesManager.setKeyword(keyword, appUserID: "kratos")
        
        self.subscriberAttributesManager.setKeyword(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$keyword"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetKeywordSkipsIfSameValue() {
        let keyword = "keyword"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$keyword", value: keyword)
        
        self.subscriberAttributesManager.setKeyword(keyword, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }
    
    func testSetKeywordOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let keyword = "keyword"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$keyword",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setKeyword(keyword, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$keyword"
        expect(receivedAttribute.value) == keyword
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    // endregion
    // region Creative
    func testSetCreative() {
        let creative = "creative"
        self.subscriberAttributesManager.setCreative(creative, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$creative"
        expect(receivedAttribute.value) == creative
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetCreativeSetsEmptyIfNil() {
        let creative = "creative"
        self.subscriberAttributesManager.setCreative(creative, appUserID: "kratos")
        
        self.subscriberAttributesManager.setCreative(nil, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$creative"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }
    
    func testSetCreativeSkipsIfSameValue() {
        let creative = "creative"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$creative", value: creative)
        
        self.subscriberAttributesManager.setCreative(creative, appUserID: "kratos")
        
        
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }
    
    func testSetCreativeOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let creative = "creative"
        
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$creative",
                                                                                      value: "old_id",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)
        
        self.subscriberAttributesManager.setCreative(creative, appUserID: "kratos")
        
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$creative"
        expect(receivedAttribute.value) == creative
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }
    // endregion
}

private extension SubscriberAttributesManagerTests {
    func assertMockAttributesSynced() {
        expect(self.mockDeviceCache.invokedStoreSubscriberAttributesCount).toEventually(equal(1))
        
        guard let invokedParams = self.mockDeviceCache.invokedStoreSubscriberAttributesParameters else {
            fatalError("no parameters for storeSubscriberAttributes found")
        }
        expect(invokedParams.attributesByKey).toNot(beEmpty())
        let attributesByKey = invokedParams.attributesByKey
        
        expect(attributesByKey[self.subscriberAttributeHeight.key]?.key)
            .toEventually(equal(subscriberAttributeHeight.key))
        expect(attributesByKey[self.subscriberAttributeHeight.key]?.value)
            .toEventually(equal(subscriberAttributeHeight.value))
        expect(attributesByKey[self.subscriberAttributeHeight.key]?.isSynced)
            .toEventually(equal(true))
        
        expect(attributesByKey[self.subscriberAttributeWeight.key]?.key)
            .toEventually(equal(subscriberAttributeWeight.key))
        expect(attributesByKey[self.subscriberAttributeWeight.key]?.value)
            .toEventually(equal(subscriberAttributeWeight.value))
        expect(attributesByKey[self.subscriberAttributeWeight.key]?.isSynced)
            .toEventually(equal(true))
    }

    func findInvokedAttribute(withName name: String) -> RCSubscriberAttribute {
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        guard let params = invokedParams.first(where: { $0.attribute.key == name }) else { fatalError() }
        return params.attribute
    }

    func checkDeviceIdentifiersAreSet() {
        let idfvReceived = findInvokedAttribute(withName: "$idfv")

        expect(idfvReceived.value) == "rc_idfv"
        expect(idfvReceived.isSynced) == false

        let idfaReceived = findInvokedAttribute(withName: "$idfa")

        expect(idfaReceived.value) == "rc_idfa"
        expect(idfaReceived.isSynced) == false

        let ipReceived = findInvokedAttribute(withName: "$ip")

        expect(ipReceived.value) == "true"
        expect(ipReceived.isSynced) == false
    }
}
