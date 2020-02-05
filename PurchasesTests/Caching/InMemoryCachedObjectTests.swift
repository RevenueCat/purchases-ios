//
// Created by RevenueCat on 2/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import Purchases

class InMemoryCachedObjectTests: XCTestCase {

    // mark: isCacheStale

    func testIsCacheStaleIsFalseBeforeDurationExpires() {
        let cacheDurationInSeconds: Int32 = 5
        let now = Date()

        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)
        guard let oldDate = Calendar.current.date(byAdding: .second, value: -4, to: now) else {
            fatalError("Couldn't set up date for tests")
        }

        cachedObject.cacheInstance("myString", date: oldDate)
        expect(cachedObject.isCacheStale()) == false

        cachedObject.lastUpdatedAt = now
        expect(cachedObject.isCacheStale()) == false
    }

    func testIsCacheStaleIsTrueAfterDurationExpires() {
        let cacheDurationInSeconds: Int32 = 5
        let now = Date()

        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)

        guard let oldDate = Calendar.current.date(byAdding: .second, value: -5, to: now) else {
            fatalError("Couldn't set up date for tests")
        }

        cachedObject.cacheInstance("myString", date: oldDate)
        expect(cachedObject.isCacheStale()) == true
    }

    // mark: clearCacheTimestamp

    func testClearCacheTimestampClearsCorrectly() {
        let cacheDurationInSeconds: Int32 = 5

        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)
        cachedObject.cacheInstance("myString", date: Date())
        expect(cachedObject.lastUpdatedAt).toNot(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())

        cachedObject.clearCacheTimestamp()
        expect(cachedObject.lastUpdatedAt).to(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())
    }

    // mark: clearCache

    func testClearCacheClearsCorrectly() {
        let cacheDurationInSeconds: Int32 = 5

        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)
        cachedObject.cacheInstance("myString", date: Date())

        expect(cachedObject.lastUpdatedAt).toNot(beNil())
        expect(cachedObject.cachedInstance()).toNot(beNil())

        cachedObject.clearCache()

        expect(cachedObject.lastUpdatedAt).to(beNil())
        expect(cachedObject.cachedInstance()).to(beNil())
    }

    // mark: updateCacheTimestampWithDate

    func testUpdateCacheTimestampWithDateUpdatesCorrectly() {
        let myString: NSString = "something"
        let cacheDurationInSeconds: Int32 = 5
        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)
        expect(cachedObject.lastUpdatedAt).to(beNil())
        let firstDate = Date()
        cachedObject.cacheInstance(myString, date: firstDate)

        expect(cachedObject.lastUpdatedAt) == firstDate

        let secondDate = Date()
        cachedObject.updateCacheTimestamp(with: secondDate)

        expect(cachedObject.lastUpdatedAt) == secondDate
    }

    // mark: cacheInstance:date

    func testCacheInstanceWithDateCachesInstanceCorrectly() {
        let myString: NSString = "something"
        let cacheDurationInSeconds: Int32 = 5
        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)
        cachedObject.cacheInstance(myString, date: Date())

        expect(cachedObject.cachedInstance()) == myString
    }

    func testCacheInstanceWithDateSetsDateCorrectly() {
        let myString: NSString = "something"
        let cacheDurationInSeconds: Int32 = 5
        let cachedObject = RCInMemoryCachedObject<NSString>(cacheDurationInSeconds: cacheDurationInSeconds)
        expect(cachedObject.lastUpdatedAt).to(beNil())
        let newDate = Date()
        cachedObject.cacheInstance(myString, date: newDate)

        expect(cachedObject.lastUpdatedAt) == newDate
    }
}
