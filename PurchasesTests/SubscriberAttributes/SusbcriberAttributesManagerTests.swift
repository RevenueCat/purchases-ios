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
                                                               value: "183",
                                                               appUserID: "waldo")
        self.subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                               value: "160",
                                                               appUserID: "waldo")
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
        var attributesByKey: [String: RCSubscriberAttribute] = [:]
        for (attribute, _) in invokedParams {
            attributesByKey[attribute.key] = attribute
        }

        expect(attributesByKey["genre"]?.key) == "genre"
        expect(attributesByKey["genre"]?.value) == "blues"
        expect(attributesByKey["genre"]?.isSynced) == false
        expect(attributesByKey["genre"]?.appUserID) == "Stevie Ray Vaughan"

        expect(attributesByKey["instrument"]?.key) == "instrument"
        expect(attributesByKey["instrument"]?.value) == "guitar"
        expect(attributesByKey["instrument"]?.isSynced) == false
        expect(attributesByKey["instrument"]?.appUserID) == "Stevie Ray Vaughan"
    }

    func testSetAttributesSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "genre",
                                                                                      value: "blues",
                                                                                      appUserID: "Stevie Ray Vaughan")

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
        expect(receivedAttribute.appUserID) == "Stevie Ray Vaughan"
    }

    func testSetAttributesUpdatesIfDifferentValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "genre",
                                                                                      value: "texas blues",
                                                                                      appUserID: "Stevie Ray Vaughan")

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
        expect(attributesByKey["genre"]?.appUserID) == "Stevie Ray Vaughan"

        expect(attributesByKey["instrument"]?.key) == "instrument"
        expect(attributesByKey["instrument"]?.value) == "guitar"
        expect(attributesByKey["instrument"]?.isSynced) == false
        expect(attributesByKey["instrument"]?.appUserID) == "Stevie Ray Vaughan"
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
        expect(receivedAttribute.appUserID) == "kratos"
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
        expect(receivedAttribute.appUserID) == "kratos"
    }

    func testSetEmailSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$email",
                                                                                      value: "kratos@sparta.com",
                                                                                      appUserID: "kratos")

        self.subscriberAttributesManager.setEmail("kratos@sparta.com", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetEmailOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$email",
                                                                                      value: "kratos@sparta.com",
                                                                                      appUserID: "kratos",
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
        expect(receivedAttribute.appUserID) == "kratos"
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
        expect(receivedAttribute.appUserID) == "kratos"
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
        expect(receivedAttribute.appUserID) == "kratos"
    }

    func testSetPhoneNumberSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$displayName",
                                                                                      value: "Kratos",
                                                                                      appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPhoneNumberOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$phoneNumber",
                                                                                      value: "9823523",
                                                                                      appUserID: "kratos",
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
        expect(receivedAttribute.appUserID) == "kratos"
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
        expect(receivedAttribute.appUserID) == "kratos"
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
        expect(receivedAttribute.appUserID) == "kratos"
    }

    func testSetDisplayNameSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: "Kratos",
                                                                                      appUserID: "kratos")

        self.subscriberAttributesManager.setDisplayName("Kratos", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetDisplayNameOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$displayName",
                                                                                      value: "Kratos",
                                                                                      appUserID: "kratos",
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
        expect(receivedAttribute.appUserID) == "kratos"
        expect(receivedAttribute.setTime) > oldSyncTime
    }

    func testSetPushToken() {
        self.subscriberAttributesManager.setPushToken("laisbawba2332g", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == "laisbawba2332g"
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.appUserID) == "kratos"
    }

    func testSetPushTokenSetsEmptyIfNil() {
        self.subscriberAttributesManager.setPushToken("laisbawba2332g", appUserID: "kratos")

        self.subscriberAttributesManager.setPushToken(nil, appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 2
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == ""
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.appUserID) == "kratos"
    }

    func testSetPushTokenSkipsIfSameValue() {
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: "laisbawba2332g",
                                                                                      appUserID: "kratos")

        self.subscriberAttributesManager.setPushToken("laisbawba2332g", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 0
    }

    func testSetPushTokenOverwritesIfNewValue() {
        let oldSyncTime = Date()
        self.mockDeviceCache.stubbedSubscriberAttributeResult = RCSubscriberAttribute(key: "$apnsTokens",
                                                                                      value: "oagi3wg93wg",
                                                                                      appUserID: "kratos",
                                                                                      isSynced: true,
                                                                                      setTime: oldSyncTime)

        self.subscriberAttributesManager.setPushToken("8jb4g203g3jg2p3", appUserID: "kratos")

        expect(self.mockDeviceCache.invokedStoreCount) == 1
        guard let invokedParams = self.mockDeviceCache.invokedStoreParameters else {
            fatalError("no attributes received")
        }
        let receivedAttribute = invokedParams.attribute
        expect(receivedAttribute.key) == "$apnsTokens"
        expect(receivedAttribute.value) == "8jb4g203g3jg2p3"
        expect(receivedAttribute.isSynced) == false
        expect(receivedAttribute.appUserID) == "kratos"
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

        expect(self.mockBackend.invokedPostSubscriberAttributesParameters?.appUserID) == "Rick Sanchez"
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
        let mockError = NSError(domain: "error", code: errorCode, userInfo: ["shouldMarkSynced": "true"])
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
        expect(attributesByKey[self.subscriberAttributeHeight.key]?.appUserID)
            .toEventually(equal(subscriberAttributeHeight.appUserID))

        expect(attributesByKey[self.subscriberAttributeWeight.key]?.key)
            .toEventually(equal(subscriberAttributeWeight.key))
        expect(attributesByKey[self.subscriberAttributeWeight.key]?.value)
            .toEventually(equal(subscriberAttributeWeight.value))
        expect(attributesByKey[self.subscriberAttributeWeight.key]?.isSynced)
            .toEventually(equal(true))
        expect(attributesByKey[self.subscriberAttributeWeight.key]?.appUserID)
            .toEventually(equal(subscriberAttributeWeight.appUserID))
    }
}
