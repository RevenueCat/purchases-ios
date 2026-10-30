//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CachingProductsManager.swift
//
//  Created by Nacho Soto on 9/14/22.

import Foundation

/// Adds product caching and shares in-flight requests for the configured store.
/// The product results are cached, and it avoids performing concurrent duplicate requests for the same products.
final class CachingProductsManager {

    private let manager: ProductsManagerType

    private let productCache = ProductsCache<StoreProduct>()

    init(manager: ProductsManagerType) {
        assert(!(manager is CachingProductsManager), "Decorating CachingProductsManager with itself")

        self.manager = manager
    }

    func clearCache() {
        // Clear the underlying manager's cache first, so stale products cannot refill this cache after invalidation.
        self.manager.clearCache()
        self.productCache.clear()
    }

}

extension CachingProductsManager: ProductsManagerType {

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        self.productCache.products(withIdentifiers: identifiers, completion: completion) { identifiers, completion in
            self.manager.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    func cache(_ product: StoreProductType) {
        self.productCache.cache([StoreProduct.from(product: product)])
    }

    var requestTimeout: TimeInterval { return self.manager.requestTimeout }

}

extension CachingProductsManager: Sendable {}

/// Shares cached products and in-flight requests. Clearing the cache starts a new generation:
/// existing callers still finish, but their results cannot repopulate the cleared cache.
final class ProductsCache<Product: StoreProductType & Hashable>: Sendable {

    typealias Completion = (Result<Set<Product>, PurchasesError>) -> Void

    private struct RequestKey: Hashable {

        let identifiers: Set<String>
        let generation: Int

    }

    private struct State {

        var productsByIdentifier: [String: Product]
        var completionsByRequest: [RequestKey: [Completion]]
        var generation: Int

    }

    private enum RequestAction {

        case complete(Set<Product>)
        case wait
        case fetch(RequestKey)

    }

    private let state: Atomic<State> = .init(.init(productsByIdentifier: [:], completionsByRequest: [:], generation: 0))

    func products(
        withIdentifiers identifiers: Set<String>,
        completion: @escaping Completion,
        fetcher: (Set<String>, @escaping Completion) -> Void
    ) {
        let identifiers = Set(identifiers.map(CompoundProductIdentifier.canonicalIdentifier))
        let (action, cachedIdentifiers) = self.state.modify { state in
            let cached = state.productsByIdentifier.filter { identifiers.contains($0.key) }
            let missing = identifiers.subtracting(cached.keys)
            guard !missing.isEmpty else {
                return (RequestAction.complete(Set(cached.values)), Set(cached.keys))
            }

            let requestKey = RequestKey(identifiers: missing, generation: state.generation)
            let existingKey = state.completionsByRequest.keys.first {
                $0.generation == requestKey.generation && $0.identifiers.isSuperset(of: missing)
            }
            let key = existingKey ?? requestKey
            state.completionsByRequest[key, default: []].append { result in
                completion(result.map { fetched in
                    let requested = fetched.filter { missing.contains($0.id) }
                    return Set(cached.values) + requested
                })
            }
            return (existingKey == nil ? .fetch(key) : .wait, Set(cached.keys))
        }

        if !cachedIdentifiers.isEmpty {
            Logger.debug(Strings.offering.products_already_cached(identifiers: cachedIdentifiers))
        }
        switch action {
        case .complete(let products):
            completion(.success(products))
        case .wait:
            Logger.debug(Strings.offering.found_existing_product_request(identifiers: identifiers))
        case .fetch(let key):
            Logger.debug(Strings.storeKit.no_cached_products_starting_store_products_request(
                identifiers: key.identifiers
            ))
            fetcher(key.identifiers) { result in
                let completions = self.state.modify { state in
                    if state.generation == key.generation, let products = result.value {
                        state.productsByIdentifier += products.dictionaryAllowingDuplicateKeys { $0.id }
                    }
                    return state.completionsByRequest.removeValue(forKey: key) ?? []
                }
                completions.forEach { $0(result) }
            }
        }
    }

    func cache(_ products: Set<Product>) {
        self.state.modify { $0.productsByIdentifier += products.dictionaryAllowingDuplicateKeys { $0.id } }
    }

    func clear() {
        self.state.modify {
            $0.generation += 1
            $0.productsByIdentifier.removeAll(keepingCapacity: true)
        }
    }

}
