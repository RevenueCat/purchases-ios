//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// Created by RevenueCat on 2/28/20.
//

import Nimble
import XCTest

@testable import RevenueCat

class SubscriberAttributesManagerTests: TestCase {

    var mockBackend: MockBackend!
    var mockDeviceCache: MockDeviceCache!
    var mockAttributionFetcher: MockAttributionFetcher!
    var mockAttributionDataMigrator: MockAttributionDataMigrator!
    var subscriberAttributesManager: SubscriberAttributesManager!
    var subscriberAttributeHeight: SubscriberAttribute!
    var subscriberAttributeWeight: SubscriberAttribute!
    var mockAttributes: [String: SubscriberAttribute]!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let platformInfo = Purchases.PlatformInfo(flavor: "iOS", version: "3.2.1")
        let systemInfo = MockSystemInfo(platformInfo: platformInfo, finishTransactions: true)

        self.mockDeviceCache = MockDeviceCache(systemInfo: systemInfo)
        self.mockBackend = MockBackend()
        self.mockAttributionFetcher = MockAttributionFetcher(attributionFactory: AttributionTypeFactory(),
                                                             systemInfo: systemInfo)
        self.mockAttributionDataMigrator = MockAttributionDataMigrator()
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: true
        )
        self.subscriberAttributeHeight = SubscriberAttribute(withKey: "height",
                                                             value: "183")
        self.subscriberAttributeWeight = SubscriberAttribute(withKey: "weight",
                                                             value: "160")
        self.mockAttributes = [
            subscriberAttributeHeight.key: subscriberAttributeHeight,
            subscriberAttributeWeight.key: subscriberAttributeWeight
        ]
    }

    // MARK: setting attributes

    func testSetAttributes() {
        self.subscriberAttributesManager.setAttributes(["genre": "blues",
                                                        "instrument": "guitar"], appUserID: "Stevie Ray Vaughan")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(beEmpty())
        var attributesByKey: [String: SubscriberAttribute] = [:]
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
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "genre",
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
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "genre",
                                                                                    value: "texas blues")

        self.subscriberAttributesManager.setAttributes(["genre": "blues",
                                                        "instrument": "guitar"], appUserID: "Stevie Ray Vaughan")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(beEmpty())
        var attributesByKey: [String: SubscriberAttribute] = [:]
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
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$email",
                                                                                    value: "kratos@sparta.com")

        self.subscriberAttributesManager.setEmail("kratos@sparta.com", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetEmailOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$email",
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
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$displayName",
                                                                                    value: "Kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPhoneNumberOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$phoneNumber",
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
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$apnsTokens",
                                                                                    value: "Kratos")

        self.subscriberAttributesManager.setDisplayName("Kratos", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetDisplayNameOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$displayName",
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
        let tokenData = "ligai32g32ig".asData
        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"

        expect(receivedAttribute.value) == tokenData.asString
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPushTokenSetsEmptyIfNil() {
        let tokenData = "ligai32g32ig".asData
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
        let tokenData = "ligai32g32ig".asData
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$apnsTokens",
                                                                                    value: tokenData.asString)

        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPushTokenOverwritesIfNewValue() {
        let tokenData = "ligai32g32ig".asData
        let oldSyncTime = Date()

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$apnsTokens",
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
        expect(receivedAttribute.value) == tokenData.asString
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
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$apnsTokens",
                                                                                    value: tokenString)

        self.subscriberAttributesManager.setPushTokenString(tokenString, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPushTokenStringOverwritesIfNewValue() {
        let tokenString = "oiag023jkgsop"
        let oldSyncTime = Date()

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$apnsTokens",
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
        expect(self.subscriberAttributesManager.unsyncedAttributesByKey(appUserID: "waldo")) == [:]

        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        expect(self.subscriberAttributesManager.unsyncedAttributesByKey(appUserID: "waldo")) == mockAttributes
    }

    func testMarkAttributesAsSynced() {
        self.mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        self.subscriberAttributesManager.markAttributesAsSynced(_: mockAttributes, appUserID: "waldo")
        assertMockAttributesSynced()
    }

    func testMarkAttributesAsSyncedSkipsIfEmpty() {
        self.subscriberAttributesManager.markAttributesAsSynced(_: [:], appUserID: "waldo")
        expect(self.mockDeviceCache.invokedStoreSubscriberAttributesCount) == 0
    }

    // MARK: - sync attributes for all users

    func testSyncAttributesForAllUsersSyncsForEveryUserWithUnsyncedAttributes() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let userID3 = "userID3"

        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "The Doors"),
            "song": SubscriberAttribute(withKey: "song", value: "Riders on the storm"),
            "album": SubscriberAttribute(withKey: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": SubscriberAttribute(withKey: "instrument", value: "Guitar"),
            "name": SubscriberAttribute(withKey: "name", value: "Robert Krieger")
        ]
        let userID3Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "Dire Straits"),
            "song": SubscriberAttribute(withKey: "song", value: "Sultans of Swing"),
            "album": SubscriberAttribute(withKey: "album", value: "Dire Straits")
        ]
        let allAttributes: [String: [String: SubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes,
            userID3: userID3Attributes
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: userID1)
        expect(self.mockBackend.invokedPostSubscriberAttributesCount) == 3

        expect(self.mockBackend.invokedPostSubscriberAttributesParametersList).to(contain(
            MockBackend.InvokedPostSubscriberAttributesParams(subscriberAttributes: userID1Attributes,
                                                              appUserID: userID1)))
        expect(self.mockBackend.invokedPostSubscriberAttributesParametersList).to(contain(
            MockBackend.InvokedPostSubscriberAttributesParams(subscriberAttributes: userID2Attributes,
                                                              appUserID: userID2)))
        expect(self.mockBackend.invokedPostSubscriberAttributesParametersList).to(contain(
            MockBackend.InvokedPostSubscriberAttributesParams(subscriberAttributes: userID3Attributes,
                                                              appUserID: userID3)))
    }

    func testSyncAttributesForAllUsersSyncsDeletesAttributesForOtherUsersIfSynced() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let currentUserID = "userID3"

        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "The Doors"),
            "song": SubscriberAttribute(withKey: "song", value: "Riders on the storm"),
            "album": SubscriberAttribute(withKey: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": SubscriberAttribute(withKey: "instrument", value: "Guitar"),
            "name": SubscriberAttribute(withKey: "name", value: "Robert Krieger")
        ]
        let allAttributes: [String: [String: SubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: currentUserID)
        expect(self.mockDeviceCache.invokedDeleteAttributesIfSyncedCount).toEventually(equal(2))
        expect(Set(self.mockDeviceCache.invokedDeleteAttributesIfSyncedParametersList)) == Set([userID1, userID2])
    }

    func testSyncAttributesForAllUsersDoesntDeleteAttributesForOtherUsersIfSyncFailed() {
        let userID1 = "userID1"
        let userID2 = "userID2"
        let currentUserID = "userID3"

        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "The Doors"),
            "song": SubscriberAttribute(withKey: "song", value: "Riders on the storm"),
            "album": SubscriberAttribute(withKey: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": SubscriberAttribute(withKey: "instrument", value: "Guitar"),
            "name": SubscriberAttribute(withKey: "name", value: "Robert Krieger")
        ]
        let allAttributes: [String: [String: SubscriberAttribute]] = [
            userID1: userID1Attributes,
            userID2: userID2Attributes
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        let mockError: BackendError = .missingAppUserID()
        mockBackend.stubbedPostSubscriberAttributesCompletionResult = .failure(mockError)

        self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: currentUserID)
        expect(self.mockDeviceCache.invokedDeleteAttributesIfSyncedCount).toEventually(equal(0))
    }

    func testSyncAttributesForAllUsersDoesntDeleteForCurrentUser() {
        let currentUserID = "userID1"
        let otherUserID = "userID2"

        let userID1Attributes = [
            "band": SubscriberAttribute(withKey: "band", value: "The Doors"),
            "song": SubscriberAttribute(withKey: "song", value: "Riders on the storm"),
            "album": SubscriberAttribute(withKey: "album", value: "L.A. Woman")
        ]
        let userID2Attributes = [
            "instrument": SubscriberAttribute(withKey: "instrument", value: "Guitar"),
            "name": SubscriberAttribute(withKey: "name", value: "Robert Krieger")
        ]
        let allAttributes: [String: [String: SubscriberAttribute]] = [
            currentUserID: userID1Attributes,
            otherUserID: userID2Attributes
        ]
        mockDeviceCache.stubbedUnsyncedAttributesForAllUsersResult = allAttributes

        self.subscriberAttributesManager.syncAttributesForAllUsers(currentAppUserID: currentUserID)
        expect(self.mockDeviceCache.invokedDeleteAttributesIfSyncedCount).toEventually(equal(1))
        expect(Set(self.mockDeviceCache.invokedDeleteAttributesIfSyncedParametersList)) == Set([otherUserID])
    }
    // region AdjustID
    func testSetAdjustID() {
        let adjustID = "adjustID"
        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5
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

        expect(self.mockDeviceCache.invokedStoreCount) == 10
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$adjustId",
                                                                                    value: adjustID)

        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
    }

    func testSetAdjustIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let adjustID = "adjustID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$adjustId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
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
        expect(self.mockDeviceCache.invokedStoreCount) == 5

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 5

        checkDeviceIdentifiersAreSet()
    }

    func testSetAdjustIDDoesNotSetDeviceIdentifiersIfOptionDisabled() {
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: false
        )
        let adjustID = "adjustID"
        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region AppsflyerID
    func testSetAppsflyerID() {
        let appsflyerID = "appsflyerID"
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5
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

        expect(self.mockDeviceCache.invokedStoreCount) == 10
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$appsflyerId",
                                                                                    value: appsflyerID)

        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
    }

    func testSetAppsflyerIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let appsflyerID = "appsflyerID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$appsflyerId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
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
        expect(self.mockDeviceCache.invokedStoreCount) == 5

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 5

        checkDeviceIdentifiersAreSet()
    }

    func testSetAppsflyerIDDoesNotSetDeviceIdentifiersIfOptionDisabled() {
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: false
        )
        let appsflyerID = "appsflyerID"
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region FBAnonymousID
    func testSetFBAnonymousID() {
        let fbAnonID = "fbAnonID"
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5
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

        expect(self.mockDeviceCache.invokedStoreCount) == 10
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$fbAnonId",
                                                                                    value: fbAnonID)

        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
    }

    func testSetFBAnonymousIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let fbAnonID = "fbAnonID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$fbAnonId",
                                                                                    value: "old_adjust_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
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
        expect(self.mockDeviceCache.invokedStoreCount) == 5

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 5

        checkDeviceIdentifiersAreSet()
    }

    func testSetFBAnonymousIDDoesNotSetDeviceIdentifiersIfOptionDisabled() {
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: false
        )
        let fbAnonID = "fbAnonID"
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region mParticle
    func testSetMparticleID() {
        let mparticleID = "mparticleID"
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5
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

        expect(self.mockDeviceCache.invokedStoreCount) == 10
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mparticleId",
                                                                                    value: mparticleID)

        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
    }

    func testSetMparticleIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let mparticleID = "mparticleID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mparticleId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
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
        expect(self.mockDeviceCache.invokedStoreCount) == 5

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 5

        checkDeviceIdentifiersAreSet()
    }

    func testSetMparticleIDDoesNotSetDeviceIdentifiersIfOptionDisabled() {
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: false
        )
        let mparticleID = "mparticleID"
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region OnesignalID
    func testSetOnesignalID() {
        let onesignalID = "onesignalID"
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
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

        expect(self.mockDeviceCache.invokedStoreCount) == 2
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$onesignalId",
                                                                                    value: onesignalID)

        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetOnesignalIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let onesignalID = "onesignalID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$onesignalId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalId"
        expect(receivedAttribute.value) == onesignalID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetOnesignalIDDoesNotSetDeviceIdentifiers() {
        let onesignalID = "onesignalID"
        self.subscriberAttributesManager.setOnesignalID(onesignalID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region OnesignalUserID
    func testSetOnesignalUserID() {
        let onesignalUserID = "onesignalUserID"
        self.subscriberAttributesManager.setOnesignalUserID(onesignalUserID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalUserId"
        expect(receivedAttribute.value) == onesignalUserID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetOnesignalUserIDSetsEmptyIfNil() {
        let onesignalUserID = "onesignalUserID"
        self.subscriberAttributesManager.setOnesignalUserID(onesignalUserID, appUserID: "kratos")

        self.subscriberAttributesManager.setOnesignalUserID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalUserId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetOnesignalUserIDSkipsIfSameValue() {
        let onesignalUserID = "onesignalUserID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$onesignalUserId",
                                                                                    value: onesignalUserID)

        self.subscriberAttributesManager.setOnesignalUserID(onesignalUserID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetOnesignalUserIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let onesignalUserID = "onesignalUserID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$onesignalUserId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setOnesignalUserID(onesignalUserID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$onesignalUserId"
        expect(receivedAttribute.value) == onesignalUserID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetOnesignalUserIDDoesNotSetDeviceIdentifiers() {
        let onesignalUserID = "onesignalUserID"
        self.subscriberAttributesManager.setOnesignalUserID(onesignalUserID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region AirshipChannelID
    func testSetAirshipChannelID() throws {
        let airshipChannelID = "airshipChannelID"

        self.subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$airshipChannelId"
        expect(receivedAttribute.value) == airshipChannelID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAirshipChannelIDSetsEmptyIfNil() throws {
        let airshipChannelID = "airshipChannelID"

        self.subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: "kratos")
        self.subscriberAttributesManager.setAirshipChannelID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$airshipChannelId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAirshipChannelIDSkipsIfSameValue() {
        let airshipChannelID = "airshipChannelID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$airshipChannelId",
                                                                                    value: airshipChannelID)
        self.subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAirshipChannelIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let airshipChannelID = "airshipChannelID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$airshipChannelId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$airshipChannelId"
        expect(receivedAttribute.value) == airshipChannelID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetAirshipChannelIDDoesNotSetDeviceIdentifiers() {
        let airshipChannelID = "airshipChannelID"
        self.subscriberAttributesManager.setAirshipChannelID(airshipChannelID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region CleverTapID
    func testSetCleverTapID() throws {
        let cleverTapID = "cleverTapID"

        self.subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$clevertapId"
        expect(receivedAttribute.value) == cleverTapID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetCleverTapIDSetsEmptyIfNil() throws {
        let cleverTapID = "cleverTapID"

        self.subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: "kratos")
        self.subscriberAttributesManager.setCleverTapID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$clevertapId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetCleverTapIDSkipsIfSameValue() {
        let cleverTapID = "cleverTapID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$clevertapId",
                                                                                    value: cleverTapID)
        self.subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetCleverTapIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let cleverTapID = "cleverTapID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$clevertapId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$clevertapId"
        expect(receivedAttribute.value) == cleverTapID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetCleverTapIDDoesNotSetDeviceIdentifiers() {
        let cleverTapID = "cleverTapID"
        self.subscriberAttributesManager.setCleverTapID(cleverTapID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region airbridgeDeviceID
    func testSetAirbridgeDeviceID() {
        let airbridgeDeviceId = "airbridgeDeviceID"
        self.subscriberAttributesManager.setAirbridgeDeviceID(airbridgeDeviceId, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$airbridgeDeviceId"
        expect(receivedAttribute.value) == airbridgeDeviceId
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAirbridgeDeviceIDSetsEmptyIfNil() {
        let airbridgeDeviceId = "airbridgeDeviceID"
        self.subscriberAttributesManager.setAirbridgeDeviceID(airbridgeDeviceId, appUserID: "kratos")

        self.subscriberAttributesManager.setAirbridgeDeviceID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 10
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$airbridgeDeviceId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAirbridgeDeviceIDSkipsIfSameValue() {
        let airbridgeDeviceId = "airbridgeDeviceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$airbridgeDeviceId",
                                                                                    value: airbridgeDeviceId)

        self.subscriberAttributesManager.setAirbridgeDeviceID(airbridgeDeviceId, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
    }

    func testSetAirbridgeDeviceIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let airbridgeDeviceId = "airbridgeDeviceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$airbridgeDeviceId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAirbridgeDeviceID(airbridgeDeviceId, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$airbridgeDeviceId"
        expect(receivedAttribute.value) == airbridgeDeviceId
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetAirbridgeDeviceIDSetsDeviceIdentifiers() {
        let airbridgeDeviceId = "airbridgeDeviceID"
        self.subscriberAttributesManager.setAirbridgeDeviceID(airbridgeDeviceId, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 5

        checkDeviceIdentifiersAreSet()
    }

    func testSetAirbridgeDeviceIDDoesNotSetDeviceIdentifiersIfOptionDisabled() {
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: false
        )
        let airbridgeDeviceId = "airbridgeDeviceID"
        self.subscriberAttributesManager.setAirbridgeDeviceID(airbridgeDeviceId, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region kochavaDeviceID
    func testSetKochavaDeviceID() {
        let kochavaDeviceId = "kochavaDeviceID"
        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceId, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$kochavaDeviceId"
        expect(receivedAttribute.value) == kochavaDeviceId
        expect(receivedAttribute.isSynced) == false
    }

    func testSetKochavaDeviceIDSetsEmptyIfNil() {
        let kochavaDeviceId = "kochavaDeviceID"
        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceId, appUserID: "kratos")

        self.subscriberAttributesManager.setKochavaDeviceID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 10
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$kochavaDeviceId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetKochavaDeviceIDSkipsIfSameValue() {
        let kochavaDeviceId = "kochavaDeviceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$kochavaDeviceId",
                                                                                    value: kochavaDeviceId)

        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceId, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
    }

    func testSetKochavaDeviceIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let kochavaDeviceId = "kochavaDeviceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$kochavaDeviceId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceId, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$kochavaDeviceId"
        expect(receivedAttribute.value) == kochavaDeviceId
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetKochavaDeviceIDSetsDeviceIdentifiers() {
        let kochavaDeviceId = "kochavaDeviceID"
        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceId, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 5

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 5

        checkDeviceIdentifiersAreSet()
    }

    func testSetKochavaDeviceIDDoesNotSetDeviceIdentifiersIfOptionDisabled() {
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator,
            automaticDeviceIdentifierCollectionEnabled: false
        )
        let kochavaDeviceId = "kochavaDeviceID"
        self.subscriberAttributesManager.setKochavaDeviceID(kochavaDeviceId, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region MixpanelDistinctID
    func testSetMixpanelDistinctID() throws {
        let mixpanelDistinctID = "mixpanelDistinctID"

        self.subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$mixpanelDistinctId"
        expect(receivedAttribute.value) == mixpanelDistinctID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetMixpanelDistinctIDSetsEmptyIfNil() throws {
        let mixpanelDistinctID = "mixpanelDistinctID"

        self.subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: "kratos")
        self.subscriberAttributesManager.setMixpanelDistinctID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$mixpanelDistinctId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetMixpanelDistinctIDSkipsIfSameValue() {
        let mixpanelDistinctID = "mixpanelDistinctID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mixpanelDistinctId",
                                                                                    value: mixpanelDistinctID)
        self.subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetMixpanelDistinctIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let mixpanelDistinctID = "mixpanelDistinctID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mixpanelDistinctId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$mixpanelDistinctId"
        expect(receivedAttribute.value) == mixpanelDistinctID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetMixpanelDistinctIDDoesNotSetDeviceIdentifiers() {
        let mixpanelDistinctID = "mixpanelDistinctID"
        self.subscriberAttributesManager.setMixpanelDistinctID(mixpanelDistinctID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region FirebaseAppInstanceID
    func testSetFirebaseAppInstanceID() throws {
        let firebaseAppInstanceID = "firebaseAppInstanceID"

        self.subscriberAttributesManager.setFirebaseAppInstanceID(firebaseAppInstanceID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$firebaseAppInstanceId"
        expect(receivedAttribute.value) == firebaseAppInstanceID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetFirebaseAppInstanceIDSetsEmptyIfNil() throws {
        let firebaseAppInstanceID = "firebaseAppInstanceID"

        self.subscriberAttributesManager.setFirebaseAppInstanceID(firebaseAppInstanceID, appUserID: "kratos")
        self.subscriberAttributesManager.setFirebaseAppInstanceID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$firebaseAppInstanceId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetFirebaseAppInstanceIDSkipsIfSameValue() {
        let firebaseAppInstanceID = "firebaseAppInstanceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$firebaseAppInstanceId",
                                                                                    value: firebaseAppInstanceID)
        self.subscriberAttributesManager.setFirebaseAppInstanceID(firebaseAppInstanceID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetFirebaseAppInstanceIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let firebaseAppInstanceID = "firebaseAppInstanceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$firebaseAppInstanceId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setFirebaseAppInstanceID(firebaseAppInstanceID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$firebaseAppInstanceId"
        expect(receivedAttribute.value) == firebaseAppInstanceID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetFirebaseAppInstanceIDDoesNotSetDeviceIdentifiers() {
        let firebaseAppInstanceID = "firebaseAppInstanceID"
        self.subscriberAttributesManager.setFirebaseAppInstanceID(firebaseAppInstanceID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region FirebaseAppInstanceID
    func testSetTenjinAnalyticsInstallationID() throws {
        let tenjinAnalyticsInstallationID = "tenjinAnalyticsInstallationID"

        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(tenjinAnalyticsInstallationID,
                                                                          appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$tenjinId"
        expect(receivedAttribute.value) == tenjinAnalyticsInstallationID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetSetTenjinAnalyticsInstallationIDSetsEmptyIfNil() throws {
        let tenjinAnalyticsInstallationID = "tenjinAnalyticsInstallationID"

        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(tenjinAnalyticsInstallationID,
                                                                          appUserID: "kratos")
        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$tenjinId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetTenjinAnalyticsInstallationIDSkipsIfSameValue() {
        let tenjinAnalyticsInstallationID = "tenjinAnalyticsInstallationID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(
            withKey: "$tenjinId",
            value: tenjinAnalyticsInstallationID
        )
        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(tenjinAnalyticsInstallationID,
                                                                          appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetTenjinAnalyticsInstallationIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let tenjinAnalyticsInstallationID = "tenjinAnalyticsInstallationID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$tenjinId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(tenjinAnalyticsInstallationID,
                                                                          appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$tenjinId"
        expect(receivedAttribute.value) == tenjinAnalyticsInstallationID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetTenjinAnalyticsInstallationIDDoesNotSetDeviceIdentifiers() {
        let tenjinAnalyticsInstallationID = "tenjinAnalyticsInstallationID"
        self.subscriberAttributesManager.setTenjinAnalyticsInstallationID(tenjinAnalyticsInstallationID,
                                                                          appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region PostHogUserID
    func testSetPostHogUserID() throws {
        let postHogUserID = "postHogUserID"

        self.subscriberAttributesManager.setPostHogUserID(postHogUserID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$posthogUserId"
        expect(receivedAttribute.value) == postHogUserID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPostHogUserIDSetsEmptyIfNil() throws {
        let postHogUserID = "postHogUserID"

        self.subscriberAttributesManager.setPostHogUserID(postHogUserID, appUserID: "kratos")
        self.subscriberAttributesManager.setPostHogUserID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$posthogUserId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetPostHogUserIDSkipsIfSameValue() {
        let postHogUserID = "postHogUserID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(
            withKey: "$posthogUserId",
            value: postHogUserID
        )
        self.subscriberAttributesManager.setPostHogUserID(postHogUserID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPostHogUserIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let postHogUserID = "postHogUserID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(
            withKey: "$posthogUserId",
            value: "old_id",
            isSynced: true,
            setTime: oldSyncTime
        )

        self.subscriberAttributesManager.setPostHogUserID(postHogUserID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$posthogUserId"
        expect(receivedAttribute.value) == postHogUserID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetPostHogUserIDDoesNotSetDeviceIdentifiers() {
        let postHogUserID = "postHogUserID"
        self.subscriberAttributesManager.setPostHogUserID(postHogUserID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region AmplitudeUserID
    func testSetAmplitudeUserID() throws {
        let amplitudeUserID = "amplitudeUserID"

        self.subscriberAttributesManager.setAmplitudeUserID(amplitudeUserID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$amplitudeUserId"
        expect(receivedAttribute.value) == amplitudeUserID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAmplitudeUserIDSetsEmptyIfNil() throws {
        let amplitudeUserID = "amplitudeUserID"

        self.subscriberAttributesManager.setAmplitudeUserID(amplitudeUserID, appUserID: "kratos")
        self.subscriberAttributesManager.setAmplitudeUserID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$amplitudeUserId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAmplitudeUserIDSkipsIfSameValue() {
        let amplitudeUserID = "amplitudeUserID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$amplitudeUserId",
                                                                                    value: amplitudeUserID)
        self.subscriberAttributesManager.setAmplitudeUserID(amplitudeUserID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAmplitudeUserIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let amplitudeUserID = "amplitudeUserID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$amplitudeUserId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAmplitudeUserID(amplitudeUserID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$amplitudeUserId"
        expect(receivedAttribute.value) == amplitudeUserID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetAmplitudeUserIDDoesNotSetDeviceIdentifiers() {
        let amplitudeUserID = "amplitudeUserID"
        self.subscriberAttributesManager.setAmplitudeUserID(amplitudeUserID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
    }
    // endregion
    // region AmplitudeDeviceID
    func testSetAmplitudeDeviceID() throws {
        let amplitudeDeviceID = "amplitudeDeviceID"

        self.subscriberAttributesManager.setAmplitudeDeviceID(amplitudeDeviceID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$amplitudeDeviceId"
        expect(receivedAttribute.value) == amplitudeDeviceID
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAmplitudeDeviceIDSetsEmptyIfNil() throws {
        let amplitudeDeviceID = "amplitudeDeviceID"

        self.subscriberAttributesManager.setAmplitudeDeviceID(amplitudeDeviceID, appUserID: "kratos")
        self.subscriberAttributesManager.setAmplitudeDeviceID(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$amplitudeDeviceId"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAmplitudeDeviceIDSkipsIfSameValue() {
        let amplitudeDeviceID = "amplitudeDeviceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$amplitudeDeviceId",
                                                                                    value: amplitudeDeviceID)
        self.subscriberAttributesManager.setAmplitudeDeviceID(amplitudeDeviceID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAmplitudeDeviceIDOverwritesIfNewValue() throws {
        let oldSyncTime = Date()
        let amplitudeDeviceID = "amplitudeDeviceID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$amplitudeDeviceId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAmplitudeDeviceID(amplitudeDeviceID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1

        let invokedParams = try XCTUnwrap(self.mockDeviceCache.invokedStoreParameters)
        let receivedAttribute = invokedParams.attribute

        expect(receivedAttribute.key) == "$amplitudeDeviceId"
        expect(receivedAttribute.value) == amplitudeDeviceID
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetAmplitudeDeviceIDDoesNotSetDeviceIdentifiers() {
        let amplitudeDeviceID = "amplitudeDeviceID"
        self.subscriberAttributesManager.setAmplitudeDeviceID(amplitudeDeviceID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 1

        checkDeviceIdentifiersAreNotSet()
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mediaSource",
                                                                                    value: mediaSource)

        self.subscriberAttributesManager.setMediaSource(mediaSource, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetMediaSourceOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let mediaSource = "mediaSource"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mediaSource",
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$campaign",
                                                                                    value: campaign)

        self.subscriberAttributesManager.setCampaign(campaign, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetCampaignOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let campaign = "campaign"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$campaign",
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$adGroup", value: adGroup)

        self.subscriberAttributesManager.setAdGroup(adGroup, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAdGroupOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let adGroup = "adGroup"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$adGroup",
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
        let adValue = "ad"
        self.subscriberAttributesManager.setAd(adValue, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$ad"
        expect(receivedAttribute.value) == adValue
        expect(receivedAttribute.isSynced) == false
    }

    func testSetAdSetsEmptyIfNil() {
        let adValue = "ad"
        self.subscriberAttributesManager.setAd(adValue, appUserID: "kratos")

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
        let adValue = "ad"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$ad", value: adValue)

        self.subscriberAttributesManager.setAd(adValue, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAdOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let adValue = "ad"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$ad",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAd(adValue, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$ad"
        expect(receivedAttribute.value) == adValue
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$keyword", value: keyword)

        self.subscriberAttributesManager.setKeyword(keyword, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetKeywordOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let keyword = "keyword"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$keyword",
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

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$creative",
                                                                                    value: creative)

        self.subscriberAttributesManager.setCreative(creative, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetCreativeOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let creative = "creative"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$creative",
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
    // region AppsFlyer Attribution Data

    func testSetAppsFlyerAttributionDataSetsAllAttributesFromFullData() {
        let fullData: [AnyHashable: Any] = [
            "media_source": "facebook",
            "campaign": "summer_sale",
            "adgroup": "test_group",
            "af_ad": "test_ad",
            "af_keywords": "test_keywords",
            "creative": "test_creative"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(fullData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 6

        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "facebook"
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "summer_sale"
        expect(self.findInvokedAttribute(withName: "$adGroup").value) == "test_group"
        expect(self.findInvokedAttribute(withName: "$ad").value) == "test_ad"
        expect(self.findInvokedAttribute(withName: "$keyword").value) == "test_keywords"
        expect(self.findInvokedAttribute(withName: "$creative").value) == "test_creative"
    }

    func testSetAppsFlyerAttributionDataUsesFallbackFields() {
        let fallbackData: [AnyHashable: Any] = [
            "af_status": "organic",
            "campaign": "test_campaign",
            "adset": "test_adset",
            "ad_id": 12345,
            "keyword": "test_keyword",
            "af_creative": "test_af_creative"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(fallbackData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 6

        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "Organic"
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "test_campaign"
        expect(self.findInvokedAttribute(withName: "$adGroup").value) == "test_adset"
        expect(self.findInvokedAttribute(withName: "$ad").value) == "12345"
        expect(self.findInvokedAttribute(withName: "$keyword").value) == "test_keyword"
        expect(self.findInvokedAttribute(withName: "$creative").value) == "test_af_creative"
    }

    func testSetAppsFlyerAttributionDataPrefersPrimaryFieldsOverFallbacks() {
        let dataWithBothPrimaryAndFallback: [AnyHashable: Any] = [
            "media_source": "facebook",
            "af_status": "Organic",
            "campaign": "test_campaign",
            "adgroup": "primary_adgroup",
            "adset": "fallback_adset",
            "af_ad": "primary_ad",
            "ad_id": "fallback_ad_id",
            "af_keywords": "primary_keywords",
            "keyword": "fallback_keyword",
            "creative": "primary_creative",
            "af_creative": "fallback_creative"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(
            dataWithBothPrimaryAndFallback,
            appUserID: "kratos"
        )

        expect(self.mockDeviceCache.invokedStoreCount) == 6

        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "facebook"
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "test_campaign"
        expect(self.findInvokedAttribute(withName: "$adGroup").value) == "primary_adgroup"
        expect(self.findInvokedAttribute(withName: "$ad").value) == "primary_ad"
        expect(self.findInvokedAttribute(withName: "$keyword").value) == "primary_keywords"
        expect(self.findInvokedAttribute(withName: "$creative").value) == "primary_creative"
    }

    func testSetAppsFlyerAttributionDataWithNilDoesNothing() {
        self.subscriberAttributesManager.setAppsFlyerAttributionData(nil, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAppsFlyerAttributionDataWithEmptyDictDoesNothing() {
        self.subscriberAttributesManager.setAppsFlyerAttributionData([:], appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetAppsFlyerAttributionDataDoesNotSetMediaSourceWhenAfStatusIsNotOrganic() {
        self.subscriberAttributesManager.setAppsFlyerAttributionData(
            ["af_status": "Non-organic"],
            appUserID: "kratos"
        )
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$mediaSource" }))
    }

    func testSetAppsFlyerAttributionDataHandlesNilValuesInDictionary() {
        let nilValue: String? = nil
        let dataWithNilValues: [AnyHashable: Any] = [
            "media_source": nilValue as Any,
            "campaign": "valid_campaign"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(dataWithNilValues, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$mediaSource" }))
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "valid_campaign"
    }

    func testSetAppsFlyerAttributionDataHandlesEmptyStringValues() {
        let dataWithEmptyStrings: [AnyHashable: Any] = [
            "media_source": "",
            "campaign": "valid_campaign"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(dataWithEmptyStrings, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$mediaSource" }))
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "valid_campaign"
    }

    func testSetAppsFlyerAttributionDataHandlesIntegerValues() {
        let dataWithIntegers: [AnyHashable: Any] = [
            "ad_id": 12345,
            "campaign": "test"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(dataWithIntegers, appUserID: "kratos")

        expect(self.findInvokedAttribute(withName: "$ad").value) == "12345"
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "test"
    }

    func testSetAppsFlyerAttributionDataHandlesDoubleValuesAsIntegers() {
        let dataWithDoubles: [AnyHashable: Any] = [
            "ad_id": 12345.0
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(dataWithDoubles, appUserID: "kratos")

        expect(self.findInvokedAttribute(withName: "$ad").value) == "12345"
    }

    func testSetAppsFlyerAttributionDataWithTypicalOrganicInstall() {
        let organicData: [AnyHashable: Any] = [
            "af_status": "Organic",
            "af_message": "organic install",
            "is_first_launch": true
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(organicData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "Organic"
    }

    func testSetAppsFlyerAttributionDataWithTypicalNonOrganicInstall() {
        let nonOrganicData: [AnyHashable: Any] = [
            "af_status": "Non-organic",
            "media_source": "Facebook Ads",
            "campaign": "Summer Sale 2024",
            "adgroup": "Lookalike Audience",
            "adset": "US Users 25-35",
            "af_ad": "video_ad_001",
            "ad_id": "23847301457860211",
            "af_keywords": "fitness app",
            "creative": "creative_v2",
            "click_time": "2024-01-15 10:30:00.000",
            "install_time": "2024-01-15 10:35:12.050"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(nonOrganicData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 6
        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "Facebook Ads"
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "Summer Sale 2024"
        expect(self.findInvokedAttribute(withName: "$adGroup").value) == "Lookalike Audience"
        expect(self.findInvokedAttribute(withName: "$ad").value) == "video_ad_001"
        expect(self.findInvokedAttribute(withName: "$keyword").value) == "fitness app"
        expect(self.findInvokedAttribute(withName: "$creative").value) == "creative_v2"
    }

    func testSetAppsFlyerAttributionDataWithOnlyFallbackFields() {
        let fallbackData: [AnyHashable: Any] = [
            "af_status": "Organic",
            "adset": "fallback_adset",
            "ad_id": 99999,
            "keyword": "fallback_keyword",
            "af_creative": "fallback_creative"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(fallbackData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 5
        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "Organic"
        expect(self.findInvokedAttribute(withName: "$adGroup").value) == "fallback_adset"
        expect(self.findInvokedAttribute(withName: "$ad").value) == "99999"
        expect(self.findInvokedAttribute(withName: "$keyword").value) == "fallback_keyword"
        expect(self.findInvokedAttribute(withName: "$creative").value) == "fallback_creative"
    }

    func testSetAppsFlyerAttributionDataIgnoresUnrelatedFields() {
        let dataWithExtraFields: [AnyHashable: Any] = [
            "media_source": "test",
            "click_time": "2024-01-15",
            "install_time": "2024-01-15",
            "is_first_launch": true,
            "http_referrer": NSNull(),
            "agency": NSNull(),
            "some_random_field": "value"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(dataWithExtraFields, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "test"
    }

    func testSetAppsFlyerAttributionDataHandlesNSNullValues() {
        let dataWithNSNull: [AnyHashable: Any] = [
            "media_source": NSNull(),
            "campaign": "valid_campaign"
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(dataWithNSNull, appUserID: "kratos")

        let invokedParams = self.mockDeviceCache.invokedStoreParametersList
        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$mediaSource" }))
        expect(invokedParams).to(containElementSatisfying({ $0.attribute.key == "$campaign" }))
    }

    func testSetAppsFlyerAttributionDataWithNSDictionary() {
        let nsDictionary: NSDictionary = [
            "media_source": "facebook",
            "campaign": "test_campaign",
            "ad_id": NSNumber(value: 12345)
        ]
        self.subscriberAttributesManager.setAppsFlyerAttributionData(
            nsDictionary as? [AnyHashable: Any],
            appUserID: "kratos"
        )

        expect(self.mockDeviceCache.invokedStoreCount) == 3
        expect(self.findInvokedAttribute(withName: "$mediaSource").value) == "facebook"
        expect(self.findInvokedAttribute(withName: "$campaign").value) == "test_campaign"
        expect(self.findInvokedAttribute(withName: "$ad").value) == "12345"
    }

    // endregion
    // region Attribution Data conversion

    func testConvertAttributionDataAndSetAsSubscriberAttributesConvertsAndSetsTheAttributes() {
        let expectedConversionKey = "converted"
        let expectedConvertedValue = "that"
        self.mockAttributionDataMigrator.stubbedConvertAttributionDataToSubscriberAttributesResult = [
            expectedConversionKey: expectedConvertedValue
        ]
        let expectedAttributionData = ["convert": "any", "to": "something"]

        self.subscriberAttributesManager.setAttributes(fromAttributionData: expectedAttributionData,
                                                       network: .adjust,
                                                       appUserID: "user_id")
        expect(self.mockAttributionDataMigrator.invokedConvertAttributionDataToSubscriberAttributes) == true
        let invokedParams = mockAttributionDataMigrator.invokedConvertAttributionDataToSubscriberAttributesParameters
        expect(invokedParams!.attributionData.count) == expectedAttributionData.count
        for (key, value) in expectedAttributionData {
            expect(invokedParams!.attributionData[key] as? String) == value
        }
        expect(invokedParams!.network) == AttributionNetwork.adjust.rawValue

        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == expectedConversionKey
        expect(receivedAttribute.value) == expectedConvertedValue
        expect(receivedAttribute.isSynced) == false
    }

    func testWhenConvertingAttributionDataProducesAnEmptyConversionSubscriberAttributesNothingIsSet() {
        self.mockAttributionDataMigrator.stubbedConvertAttributionDataToSubscriberAttributesResult = [:]
        let expectedAttributionData = ["convert": "any", "to": "something"]

        self.subscriberAttributesManager.setAttributes(fromAttributionData: expectedAttributionData,
                                                       network: .adjust,
                                                       appUserID: "user_id")
        expect(self.mockAttributionDataMigrator.invokedConvertAttributionDataToSubscriberAttributes) == true
        let invokedParams = mockAttributionDataMigrator.invokedConvertAttributionDataToSubscriberAttributesParameters
        expect(invokedParams!.attributionData.count) == expectedAttributionData.count
        for (key, value) in expectedAttributionData {
            expect(invokedParams!.attributionData[key] as? String) == value
        }
        expect(invokedParams!.network) == AttributionNetwork.adjust.rawValue

        expect(self.mockDeviceCache.invokedStoreParameters).to(beNil())
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

    func findInvokedAttribute(withName name: String) -> SubscriberAttribute {
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

        let deviceVersionReceived = findInvokedAttribute(withName: "$deviceVersion")

        expect(deviceVersionReceived.value) == "true"
        expect(deviceVersionReceived.isSynced) == false
    }

    func checkDeviceIdentifiersAreNotSet() {
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$idfv" }))

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$idfa" }))

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$ip" }))

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$deviceVersion" }))
    }

}
