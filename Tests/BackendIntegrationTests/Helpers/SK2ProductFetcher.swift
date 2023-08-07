//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2ProductFetcher.swift
//
//  Created by Nacho Soto on 7/27/23.

import RevenueCat
import StoreKit

/// Simplified version of the fetcher in RevenueCat.
/// Used to fetch products directly and test observer mode.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
final actor SK2ProductFetcher {

    func products(with identifiers: Set<String>) async throws -> Set<SK2Product> {
        return try await Set(StoreKit.Product.products(for: identifiers))
    }

}
