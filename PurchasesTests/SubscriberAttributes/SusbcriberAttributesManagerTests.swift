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
    var subscriberAttributesManager: RCSubscriberAttributesManager!
    var subscriberAttributeHeight: RCSubscriberAttribute!
    var subscriberAttributeWeight: RCSubscriberAttribute!
    var mockAttributes: [String: RCSubscriberAttribute]!

    override func setUp() {
        super.setUp()
        self.mockDeviceCache = MockDeviceCache()
        self.mockBackend = MockBackend()
        self.subscriberAttributesManager = RCSubscriberAttributesManager(backend: mockBackend,
                                                                         deviceCache: mockDeviceCache)
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
            RCSubscriberAttributesManager(backend: nil, deviceCache: self.mockDeviceCache)
        }
        ).to(raiseException())

        expect(expression: {
            RCSubscriberAttributesManager(backend: self.mockBackend, deviceCache: nil)
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

    func testSyncIfNeededWithAppUserIDSkipsIfNoUnsyncedAttributes() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = 0
        subscriberAttributesManager.syncIfNeeded(withAppUserID: "whoever", completion: { _ in })

        expect(self.mockDeviceCache.invokedStore).toEventually(beFalse())
        expect(self.mockBackend.invokedPostSubscriberAttributes).toEventually(beFalse())
    }

    func testSyncIfNeededWithAppUserIDCallsCompletionIfNoUnsyncedAttributes() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = 0
        var invokedCompletionCount = 0
        var invokedError: Error? = nil
        subscriberAttributesManager.syncIfNeeded(withAppUserID: "whoever", completion: { error in
            invokedCompletionCount += 1
            invokedError = error
        })

        expect(invokedError).toEventually(beNil())
        expect(invokedCompletionCount).toEventually(equal(1))
    }

    func testSyncIfNeededWithAppUserMakesRightCallsToBackend() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = UInt(mockAttributes.count)
        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        subscriberAttributesManager.syncIfNeeded(withAppUserID: "Rick Sanchez", completion: { _ in })

        expect(self.mockDeviceCache.invokedNumberOfUnsyncedAttributesCount) == 1
        expect(self.mockDeviceCache.invokedNumberOfUnsyncedAttributesCount) == 1
        expect(self.mockBackend.invokedPostSubscriberAttributesCount) == 1

        expect(self.mockBackend.invokedPostSubscriberAttributesParameters?.subscriberAttributes) == mockAttributes
    }

    func testSyncIfNeededCallsCompletionAfterSyncing() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = UInt(mockAttributes.count)
        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        mockBackend.stubbedPostSubscriberAttributesCompletionResult = (nil, ())

        var receivedError: Error? = nil
        var invokedCompletionCount = 0
        subscriberAttributesManager.syncIfNeeded(withAppUserID: "Rick Sanchez", completion: { error in
            receivedError = error
            invokedCompletionCount += 1
        })

        expect(receivedError).toEventually(beNil())
        expect(invokedCompletionCount).toEventually(equal(1))
    }

    func testSyncIfNeededWithAppUserIDMarksAttributesAsSyncedIfNoError() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = UInt(mockAttributes.count)
        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        mockBackend.stubbedPostSubscriberAttributesCompletionResult = (nil, ())

        subscriberAttributesManager.syncIfNeeded(withAppUserID: "Rick Sanchez", completion: { _ in })
        assertMockAttributesSynced()
    }

    func testSyncIfNeededWithAppUserIDMarksSyncedIfMarkSyncedKeyPresent() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = UInt(mockAttributes.count)
        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        let errorCode = Purchases.ErrorCode.unknownBackendError.rawValue
        let mockError = NSError(domain: "error", code: errorCode, userInfo: [RCSuccessfullySyncedKey: "true"])
        mockBackend.stubbedPostSubscriberAttributesCompletionResult = (mockError, ())

        var receivedError: Error? = nil
        subscriberAttributesManager.syncIfNeeded(withAppUserID: "Rick Sanchez", completion: { error in
            receivedError = error
        })

        expect(receivedError as NSError?).toEventually(equal(mockError))
        assertMockAttributesSynced()
    }

    func testSyncIfNeededWithAppUserIDDoesntMarkSyncedIfShouldMarkSyncedKeyNotPresent() {
        mockDeviceCache.stubbedNumberOfUnsyncedAttributesResult = UInt(mockAttributes.count)
        mockDeviceCache.stubbedUnsyncedAttributesByKeyResult = mockAttributes
        let errorCode = Purchases.ErrorCode.networkError.rawValue
        let mockError = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        mockBackend.stubbedPostSubscriberAttributesCompletionResult = (mockError, ())

        var receivedError: Error? = nil
        subscriberAttributesManager.syncIfNeeded(withAppUserID: "Rick Sanchez", completion: { error in
            receivedError = error
        })

        expect(receivedError as NSError?).toEventually(equal(mockError))
        expect(self.mockDeviceCache.invokedStoreSubscriberAttributesCount).toEventually(equal(0))
    }

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
}
