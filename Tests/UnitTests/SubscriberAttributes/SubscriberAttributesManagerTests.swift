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
        let systemInfo = try MockSystemInfo(platformInfo: platformInfo,
                                            finishTransactions: true)

        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: systemInfo)
        self.mockBackend = MockBackend()
        self.mockAttributionFetcher = MockAttributionFetcher(attributionFactory: AttributionTypeFactory(),
                                                             systemInfo: systemInfo)
        self.mockAttributionDataMigrator = MockAttributionDataMigrator()
        self.subscriberAttributesManager = SubscriberAttributesManager(
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: mockAttributionFetcher,
            attributionDataMigrator: mockAttributionDataMigrator
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

        let tokenString = (tokenData as NSData).asString()
        expect(receivedAttribute.value) == tokenString
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
        let tokenString = (tokenData as NSData).asString()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$apnsTokens",
                                                                                    value: tokenString)

        self.subscriberAttributesManager.setPushToken(tokenData, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPushTokenOverwritesIfNewValue() {
        let tokenData = "ligai32g32ig".asData
        let tokenString = (tokenData as NSData).asString()
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

    // mark - sync attributes for all users

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
        expect(self.mockDeviceCache.invokedStoreCount) == 4
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

        expect(self.mockDeviceCache.invokedStoreCount) == 8
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

        expect(self.mockDeviceCache.invokedStoreCount) == 3
    }

    func testSetAdjustIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let adjustID = "adjustID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$adjustId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAdjustID(adjustID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
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
        expect(self.mockDeviceCache.invokedStoreCount) == 4

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 4

        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region AppsflyerID
    func testSetAppsflyerID() {
        let appsflyerID = "appsflyerID"
        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 4
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

        expect(self.mockDeviceCache.invokedStoreCount) == 8
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

        expect(self.mockDeviceCache.invokedStoreCount) == 3
    }

    func testSetAppsflyerIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let appsflyerID = "appsflyerID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$appsflyerId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setAppsflyerID(appsflyerID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
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
        expect(self.mockDeviceCache.invokedStoreCount) == 4

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 4

        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region FBAnonymousID
    func testSetFBAnonymousID() {
        let fbAnonID = "fbAnonID"
        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 4
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

        expect(self.mockDeviceCache.invokedStoreCount) == 8
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

        expect(self.mockDeviceCache.invokedStoreCount) == 3
    }

    func testSetFBAnonymousIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let fbAnonID = "fbAnonID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$fbAnonId",
                                                                                    value: "old_adjust_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setFBAnonymousID(fbAnonID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
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
        expect(self.mockDeviceCache.invokedStoreCount) == 4

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 4

        checkDeviceIdentifiersAreSet()
    }
    // endregion
    // region mParticle
    func testSetMparticleID() {
        let mparticleID = "mparticleID"
        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")
        expect(self.mockDeviceCache.invokedStoreCount) == 4
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

        expect(self.mockDeviceCache.invokedStoreCount) == 8
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

        expect(self.mockDeviceCache.invokedStoreCount) == 3
    }

    func testSetMparticleIDOverwritesIfNewValue() {
        let oldSyncTime = Date()
        let mparticleID = "mparticleID"

        self.mockDeviceCache.stubbedSubscriberAttributeResult = SubscriberAttribute(withKey: "$mparticleId",
                                                                                    value: "old_id",
                                                                                    isSynced: true,
                                                                                    setTime: oldSyncTime)

        self.subscriberAttributesManager.setMparticleID(mparticleID, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 4
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
        expect(self.mockDeviceCache.invokedStoreCount) == 4

        expect(self.mockDeviceCache.invokedStoreParametersList.count) == 4

        checkDeviceIdentifiersAreSet()
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
    }

    func checkDeviceIdentifiersAreNotSet() {
        let invokedParams = self.mockDeviceCache.invokedStoreParametersList

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$idfv" }))

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$idfa" }))

        expect(invokedParams).toNot(containElementSatisfying({ $0.attribute.key == "$ip" }))
    }

}
