//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class SubscriberAttributeTests: XCTestCase {
    func testInitWithKeyValueSetsRightValues() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttribute = RCSubscriberAttribute(key: "a key",
                                                        value: "a value",
                                                        dateProvider: dateProvider)
        expect(subscriberAttribute.key) == "a key"
        expect(subscriberAttribute.value) == "a value"
        expect(subscriberAttribute.setTime) == now
        expect(subscriberAttribute.isSynced) == false
    }

    func testInitWithDictionarySetsRightValues() {
        let key = "some key"
        let value = "some value"
        let setTime = NSDate()
        let isSynced = true
        let subscriberDict: [String: NSObject] = [
            "key": NSString(string: key),
            "value": NSString(string: value),
            "setTime": setTime,
            "isSynced": NSNumber(booleanLiteral: isSynced),
        ]

        let subscriberAttribute = RCSubscriberAttribute(dictionary: subscriberDict)

        expect(subscriberAttribute.key) == key
        expect(subscriberAttribute.value) == value
        expect(subscriberAttribute.setTime as NSDate) == setTime
        expect(subscriberAttribute.isSynced) == isSynced
    }

    func testAsDictionaryReturnsCorrectFormat() {
        let key = "some key"
        let value = "some value"
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)

        let subscriberAttribute = RCSubscriberAttribute(key: key,
                                                        value: value,
                                                        dateProvider: dateProvider)

        let receivedDictionary = subscriberAttribute.asDictionary()
        expect(receivedDictionary.keys.count) == 4

        expect(receivedDictionary["key"] as? String) == key
        expect(receivedDictionary["value"] as? String) == value
        expect(receivedDictionary["setTime"] as? Date) == now
        expect((receivedDictionary["isSynced"] as! NSNumber).boolValue) == false
    }

    func testAsBackendDictionaryReturnsCorrectFormat() {
        let key = "some key"
        let value = "some value"
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)

        let subscriberAttribute = RCSubscriberAttribute(key: key,
                                                        value: value,
                                                        dateProvider: dateProvider)

        let receivedDictionary = subscriberAttribute.asBackendDictionary()
        expect(receivedDictionary.keys.count) == 2

        expect(receivedDictionary["value"] as? String) == value
        let updatedAtEpoch = (receivedDictionary["updated_at_ms"] as! NSNumber).uint64Value
        expect(updatedAtEpoch) == (now as NSDate).millisecondsSince1970()
    }
}
