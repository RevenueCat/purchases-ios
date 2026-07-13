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
@objc(RCRevocationReason)
public final class RevocationReason: NSObject, RawRepresentable, Sendable {

    /// String representation of the revocation reason.
    @objc public let rawValue: String

    /// Creates a revocation reason with the specified raw value.
    @objc public init(rawValue: String) {
        self.rawValue = rawValue
        super.init()
    }

    /// The transaction was revoked because of an issue with the app.
    @objc(RCDeveloperIssue) public static let developerIssue = RevocationReason(rawValue: "developer_issue")

    /// The transaction was revoked for another reason.
    @objc(RCOther) public static let other = RevocationReason(rawValue: "other")

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RevocationReason else { return false }

        if self === other {
            return true
        }

        return self.rawValue == other.rawValue
    }

    public override var hash: Int {
        return self.rawValue.hashValue
    }

    /// Pattern matching operator.
    public static func ~= (lhs: RevocationReason, rhs: RevocationReason) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

}

// MARK: - StoreKit 2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension RevocationReason {

    /// Creates a ``RevocationReason`` from a StoreKit 2 `Transaction.RevocationReason`.
    ///
    /// Returns `nil` for unrecognized reasons.
    convenience init?(sk2RevocationReason reason: SK2Transaction.RevocationReason) {
        guard let revocationReason = Self.from(sk2RevocationReason: reason) else {
            return nil
        }

        self.init(rawValue: revocationReason.rawValue)
    }

    static func from(sk2RevocationReason reason: SK2Transaction.RevocationReason) -> RevocationReason? {
        switch reason {
        case .developerIssue:
            return Self.developerIssue
        case .other:
            return Self.other
        default:
            Logger.appleWarning(
                Strings.storeKit.sk2_unknown_revocation_reason(String(describing: reason))
            )
            return nil
        }
    }

}
