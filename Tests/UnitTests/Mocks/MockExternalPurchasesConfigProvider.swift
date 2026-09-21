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

    private(set) var invokedAllowedStorefrontsCount: Int = 0

    func storefrontsAllowedWithoutStoreEligibility() async -> Set<String> {
        self.invokedAllowedStorefrontsCount += 1
        return self.stubbedAllowedStorefronts
    }

}

extension MockExternalPurchasesConfigProvider: @unchecked Sendable {}
