//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockExternalPurchasesConfigProvider.swift
//
//  Created by Antonio Pallares on 21/9/26.

import Foundation
@testable import RevenueCat

final class MockExternalPurchasesConfigProvider: ExternalPurchasesConfigProviderType {

    var stubbedAllowedStorefronts: Set<String> = []

    /// Stubbed as reporting, so a test that says nothing about it exercises the notice and token path.
    var stubbedReportsTokens: Bool = true

    private(set) var invokedAllowedStorefrontsCount: Int = 0
    private(set) var invokedReportsTokensCount: Int = 0

    func storefrontsAllowedWithoutStoreEligibility() async -> Set<String> {
        self.invokedAllowedStorefrontsCount += 1
        return self.stubbedAllowedStorefronts
    }

    func reportsTokensToTheAppStore() async -> Bool {
        self.invokedReportsTokensCount += 1
        return self.stubbedReportsTokens
    }

}

extension MockExternalPurchasesConfigProvider: @unchecked Sendable {}
