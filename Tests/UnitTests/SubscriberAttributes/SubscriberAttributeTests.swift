//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class SubscriberAttributeTests: TestCase {

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
        let subscriberAttribute = Self.mockAttribute

        let receivedDictionary = subscriberAttribute.asDictionary()
        expect(receivedDictionary.keys).to(haveCount(4))

        expect(receivedDictionary["key"] as? String) == subscriberAttribute.key
        expect(receivedDictionary["value"] as? String) == subscriberAttribute.value
        expect(receivedDictionary["setTime"] as? Date) == subscriberAttribute.setTime
        expect((receivedDictionary["isSynced"] as? NSNumber)?.boolValue) == subscriberAttribute.isSynced
    }

    func testAsBackendDictionaryReturnsCorrectFormat() throws {
        let receivedDictionary = Self.mockAttribute.asBackendDictionary()
        expect(receivedDictionary.keys).to(haveCount(2))

        expect(receivedDictionary["value"] as? String) == Self.mockAttribute.value
        expect((receivedDictionary["updated_at_ms"] as? NSNumber)?.uint64Value)
        == Self.mockAttribute.setTime.millisecondsSince1970AsUInt64()
    }

    func testInitWithDictionarySetsRightValues() throws {
        let key = "some key"
        let value = "some value"
        let setTime = NSDate()
        let isSynced = true
        let subscriberDict: [String: NSObject] = [
            "key": key as NSString,
            "value": value as NSString,
            "setTime": setTime,
            "isSynced": NSNumber(value: isSynced)
        ]

        let subscriberAttribute = try XCTUnwrap(SubscriberAttribute(dictionary: subscriberDict))

        expect(subscriberAttribute.key) == key
        expect(subscriberAttribute.value) == value
        expect(subscriberAttribute.setTime as NSDate) == setTime
        expect(subscriberAttribute.isSynced) == isSynced
    }

    func testEncodeAndDecode() throws {
        let subscriberAttribute = Self.mockAttribute

        expect(SubscriberAttribute(dictionary: subscriberAttribute.asDictionary())) == subscriberAttribute
    }

}

private extension SubscriberAttributeTests {

    static let mockAttribute: SubscriberAttribute = {
        let key = "some key"
        let value = "some value"
        let now = Date(timeIntervalSince1970: 2_000_000_000) // 2033-05-18 03:33:20Z
        let dateProvider = MockDateProvider(stubbedNow: now)

        return .init(withKey: key, value: value, dateProvider: dateProvider)
    }()

}
