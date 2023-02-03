//
// Created by RevenueCat on 2/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockInMemoryCachedOfferings<T: Offerings>: InMemoryCachedObject<Offerings> {

    var invokedIsCacheStale = false
    var invokedIsCacheStaleCount = 0
    var stubbedIsCacheStaleResult: Bool! = false

    override func isCacheStale(durationInSeconds: Double) -> Bool {
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

    override func updateCacheTimestamp(date: Date) {
        invokedUpdateCacheTimestamp = true
        invokedUpdateCacheTimestampCount += 1
        invokedUpdateCacheTimestampParameters = (date, ())
        invokedUpdateCacheTimestampParametersList.append((date, ()))
    }

    var invokedCacheInstance = false
    var invokedCacheInstanceCount = 0
    var invokedCacheInstanceParameters: (instance: Offerings, Void)?
    var invokedCacheInstanceParametersList = [(instance: Offerings, Void)]()

    override func cache(instance: Offerings) {
        invokedCacheInstance = true
        invokedCacheInstanceCount += 1
        invokedCacheInstanceParameters = (instance, ())
        invokedCacheInstanceParametersList.append((instance, ()))
    }

    var invokedCachedInstance = false
    var invokedCachedInstanceCount = 0
    var stubbedCachedInstanceResult: Offerings!

    override func cachedInstance() -> Offerings? {
        invokedCachedInstance = true
        invokedCachedInstanceCount += 1
        return stubbedCachedInstanceResult
    }
}
