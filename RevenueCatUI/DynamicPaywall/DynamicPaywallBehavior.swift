//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DynamicPaywallBehavior.swift

import Foundation

/// Defines how a dynamic paywall filters the packages in an offering before presentation.
///
/// Use with `presentDynamicPaywallIfNeeded(behavior:offering:...)` to present paywalls
/// whose visible packages are determined at runtime.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct DynamicPaywallBehavior: Sendable {

    let kind: Kind

    enum Kind: Sendable {
        case upgrade
    }

    /// Presents only packages that represent an upgrade from the user's current subscription.
    ///
    /// The filter:
    /// 1. Identifies the user's active auto-renewable subscription(s) from `CustomerInfo`.
    /// 2. Resolves the corresponding `StoreProduct` to read its subscription group and price.
    /// 3. Keeps only packages whose product belongs to the same subscription group
    ///    and has a higher price than the current subscription.
    ///
    /// If the user has no active subscription, or no upgrade candidates exist,
    /// the paywall is not presented.
    public static let upgrade = DynamicPaywallBehavior(kind: .upgrade)

}
