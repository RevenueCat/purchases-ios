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

/// `ProductsManagerType` decorator that adds caching behavior on each request.
/// The product results are cached, and it avoids performing concurrent duplicate requests for the same products.
final class CachingProductsManager {

    private let manager: ProductsManagerType

    private let productCache: Atomic<[String: StoreProduct]> = .init([:])
    private let requestCache: Atomic<[Set<String>: [Completion]]> = .init([:])

    #if swift(>=5.7)
    private let _sk2ProductCache: (any Sendable)?
    private let _sk2RequestCache: (any Sendable)?
    #else
    private let _sk2ProductCache: Any?
    private let _sk2RequestCache: Any?
    #endif

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private var sk2ProductCache: Atomic<[String: SK2StoreProduct]> {
        // swiftlint:disable:next force_cast
        return self._sk2ProductCache as! Atomic<[String: SK2StoreProduct]>
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private var sk2RequestCache: Atomic<[Set<String>: [SK2Completion]]> {
        // swiftlint:disable:next force_cast
        return self._sk2RequestCache as! Atomic<[Set<String>: [SK2Completion]]>
    }

    init(manager: ProductsManagerType) {
        assert(!(manager is CachingProductsManager), "Decorating CachingProductsManager with itself")

        self.manager = manager

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self._sk2ProductCache = Atomic<[String: SK2StoreProduct]>([:])
            self._sk2RequestCache = Atomic<[Set<String>: [SK2Completion]]>([:])
        } else {
            self._sk2ProductCache = nil
            self._sk2RequestCache = nil
        }
    }

    func clearCache() {
        self.productCache.value.removeAll(keepingCapacity: true)
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self.sk2ProductCache.value.removeAll(keepingCapacity: true)
        }

        self.manager.clearCache()
    }

}

extension CachingProductsManager: ProductsManagerType {

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        Self.products(with: identifiers,
                      completion: completion,
                      productCache: self.productCache,
                      requestCache: self.requestCache) { identifiers, completion in
            self.manager.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>, completion: @escaping SK2Completion) {
        Self.products(with: identifiers,
                      completion: completion,
                      productCache: self.sk2ProductCache,
                      requestCache: self.sk2RequestCache) { identifiers, completion in
            self.manager.sk2Products(withIdentifiers: identifiers, completion: completion)
        }
    }

    func cache(_ product: StoreProductType) {
        Self.cache([StoreProduct.from(product: product)], container: self.productCache)
    }

    var requestTimeout: TimeInterval { return self.manager.requestTimeout }

}

#if swift(>=5.7)
extension CachingProductsManager: Sendable {}
#else
// @unchecked because:
// - It contains `any`
extension CachingProductsManager: @unchecked Sendable {}
#endif

// MARK: - Private

private extension CachingProductsManager {

    static func products<T: StoreProductType>(
        with identifiers: Set<String>,
        completion: @escaping (Result<Set<T>, PurchasesError>) -> Void,
        productCache: Atomic<[String: T]>,
        requestCache: Atomic<[Set<String>: [(Result<Set<T>, PurchasesError>) -> Void]]>,
        fetcher: (Set<String>, @escaping (Result<Set<T>, PurchasesError>) -> Void) -> Void
    ) {
        let cachedProducts = Self.cachedProducts(with: identifiers, productCache: productCache)
        let missingProducts = identifiers.subtracting(cachedProducts.keys)

        if missingProducts.isEmpty {
            completion(.success(Set(cachedProducts.values)))
        } else {
            let requestInProgress = Self.save(completion, for: missingProducts, requestCache: requestCache)
            guard !requestInProgress else {
                Logger.debug(Strings.offering.found_existing_product_request(identifiers: missingProducts))
                return
            }

            Logger.debug(
                Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: missingProducts)
            )

            fetcher(missingProducts) { result in
                if let products = result.value {
                    Self.cache(products, container: productCache)
                }

                for completion in Self.getAndClearRequestCompletion(for: missingProducts, requestCache: requestCache) {
                    completion(
                        result.map { Set(cachedProducts.values) + $0 }
                    )
                }
            }
        }
    }

    static func cachedProducts<T: StoreProductType>(
        with identifiers: Set<String>,
        productCache: Atomic<[String: T]>
    ) -> [String: T] {
        let productsAlreadyCached = productCache.value.filter { identifiers.contains($0.key) }

        if !productsAlreadyCached.isEmpty {
            Logger.debug(Strings.offering.products_already_cached(identifiers: Set(productsAlreadyCached.keys)))

        }

        return productsAlreadyCached
    }

    static func cache<T: StoreProductType>(_ products: Set<T>, container: Atomic<[String: T]>) {
        container.value += products.dictionaryWithKeys { $0.productIdentifier }
    }

    /// - Returns: true if there is already a request in progress for these products.
    static func save<T: StoreProductType>(
        _ completion: @escaping (Result<Set<T>, PurchasesError>) -> Void,
        for identifiers: Set<String>,
        requestCache: Atomic<[Set<String>: [(Result<Set<T>, PurchasesError>) -> Void]]>
    ) -> Bool {
        return requestCache.modify { cache in
            let existingRequest = cache[identifiers]?.isEmpty == false

            cache[identifiers, default: []].append(completion)
            return existingRequest
        }
    }

    /// - Returns: completion blocks for requests for the given identifiers.
    static func getAndClearRequestCompletion<T: StoreProductType>(
        for identifiers: Set<String>,
        requestCache: Atomic<[Set<String>: [(Result<Set<T>, PurchasesError>) -> Void]]>
    ) -> [(Result<Set<T>, PurchasesError>) -> Void] {
        return requestCache.modify {
            return $0.removeValue(forKey: identifiers) ?? []
        }
    }

}
