//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class SubscriberAttributeTests: XCTestCase {
    func testInitWithKeyValueAppUserIDSetsRightValues() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttribute = RCSubscriberAttribute(key: "a key",
                                                        value: "a value",
                                                        appUserID: "user id",
                                                        dateProvider: dateProvider)
        expect(subscriberAttribute.key) == "a key"
        expect(subscriberAttribute.value) == "a value"
        expect(subscriberAttribute.appUserID) == "user id"
        expect(subscriberAttribute.setTime) == now
        expect(subscriberAttribute.isSynced) == false
    }

    func testInitWithDictionarySetsRightValues() {
        let key = "some key"
        let value = "some value"
        let appUserID = "68asdfa4g3210"
        let setTime = NSDate()
        let isSynced = true
        let subscriberDict: [String: NSObject] = [
            "key": NSString(string: key),
            "value": NSString(string: value),
            "appUserID": NSString(string: appUserID),
            "setTime": setTime,
            "isSynced": NSNumber(booleanLiteral: isSynced),
        ]

        let subscriberAttribute = RCSubscriberAttribute(dictionary: subscriberDict)

        expect(subscriberAttribute.key) == key
        expect(subscriberAttribute.value) == value
        expect(subscriberAttribute.appUserID) == appUserID
        expect(subscriberAttribute.setTime as NSDate) == setTime
        expect(subscriberAttribute.isSynced) == isSynced
    }

    func testAsDictionaryReturnsCorrectFormat() {
        let key = "some key"
        let value = "some value"
        let appUserID = "68asdfa4g3210"
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)

        let subscriberAttribute = RCSubscriberAttribute(key: key,
                                                        value: value,
                                                        appUserID: appUserID,
                                                        dateProvider: dateProvider)

        let receivedDictionary = subscriberAttribute.asDictionary()
        expect(receivedDictionary.keys.count) == 5

        expect(receivedDictionary["key"] as? String) == key
        expect(receivedDictionary["value"] as? String) == value
        expect(receivedDictionary["appUserID"] as? String) == appUserID
        expect(receivedDictionary["setTime"] as! Date) == now
        expect((receivedDictionary["isSynced"] as! NSNumber).boolValue) == false
    }

    func testAsBackendDictionaryReturnsCorrectFormat() {
        let key = "some key"
        let value = "some value"
        let appUserID = "68asdfa4g3210"
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)

        let subscriberAttribute = RCSubscriberAttribute(key: key,
                                                        value: value,
                                                        appUserID: appUserID,
                                                        dateProvider: dateProvider)

        let receivedDictionary = subscriberAttribute.asBackendDictionary()
        expect(receivedDictionary.keys.count) == 2

        expect(receivedDictionary["value"] as? String) == value
        let updatedAtEpoch = (receivedDictionary["updated_at"] as! NSNumber).doubleValue
        let updatedAtDate = Date(timeIntervalSince1970: updatedAtEpoch)
        expect(updatedAtDate).to(beCloseTo(now))
    }
}
