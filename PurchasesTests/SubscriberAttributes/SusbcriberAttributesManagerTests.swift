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

    override func setUp() {
        super.setUp()
        self.mockDeviceCache = MockDeviceCache()
        self.mockBackend = MockBackend()
        self.subscriberAttributesManager = RCSubscriberAttributesManager(backend: mockBackend,
                                                                         deviceCache: mockDeviceCache)
    }

    // MARK: setting attributes

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

    // MARK: syncing
}
