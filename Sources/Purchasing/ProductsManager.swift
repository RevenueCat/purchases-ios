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
    private let diagnosticsTracker: DiagnosticsTrackerType?
    private let systemInfo: SystemInfo
    private let dateProvider: DateProvider

    private let _productsFetcherSK2: (any Sendable)?

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private var productsFetcherSK2: ProductsFetcherSK2 {
        // swiftlint:disable:next force_cast force_unwrapping
        return self._productsFetcherSK2! as! ProductsFetcherSK2
    }

    init(
        productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
        diagnosticsTracker: DiagnosticsTrackerType?,
        systemInfo: SystemInfo,
        requestTimeout: TimeInterval,
        dateProvider: DateProvider = DateProvider()
    ) {
        self.productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                     requestTimeout: requestTimeout)
        self.diagnosticsTracker = diagnosticsTracker
        self.systemInfo = systemInfo
        self.dateProvider = dateProvider

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self._productsFetcherSK2 = ProductsFetcherSK2()
        } else {
            self._productsFetcherSK2 = nil
        }
    }

    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        let startTime = self.dateProvider.now()
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable {
            self.sk2Products(withIdentifiers: identifiers) { result in
                let notFoundProducts = identifiers.subtracting(result.value?.map(\.productIdentifier) ?? [])
                self.trackProductsRequestIfNeeded(startTime,
                                                  requestedProductIds: identifiers,
                                                  notFoundProductIds: notFoundProducts,
                                                  storeKitVersion: .storeKit2,
                                                  error: result.error)
                completion(result.map { Set($0.map(StoreProduct.from(product:))) })
            }
        } else {
            self.sk1Products(withIdentifiers: identifiers) { result in
                let notFoundProducts = identifiers.subtracting(result.value?.map(\.productIdentifier) ?? [])
                self.trackProductsRequestIfNeeded(startTime,
                                                  requestedProductIds: identifiers,
                                                  notFoundProductIds: notFoundProducts,
                                                  storeKitVersion: .storeKit1,
                                                  error: result.error)
                completion(result.map { Set($0.map(StoreProduct.from(product:))) })
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
            } catch let error as NSError {
                Logger.debug(Strings.storeKit.store_products_request_failed(error))
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
                     completion: @escaping (Result<Set<SK1StoreProduct>, PurchasesError>) -> Void) {
        return self.productsFetcherSK1.products(withIdentifiers: identifiers, completion: completion)
    }

    func trackProductsRequestIfNeeded(_ startTime: Date,
                                      requestedProductIds: Set<String>,
                                      notFoundProductIds: Set<String>,
                                      storeKitVersion: StoreKitVersion,
                                      error: PurchasesError?) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           let diagnosticsTracker = self.diagnosticsTracker {
            let responseTime = self.dateProvider.now().timeIntervalSince(startTime)
            let errorMessage = (error?.userInfo[NSUnderlyingErrorKey] as? Error)?.localizedDescription
                ?? error?.localizedDescription
            let errorCode = error?.errorCode
            let storeKitErrorDescription = StoreKitErrorUtils.extractStoreKitErrorDescription(from: error)
            diagnosticsTracker.trackProductsRequest(wasSuccessful: error == nil,
                                                    storeKitVersion: storeKitVersion,
                                                    errorMessage: errorMessage,
                                                    errorCode: errorCode,
                                                    storeKitErrorDescription: storeKitErrorDescription,
                                                    requestedProductIds: requestedProductIds,
                                                    notFoundProductIds: notFoundProductIds,
                                                    responseTime: responseTime)
        }
    }

}

// MARK: - ProductsManagerType async

extension ProductsManagerType {

    /// `async` overload for `products(withIdentifiers:)`
    func products(withIdentifiers identifiers: Set<String>) async throws -> Set<StoreProduct> {
        return try await Async.call { completion in
            self.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    /// `async` overload for `sk2Products(withIdentifiers:)`
    ///
    /// - Throws: `PurchasesError`.
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
