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

/// Entitlement reward granted after successful reward verification.
@_spi(Experimental) public struct EntitlementReward: Sendable, Equatable {

    /// Entitlement identifier.
    public let identifier: String

    /// Grant expiration.
    public let expiresAt: Date

    internal init?(identifier: String, expiresAt: Date) {
        guard !identifier.isEmpty else { return nil }
        self.identifier = identifier
        self.expiresAt = expiresAt
    }
}
