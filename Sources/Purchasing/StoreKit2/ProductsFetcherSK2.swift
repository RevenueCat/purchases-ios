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
    private var cachedProductsStorefrontIdentifier: String?

    func products(identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        do {
            if let cachedProducts = await self.cachedProducts(withIdentifiers: identifiers) {
                return cachedProducts
            }

            let storeKitProducts = try await StoreKit.Product.products(for: identifiers)
            let sk2StoreProducts = Set(storeKitProducts.map { SK2StoreProduct(sk2Product: $0) })

            await self.cache(products: sk2StoreProducts)

            return sk2StoreProducts
        } catch {
            throw Error.productsRequestError(innerError: error)
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension ProductsFetcherSK2 {

    func cachedProducts(withIdentifiers identifiers: Set<String>) async -> Set<SK2StoreProduct>? {
        guard await self.cachedProductsStorefrontIdentifier == self.currentStorefrontIdentifier else {
            if !self.cachedProductsByIdentifier.isEmpty {
                Logger.debug(Strings.offering.product_cache_invalid_for_storefront_change)
            }

            return nil
        }

        let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }
        if productsAlreadyCached.count == identifiers.count {
            Logger.debug(Strings.offering.products_already_cached(identifiers: identifiers))
            return Set(productsAlreadyCached.values)
        } else {
            return nil
        }
    }

    func cache(products: Set<SK2StoreProduct>) async {
        let storeFrontIdentifier = await self.invalidateOutdatedProductsIfNeeded()

        self.cachedProductsStorefrontIdentifier = storeFrontIdentifier
        self.cachedProductsByIdentifier += products.dictionaryWithKeys {
            $0.productIdentifier
        }
    }

    /// - Returns: current `Storefront` identifier
    func invalidateOutdatedProductsIfNeeded() async -> String? {
        let storeFrontIdentifier = await self.currentStorefrontIdentifier

        if storeFrontIdentifier != self.cachedProductsStorefrontIdentifier {
            self.clearCache()
        }

        return storeFrontIdentifier
    }

    func clearCache() {
        self.cachedProductsByIdentifier.removeAll(keepingCapacity: false)
    }

    var currentStorefrontIdentifier: String? {
        // Note: not using `Storefront.updates` because it's not currently possible
        // to avoid race conditions. Updates never arrive on time for tests to detect
        // changes and clear the cache.
        get async { await Storefront.current?.id }
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
