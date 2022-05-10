//
// Created by RevenueCat on 2/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class InMemoryCachedObjectTests: TestCase {

    // MARK: isCacheStaleWithDurationInSeconds:

    func testIsCacheStaleIsFalseBeforeDurationExpires() {
        let cacheDurationInSeconds = 5.0
        let now = Date()

        let cachedObject = InMemoryCachedObject<NSString>()

        cachedObject.cache(instance: "myString")
        expect(cachedObject.isCacheStale(durationInSeconds: cacheDurationInSeconds)) == false

        cachedObject.updateCacheTimestamp(date: now)
        expect(cachedObject.isCacheStale(durationInSeconds: cacheDurationInSeconds)) == false
    }

    func testIsCacheStaleIsTrueAfterDurationExpires() {
        let cacheDurationInSeconds = 5.0
        let now = Date()

        let cachedObject = InMemoryCachedObject<NSString>()

        guard let oldDate = Calendar.current.date(byAdding: .second, value: -5, to: now) else {
            fatalError("Couldn't set up date for tests")
        }

        cachedObject.cache(instance: "myString")
        cachedObject.updateCacheTimestamp(date: oldDate)
        expect(cachedObject.isCacheStale(durationInSeconds: cacheDurationInSeconds)) == true
    }

    func testIsCacheStaleIsTrueIfTheresNothingCached() {
        let cachedObject = InMemoryCachedObject<NSString>()

        expect(cachedObject.isCacheStale(durationInSeconds: 5)) == true

        cachedObject.cache(instance: "myString")
        cachedObject.clearCache()

        expect(cachedObject.isCacheStale(durationInSeconds: 5)) == true
    }

    // MARK: clearCacheTimestamp

    func testClearCacheTimestampClearsCorrectly() {
        let cachedObject = InMemoryCachedObject<NSString>()
        cachedObject.cache(instance: "myString")
        expect(cachedObject.lastUpdatedAt).toNot(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())

        cachedObject.clearCacheTimestamp()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())
    }

    // MARK: clearCache

    func testClearCacheClearsCorrectly() {
        let cachedObject = InMemoryCachedObject<NSString>()
        cachedObject.cache(instance: "myString")

        expect(cachedObject.lastUpdatedAt).toNot(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())

        cachedObject.clearCache()

        expect(cachedObject.lastUpdatedAt).to(beNil())
        expect(cachedObject.cachedInstance()).to(beNil())
    }

    // MARK: updateCacheTimestampWithDate

    func testUpdateCacheTimestampWithDateUpdatesCorrectly() {
        let myString: NSString = "something"
        let cachedObject = InMemoryCachedObject<NSString>()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        let firstDate = Date()
        cachedObject.cache(instance: myString)

        cachedObject.updateCacheTimestamp(date: firstDate)

        let secondDate = Date()
        cachedObject.updateCacheTimestamp(date: secondDate)

        expect(cachedObject.lastUpdatedAt) == secondDate
    }

    // MARK: cacheInstance:date

    func testCacheInstanceWithDateCachesInstanceCorrectly() {
        let myString: NSString = "something"
        let cachedObject = InMemoryCachedObject<NSString>()
        cachedObject.cache(instance: myString)

        expect(cachedObject.cachedInstance()) == myString
    }

    func testCacheInstanceWithDateSetsDateCorrectly() {
        let myString: NSString = "something"
        let cachedObject = InMemoryCachedObject<NSString>()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        let newDate = Date()
        cachedObject.cache(instance: myString)

        expect(cachedObject.lastUpdatedAt).to(beCloseTo(newDate))
    }
}
