//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductEntitlementMappingFetcher.swift
//
//  Created by Nacho Soto on 3/23/23.

import Foundation

/// A type that can synchronously fetch `ProductEntitlementMapping`.
protocol ProductEntitlementMappingFetcher {

    var productEntitlementMapping: ProductEntitlementMapping? { get }

}
