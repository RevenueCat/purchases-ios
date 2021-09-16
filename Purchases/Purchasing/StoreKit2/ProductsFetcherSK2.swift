//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerSK2.swift
//
//  Created by Andrés Boedo on 7/23/21.

import Foundation
import StoreKit

enum ProductsManagerSK2Error: Error {

    case productsRequestError(innerError: Error)

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
actor ProductsFetcherSK2 {

    private var cachedProductsByIdentifier: [String: SK2ProductDetails] = [:]

    func products(identifiers: Set<String>) async throws -> Set<SK2ProductDetails> {
        do {
            // todo: also cache requests, so that if a request is in flight for the same products,
            // we don't need to make a new one
            let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
            if productsAlreadyCached.count == identifiers.count {
                let productsAlreadyCachedSet = Set(productsAlreadyCached.values)
                Logger.debug(Strings.offering.products_already_cached(identifiers: identifiers))
                return productsAlreadyCachedSet
            }
            // todo: remove when this gets fixed.
            // limiting to arm architecture since builds on beta 5 fail if other archs are included
            #if arch(arm64)

            let storeKitProducts = try await StoreKit.Product.products(for: identifiers)
            let sk2ProductDetails = storeKitProducts.map { SK2ProductDetails(sk2Product: $0) }
            return Set(sk2ProductDetails)
            #else
            return Set()
            #endif

        } catch {
            throw ProductsManagerSK2Error.productsRequestError(innerError: error)
        }
    }

}
