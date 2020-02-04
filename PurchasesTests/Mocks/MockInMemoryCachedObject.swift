//
// Created by RevenueCat on 2/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Purchases

class MyMutableArray<T:AnyObject> : NSMutableArray {

}

class MockInMemoryCachedObject<T:AnyObject> : RCInMemoryCachedObject<AnyObject> {

//    required init(cacheDurationInSeconds: Int32) {
//    }
//
//    required init(cacheDurationInSeconds: Int32, lastUpdatedAt: Date?) {
//    }
//
//    required init(cacheDurationInSeconds: Int32, lastUpdatedAt: Date?, stubbedNow: Date?) {
//    }

    var invokedIsCacheStale = false
    var invokedIsCacheStaleCount = 0
    var stubbedIsCacheStaleResult: Bool! = false

    override func isCacheStale() -> Bool {
        invokedIsCacheStale = true
        invokedIsCacheStaleCount += 1
        return stubbedIsCacheStaleResult
    }

    var invokedClearCacheTimestamp = false
    var invokedClearCacheTimestampCount = 0

    override func clearCacheTimestamp() {
        invokedClearCacheTimestamp = true
        invokedClearCacheTimestampCount += 1
    }

    var invokedClearCache = false
    var invokedClearCacheCount = 0

    override func clearCache() {
        invokedClearCache = true
        invokedClearCacheCount += 1
    }

    var invokedUpdateCacheTimestamp = false
    var invokedUpdateCacheTimestampCount = 0
    var invokedUpdateCacheTimestampParameters: (date: Date, Void)?
    var invokedUpdateCacheTimestampParametersList = [(date: Date, Void)]()

    override func updateCacheTimestamp(with date: Date) {
        invokedUpdateCacheTimestamp = true
        invokedUpdateCacheTimestampCount += 1
        invokedUpdateCacheTimestampParameters = (date, ())
        invokedUpdateCacheTimestampParametersList.append((date, ()))
    }

    var invokedCacheInstance = false
    var invokedCacheInstanceCount = 0
    var invokedCacheInstanceParameters: (instance: T, date: Date)?
    var invokedCacheInstanceParametersList = [(instance: T, date: Date)]()

//    override func cacheInstance(_ instance: T, date: Date) {
//        invokedCacheInstance = true
//        invokedCacheInstanceCount += 1
//        invokedCacheInstanceParameters = (instance, date)
//        invokedCacheInstanceParametersList.append((instance, date))
//    }
//
//    var invokedCachedInstance = false
//    var invokedCachedInstanceCount = 0
//    var stubbedCachedInstanceResult: T!
//
//    override func cachedInstance() -> T? {
//        invokedCachedInstance = true
//        invokedCachedInstanceCount += 1
//        return stubbedCachedInstanceResult
//    }
}