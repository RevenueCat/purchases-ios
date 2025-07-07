//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockVirtualCurrencyManager.swift
//
//  Created by Will Taylor on 6/4/25.

import Foundation
@testable import RevenueCat

class MockVirtualCurrencyManager: VirtualCurrencyManagerType {

    var stubbedVirtualCurrenciesResult: Result<RevenueCat.VirtualCurrencies, Error> = .success(VirtualCurrencies(
        virtualCurrencies: [:]
    ))

    var virtualCurrenciesCallCount = 0
    var virtualCurrenciesCalled = false
    func virtualCurrencies() async throws -> RevenueCat.VirtualCurrencies {
        self.virtualCurrenciesCallCount += 1
        self.virtualCurrenciesCalled = true

        return try stubbedVirtualCurrenciesResult.get()
    }

    var invalidateVirtualCurrenciesCacheCallCount = 0
    var invalidateVirtualCurrenciesCacheCalled = false
    func invalidateVirtualCurrenciesCache() {
        self.invalidateVirtualCurrenciesCacheCallCount += 1
        self.invalidateVirtualCurrenciesCacheCalled = true
    }

    var stubbedCachedVirtualCurrencies: VirtualCurrencies?
    var cachedVirtualCurrenciesCallCount = 0
    var cachedVirtualCurrenciesCalled = false
    func cachedVirtualCurrencies() -> VirtualCurrencies? {
        cachedVirtualCurrenciesCallCount += 1
        cachedVirtualCurrenciesCalled = true
        return stubbedCachedVirtualCurrencies
    }
}
