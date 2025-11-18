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
        expect(receivedDictionary.keys).to(haveCount(5))

        expect(receivedDictionary["key"] as? String) == subscriberAttribute.key
        expect(receivedDictionary["value"] as? String) == subscriberAttribute.value
        expect(receivedDictionary["setTime"] as? Date) == subscriberAttribute.setTime
        expect((receivedDictionary["isSynced"] as? NSNumber)?.boolValue) == subscriberAttribute.isSynced
        expect((receivedDictionary["ignoreTimeInCacheIdentity"] as? NSNumber)?.boolValue)
        == subscriberAttribute.ignoreTimeInCacheIdentity
    }

    func testAsBackendDictionaryReturnsCorrectFormat() throws {
        let receivedDictionary = Self.mockAttribute.asBackendDictionary()
        expect(receivedDictionary.keys).to(haveCount(2))

        expect(receivedDictionary["value"] as? String) == Self.mockAttribute.value
        expect((receivedDictionary["updated_at_ms"] as? NSNumber)?.uint64Value)
        == Self.mockAttribute.setTime.millisecondsSince1970
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

    func testInitWithIgnoreTimeInCacheIdentityDefaultsToFalse() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttribute = SubscriberAttribute(withKey: "a key",
                                                      value: "a value",
                                                      dateProvider: dateProvider)
        expect(subscriberAttribute.ignoreTimeInCacheIdentity) == false
    }

    func testInitWithIgnoreTimeInCacheIdentityCanBeSetToTrue() {
        let now = Date()
        let dateProvider = MockDateProvider(stubbedNow: now)
        let subscriberAttribute = SubscriberAttribute(withKey: "a key",
                                                      value: "a value",
                                                      dateProvider: dateProvider,
                                                      ignoreTimeInCacheIdentity: true)
        expect(subscriberAttribute.ignoreTimeInCacheIdentity) == true
    }

    func testAsDictionaryIncludesIgnoreTimeInCacheIdentity() throws {
        let subscriberAttribute = SubscriberAttribute(withKey: "test key",
                                                      value: "test value",
                                                      dateProvider: MockDateProvider(stubbedNow: Date()),
                                                      ignoreTimeInCacheIdentity: true)

        let receivedDictionary = subscriberAttribute.asDictionary()
        expect(receivedDictionary.keys).to(haveCount(5))
        expect((receivedDictionary["ignoreTimeInCacheIdentity"] as? NSNumber)?.boolValue) == true
    }

    func testInitWithDictionarySetsIgnoreTimeInCacheIdentity() throws {
        let key = "some key"
        let value = "some value"
        let setTime = NSDate()
        let isSynced = true
        let ignoreTimeInCacheIdentity = true
        let subscriberDict: [String: NSObject] = [
            "key": key as NSString,
            "value": value as NSString,
            "setTime": setTime,
            "isSynced": NSNumber(value: isSynced),
            "ignoreTimeInCacheIdentity": NSNumber(value: ignoreTimeInCacheIdentity)
        ]

        let subscriberAttribute = try XCTUnwrap(SubscriberAttribute(dictionary: subscriberDict))

        expect(subscriberAttribute.ignoreTimeInCacheIdentity) == ignoreTimeInCacheIdentity
    }

    func testInitWithDictionaryDefaultsIgnoreTimeInCacheIdentityToFalse() throws {
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

        expect(subscriberAttribute.ignoreTimeInCacheIdentity) == false
    }

    func testCacheKeysAreDifferentWhenOnlyDifferentTimeAndIgnoreTimeInCacheIdentityIsFalse() {
        let time1 = Date(timeIntervalSince1970: 1000)
        let time2 = Date(timeIntervalSince1970: 2000)
        let dateProvider1 = MockDateProvider(stubbedNow: time1)
        let dateProvider2 = MockDateProvider(stubbedNow: time2)

        let attribute1 = SubscriberAttribute(withKey: "key",
                                             value: "value",
                                             dateProvider: dateProvider1,
                                             ignoreTimeInCacheIdentity: false)
        let attribute2 = SubscriberAttribute(withKey: "key",
                                             value: "value",
                                             dateProvider: dateProvider2,
                                             ignoreTimeInCacheIdentity: false)

        // When ignoreTimeInCacheIdentity is false, different setTime should produce different cache keys
        expect(attribute1.individualizedCacheKeyPart) != attribute2.individualizedCacheKeyPart
    }

    func testCacheKeysAreEqualWhenOnlyDifferentTimeAndIgnoreTimeInCacheIdentityIsTrue() {
        let time1 = Date(timeIntervalSince1970: 1000)
        let time2 = Date(timeIntervalSince1970: 2000)
        let dateProvider1 = MockDateProvider(stubbedNow: time1)
        let dateProvider2 = MockDateProvider(stubbedNow: time2)

        let attribute1 = SubscriberAttribute(withKey: "key",
                                             value: "value",
                                             dateProvider: dateProvider1,
                                             ignoreTimeInCacheIdentity: true)
        let attribute2 = SubscriberAttribute(withKey: "key",
                                             value: "value",
                                             dateProvider: dateProvider2,
                                             ignoreTimeInCacheIdentity: true)

        // When ignoreTimeInCacheIdentity is true, only different setTime should still produce same cache keys
        expect(attribute1.individualizedCacheKeyPart) == attribute2.individualizedCacheKeyPart
    }

    func testDictionaryIndividualizedCacheKeyPart() {
        let time1 = Date(timeIntervalSince1970: 1000)
        let time2 = Date(timeIntervalSince1970: 2000)
        let dateProvider1 = MockDateProvider(stubbedNow: time1)
        let dateProvider2 = MockDateProvider(stubbedNow: time2)

        let attribute1 = SubscriberAttribute(withKey: "key",
                                             value: "value",
                                             dateProvider: dateProvider1,
                                             ignoreTimeInCacheIdentity: true)
        let attribute2 = SubscriberAttribute(withKey: "key",
                                             value: "value",
                                             dateProvider: dateProvider2,
                                             ignoreTimeInCacheIdentity: true)

        let dict1: SubscriberAttribute.Dictionary = ["key": attribute1]
        let dict2: SubscriberAttribute.Dictionary = ["key": attribute2]

        // Even though timestamps differ, cache keys should be the same
        expect(dict1.individualizedCacheKeyPart) == dict2.individualizedCacheKeyPart
    }

    func testDictionaryIndividualizedCacheKeyPartDifferentWhenIgnoreTimeInCacheIdentityIsFalse() {
        let time1 = Date(timeIntervalSince1970: 1000)
        let time2 = Date(timeIntervalSince1970: 2000)
        let dateProvider1 = MockDateProvider(stubbedNow: time1)
        let dateProvider2 = MockDateProvider(stubbedNow: time2)

        let attribute = SubscriberAttribute(withKey: "key",
                                            value: "value",
                                            dateProvider: dateProvider1,
                                            ignoreTimeInCacheIdentity: false)

        let attributeDifferentTime = SubscriberAttribute(withKey: "key",
                                                         value: "value",
                                                         dateProvider: dateProvider2,
                                                         ignoreTimeInCacheIdentity: false)

        let dict1: SubscriberAttribute.Dictionary = ["key": attribute]
        let dict2: SubscriberAttribute.Dictionary = ["key": attributeDifferentTime]

        // When ignoreTimeInCacheIdentity is false, different timestamps should produce different cache keys
        expect(dict1.individualizedCacheKeyPart) != dict2.individualizedCacheKeyPart
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
