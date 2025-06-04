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

    var stubbedVirtualCurrenciesResult: RevenueCat.VirtualCurrencies = VirtualCurrencies(
        virtualCurrencies: [:]
    )

    var virtualCurrenciesCallCount = 0
    var virtualCurrenciesCalled = false
    var virtualCurrenciesCallParameters: [Bool] = []
    func virtualCurrencies(forceRefresh: Bool) async throws -> RevenueCat.VirtualCurrencies {
        self.virtualCurrenciesCallCount += 1
        self.virtualCurrenciesCalled = true
        self.virtualCurrenciesCallParameters.append(forceRefresh)

        return stubbedVirtualCurrenciesResult
    }
}
