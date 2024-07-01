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

    var currentStorefront: StorefrontType? { get }

}

/// Main ``StorefrontProviderType`` implementation.
/// Relies on StoreKit 1 because StoreKit 2's implementation would be `async`.
final class DefaultStorefrontProvider: StorefrontProviderType {

    var currentStorefront: StorefrontType? {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *) {
            return Storefront.sk1CurrentStorefrontType
        } else {
            return nil
        }
    }

}
