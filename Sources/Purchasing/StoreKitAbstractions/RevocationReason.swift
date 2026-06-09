//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RevocationReason.swift

import Foundation
import StoreKit

/// Indicates the reason for a transaction revocation.
///
/// This mirrors StoreKit 2's `Transaction.RevocationReason` (available on iOS 15+, macOS 12+,
/// tvOS 15+, watchOS 8+).
///
/// When the revocation reason cannot be determined, the property is `nil`. This happens for:
/// - All StoreKit 1 transactions (SK1 does not expose revocation metadata).
/// - StoreKit 2 transactions that were not revoked.
public struct RevocationReason: RawRepresentable, Equatable, Sendable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let developerIssue = RevocationReason(rawValue: "developer_issue")
    public static let other = RevocationReason(rawValue: "other")

}

// MARK: - StoreKit 2

#if swift(>=5.9)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension RevocationReason {

    /// Creates a ``RevocationReason`` from a StoreKit 2 `Transaction.RevocationReason`.
    ///
    /// Returns `nil` for unrecognized reasons.
    init?(sk2RevocationReason reason: SK2Transaction.RevocationReason) {
        switch reason {
        case .developerIssue:
            self = .developerIssue
        case .other:
            self = .other
        default:
            Logger.appleWarning(
                Strings.storeKit.sk2_unknown_revocation_reason(String(describing: reason))
            )
            return nil
        }
    }

}
#endif
