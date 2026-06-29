//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementReward.swift
//

import Foundation

/// An entitlement reward granted by an ad network after a successful reward verification.
///
/// The entitlement is surfaced through the standard entitlements API; this payload describes the
/// grant that was verified for the rewarded ad.
@_spi(Experimental) public struct EntitlementReward: Sendable, Equatable {

    /// The granted entitlement identifier (the key in the `CustomerInfo` entitlements map).
    public let identifier: String

    /// The moment the granted entitlement expires.
    public let expiresAt: Date

    /// Creates an entitlement reward.
    ///
    /// Returns `nil` if `identifier` is empty. This is the single source of truth for "what counts as a
    /// valid entitlement reward" across the SDK.
    internal init?(identifier: String, expiresAt: Date) {
        guard !identifier.isEmpty else { return nil }
        self.identifier = identifier
        self.expiresAt = expiresAt
    }
}
