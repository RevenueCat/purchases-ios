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

    /// Getter is declared as `internal` for testing purposes only.
    private(set) var cachedProductsByIdentifier: [String: SK2StoreProduct] = [:]

    func products(identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        do {
            if let cachedProducts = await self.cachedProducts(withIdentifiers: identifiers) {
                Logger.debug(
                    Strings.offering.products_already_cached(
                        identifiers: Set(cachedProducts.map { $0.productIdentifier})
                    )
                )
                return cachedProducts
            }

            Logger.debug(
                Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: identifiers)
            )

            let storeKitProducts = try await StoreKit.Product.products(for: identifiers)
            Logger.rcSuccess(Strings.storeKit.store_product_request_received_response)
            let sk2StoreProducts = Set(storeKitProducts.map { SK2StoreProduct(sk2Product: $0) })

            await self.cache(products: sk2StoreProducts)

            return sk2StoreProducts
        } catch {
            throw Error.productsRequestError(innerError: error)
        }
    }

    /// - Returns: The product identifiers that were removed, or empty if there were not
    ///   cached products.
    @discardableResult
    func clearCache() -> Set<String> {
        let cachedProductIdentifiers = self.cachedProductsByIdentifier.keys
        if !cachedProductIdentifiers.isEmpty {
            Logger.debug(Strings.offering.product_cache_invalid_for_storefront_change)
            self.cachedProductsByIdentifier.removeAll(keepingCapacity: false)
        }
        return Set(cachedProductIdentifiers)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension ProductsFetcherSK2 {

    func cachedProducts(withIdentifiers identifiers: Set<String>) async -> Set<SK2StoreProduct>? {
        let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
        if productsAlreadyCached.count == identifiers.count {
            Logger.debug(Strings.offering.products_already_cached(identifiers: identifiers))
            return Set(productsAlreadyCached.values)
        } else {
            return nil
        }
    }

    func cache(products: Set<SK2StoreProduct>) async {
        self.cachedProductsByIdentifier += products.dictionaryWithKeys {
            $0.productIdentifier
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
