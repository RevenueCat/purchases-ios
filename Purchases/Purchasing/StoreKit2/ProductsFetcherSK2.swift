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

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
actor ProductsFetcherSK2 {

    enum Error: Swift.Error {

        case productsRequestError(innerError: Swift.Error)

    }

    private var cachedProductsByIdentifier: [String: SK2StoreProduct] = [:]

    func products(identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        do {
            // todo: also cache requests, so that if a request is in flight for the same products,
            // we don't need to make a new one
            let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
            if productsAlreadyCached.count == identifiers.count {
                let productsAlreadyCachedSet = Set(productsAlreadyCached.values)
                Logger.debug(Strings.offering.products_already_cached(identifiers: identifiers))
                return productsAlreadyCachedSet
            }

            let storeKitProducts = try await StoreKit.Product.products(for: identifiers)
            let sk2StoreProduct = storeKitProducts.map { SK2StoreProduct(sk2Product: $0) }
            return Set(sk2StoreProduct)
        } catch {
            throw Error.productsRequestError(innerError: error)
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension ProductsFetcherSK2.Error: CustomNSError {

    var errorUserInfo: [String: Any] {
        switch self {
        case let .productsRequestError(inner):
            return [
                NSUnderlyingErrorKey: inner
            ]
        }
    }

}
