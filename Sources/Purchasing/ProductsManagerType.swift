//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerType.swift
//
//  Created by Antonio Pallares on 25/7/25.

import Foundation

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
