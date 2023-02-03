//
//  ProductFetcherSK1.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 12/19/22.
//

import RevenueCat
import StoreKit

/// Simplified version of the fetcher in RevenueCat.
/// Used to fetch products directly and test observer mode.
final actor ProductFetcherSK2 {

    func products(with identifiers: Set<String>) async throws -> Set<SK2Product> {
        return try await Set(StoreKit.Product.products(for: identifiers))
    }

}
