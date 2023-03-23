//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockProductEntitlementMappingFetcher.swift
//
//  Created by Nacho Soto on 3/23/23.

import Foundation
@testable import RevenueCat

final class MockProductEntitlementMappingFetcher: ProductEntitlementMappingFetcher {

    var stubbedResult: ProductEntitlementMapping?

    var productEntitlementMapping: ProductEntitlementMapping? {
        return self.stubbedResult
    }

}
