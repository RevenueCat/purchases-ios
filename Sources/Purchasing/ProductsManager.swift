//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManager.swift
//
//  Created by Andrés Boedo on 7/14/20.
//

import Foundation
import StoreKit

/// Protocol for a type that can fetch and cache ``StoreProduct``s.
/// The basic interface only has a completion-blocked based API, but default `async` overloads are provided.
protocol ProductsManagerType: Sendable {

    typealias Completion = (Result<Set<StoreProduct>, PurchasesError>) -> Void

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    typealias SK2Completion = (Result<Set<SK2StoreProduct>, PurchasesError>) -> Void

    /// Fetches the ``StoreProduct``s with the given identifiers
    /// The returned products will be SK1 or SK2 backed depending on the implementation and configuration.
    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion)

    /// Fetches the `SK2StoreProduct`s with the given identifiers.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>, completion: @escaping SK2Completion)

    /// Adds the products to the internal cache
    /// If the type implementing this protocol doesn't have a caching mechanism then this method does nothing.
    func cache(_ product: StoreProductType)

    /// Removes all elements from its internal cache
    /// If the type implementing this protocol doesn't have a caching mechanism then this method does nothing.
    func clearCache()

    var requestTimeout: TimeInterval { get }

}

// MARK: -

/// Basic implemenation of a `ProductsManagerType`
class ProductsManager: NSObject, ProductsManagerType {

    private let productsFetcherSK1: ProductsFetcherSK1
    private let systemInfo: SystemInfo

#if swift(>=5.7)
    private let _productsFetcherSK2: (any Sendable)?
#else
    private let _productsFetcherSK2: Any?
#endif

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private var productsFetcherSK2: ProductsFetcherSK2 {
        // swiftlint:disable:next force_cast
        return self._productsFetcherSK2! as! ProductsFetcherSK2
    }

    init(
        productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
        systemInfo: SystemInfo,
        requestTimeout: TimeInterval
    ) {
        self.productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                     requestTimeout: requestTimeout)
        self.systemInfo = systemInfo

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self._productsFetcherSK2 = ProductsFetcherSK2()
        } else {
            self._productsFetcherSK2 = nil
        }
    }

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
            self.sk2Products(withIdentifiers: identifiers) { result in
                completion(result.map { Set($0.map(StoreProduct.from(product:))) })
            }
        } else {
            self.sk1Products(withIdentifiers: identifiers) { result in
                completion(result.map { Set($0.map(StoreProduct.init(sk1Product:))) })
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>, completion: @escaping SK2Completion) {
        Async.call(with: completion) {
            do {
                let products = try await self.productsFetcherSK2.products(identifiers: identifiers)

                Logger.debug(Strings.storeKit.store_product_request_finished)
                return Set(products)
            } catch {
                Logger.debug(Strings.storeKit.store_products_request_failed(error: error))
                throw ErrorUtils.storeProblemError(error: error)
            }
        }
    }

    // This class does not implement caching.
    // See `CachingProductsManager`.
    func cache(_ product: StoreProductType) {}
    func clearCache() {
        self.productsFetcherSK1.clearCache()
    }

    var requestTimeout: TimeInterval {
        return self.productsFetcherSK1.requestTimeout
    }

}

// MARK: - private

private extension ProductsManager {

    func sk1Products(withIdentifiers identifiers: Set<String>,
                     completion: @escaping (Result<Set<SK1Product>, PurchasesError>) -> Void) {
        return self.productsFetcherSK1.sk1Products(withIdentifiers: identifiers, completion: completion)
    }

}

// MARK: - ProductsManagerType async

extension ProductsManagerType {

    /// `async` overload for `products(withIdentifiers:)`
    @available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
    func products(withIdentifiers identifiers: Set<String>) async throws -> Set<StoreProduct> {
        return try await Async.call { completion in
            self.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    /// `async` overload for `sk2Products(withIdentifiers:)`
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        return try await Async.call { completion in
            self.sk2Products(withIdentifiers: identifiers, completion: completion)
        }
    }

}

// MARK: -

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
// However it contains no mutable state, and its members are all `Sendable`.
extension ProductsManager: @unchecked Sendable {}
