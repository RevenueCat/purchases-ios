//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StorefrontProvider.swift
//
//  Created by Nacho Soto on 11/17/23.

import Foundation

/// A type that can determine the current `Storefront`.
protocol StorefrontProviderType {

    /// The current `StorefrontType`, if available.
    ///
    /// In iOS 15+, it uses StoreKit 2's async API to retrieve the current storefront.
    ///
    /// This is the preferred way to access the current storefront, as it prevents blocking the current thread.
    var currentStorefront: StorefrontType? { get async }

    /// The current `StorefrontType`, if available.
    ///
    /// - Important: This is a synchronous API that uses StoreKit 1, and may block the current thread.
    /// The preferred way to access the current storefront is via `currentStorefront`.
    var syncStorefront: StorefrontType? { get }

}

/// Main ``StorefrontProviderType`` implementation.
/// Relies on StoreKit 1 because StoreKit 2's implementation would be `async`.
final class DefaultStorefrontProvider: StorefrontProviderType {

    var currentStorefront: StorefrontType? {
        get async {
            return await Storefront.currentStorefrontType
        }
    }

    var syncStorefront: StorefrontType? {
        return Storefront.sk1CurrentStorefrontType
    }
}
