//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class SubscriberAttributeTests: XCTestCase {
    func testInitWithKeyValueSetsRightValues() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttribute = SubscriberAttribute(withKey: "a key",
                                                      value: "a value",
                                                      dateProvider: dateProvider)
        expect(subscriberAttribute.key) == "a key"
        expect(subscriberAttribute.value) == "a value"
        expect(subscriberAttribute.setTime) == now
        expect(subscriberAttribute.isSynced) == false
    }

    func testAsDictionaryReturnsCorrectFormat() throws {
        let key = "some key"
        let value = "some value"
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)

        let subscriberAttribute = SubscriberAttribute(withKey: key,
                                                      value: value,
                                                      dateProvider: dateProvider)

        let receivedDictionary = subscriberAttribute.asDictionary()
        expect(receivedDictionary.keys.count) == 4

        expect(receivedDictionary["key"] as? String) == key
        expect(receivedDictionary["value"] as? String) == value
        expect(receivedDictionary["setTime"] as? Date) == now
        let isSynced = try XCTUnwrap((receivedDictionary["isSynced"] as? NSNumber)?.boolValue)
        expect(isSynced) == false
    }

    func testAsBackendDictionaryReturnsCorrectFormat() throws {
        let key = "some key"
        let value = "some value"
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)

        let subscriberAttribute = SubscriberAttribute(withKey: key,
                                                      value: value,
                                                      dateProvider: dateProvider)

        let receivedDictionary = subscriberAttribute.asBackendDictionary()
        expect(receivedDictionary.keys.count) == 2

        expect(receivedDictionary["value"] as? String) == value
        let updatedAtEpoch = try XCTUnwrap((receivedDictionary["updated_at_ms"] as? NSNumber)?.uint64Value)
        expect(updatedAtEpoch) == (now as NSDate).millisecondsSince1970AsUInt64()
    }
}
