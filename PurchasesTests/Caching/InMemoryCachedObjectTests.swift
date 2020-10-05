//
// Created by RevenueCat on 2/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

import Purchases

class InMemoryCachedObjectTests: XCTestCase {

    // mark: isCacheStaleWithDurationInSeconds:

    func testIsCacheStaleIsFalseBeforeDurationExpires() {
        let cacheDurationInSeconds: Int32 = 5
        let now = Date()

        let cachedObject = RCInMemoryCachedObject<NSString>()

        cachedObject.cacheInstance("myString")
        expect(cachedObject.isCacheStaleWithDuration(inSeconds: cacheDurationInSeconds)) == false

        cachedObject.lastUpdatedAt = now
        expect(cachedObject.isCacheStaleWithDuration(inSeconds: cacheDurationInSeconds)) == false
    }

    func testIsCacheStaleIsTrueAfterDurationExpires() {
        let cacheDurationInSeconds: Int32 = 5
        let now = Date()

        let cachedObject = RCInMemoryCachedObject<NSString>()

        guard let oldDate = Calendar.current.date(byAdding: .second, value: -5, to: now) else {
            fatalError("Couldn't set up date for tests")
        }

        cachedObject.cacheInstance("myString")
        cachedObject.lastUpdatedAt = oldDate
        expect(cachedObject.isCacheStaleWithDuration(inSeconds: cacheDurationInSeconds)) == true
    }


    func testIsCacheStaleIsTrueIfTheresNothingCached() {
        let cachedObject = RCInMemoryCachedObject<NSString>()

        expect(cachedObject.isCacheStaleWithDuration(inSeconds: 5)) == true

        cachedObject.cacheInstance("myString")
        cachedObject.clearCache()

        expect(cachedObject.isCacheStaleWithDuration(inSeconds: 5)) == true
    }

    // mark: clearCacheTimestamp

    func testClearCacheTimestampClearsCorrectly() {
        let cachedObject = RCInMemoryCachedObject<NSString>()
        cachedObject.cacheInstance("myString")
        expect(cachedObject.lastUpdatedAt).toNot(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())

        cachedObject.clearCacheTimestamp()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())
    }

    // mark: clearCache

    func testClearCacheClearsCorrectly() {
        let cachedObject = RCInMemoryCachedObject<NSString>()
        cachedObject.cacheInstance("myString")

        expect(cachedObject.lastUpdatedAt).toNot(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())

        cachedObject.clearCache()

        expect(cachedObject.lastUpdatedAt).to(beNil())
        expect(cachedObject.cachedInstance()).to(beNil())
    }

    // mark: updateCacheTimestampWithDate

    func testUpdateCacheTimestampWithDateUpdatesCorrectly() {
        let myString: NSString = "something"
        let cachedObject = RCInMemoryCachedObject<NSString>()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        let firstDate = Date()
        cachedObject.cacheInstance(myString)

        cachedObject.lastUpdatedAt = firstDate

        let secondDate = Date()
        cachedObject.updateCacheTimestamp(with: secondDate)

        expect(cachedObject.lastUpdatedAt) == secondDate
    }

    // mark: cacheInstance:date

    func testCacheInstanceWithDateCachesInstanceCorrectly() {
        let myString: NSString = "something"
        let cachedObject = RCInMemoryCachedObject<NSString>()
        cachedObject.cacheInstance(myString)

        expect(cachedObject.cachedInstance()) == myString
    }

    func testCacheInstanceWithDateSetsDateCorrectly() {
        let myString: NSString = "something"
        let cachedObject = RCInMemoryCachedObject<NSString>()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        let newDate = Date()
        cachedObject.cacheInstance(myString)

        expect(cachedObject.lastUpdatedAt).to(beCloseTo(newDate))
    }
}
