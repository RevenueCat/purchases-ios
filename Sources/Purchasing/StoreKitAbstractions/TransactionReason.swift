//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionReason.swift

import Foundation
import StoreKit

/// Indicates the reason for a transaction.
///
/// This mirrors StoreKit 2's `Transaction.Reason` (available on iOS 17+, macOS 14+, tvOS 17+, watchOS 10+).
///
/// When the reason cannot be determined, the property is `nil`. This happens for:
/// - All StoreKit 1 transactions (SK1 does not expose a transaction reason).
/// - StoreKit 2 transactions on iOS 16 and earlier (the `reason` property is not available).
enum TransactionReason: String {

    /// The customer initiated the transaction, such as a purchase or a subscription offer redemption.
    case purchase

    /// The App Store server initiated the transaction, such as an auto-renewable subscription renewal.
    case renewal

}

extension TransactionReason: Equatable, Sendable {}

// MARK: - StoreKit 2

#if swift(>=5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension TransactionReason {

    /// Creates a ``TransactionReason`` from a StoreKit 2 `Transaction.Reason`.
    ///
    /// Returns `nil` for unrecognized reasons.
    init?(sk2TransactionReason reason: SK2Transaction.Reason) {
        switch reason {
        case .purchase:
            self = .purchase
        case .renewal:
            self = .renewal
        default:
            Logger.appleWarning(
                Strings.storeKit.sk2_unknown_transaction_reason(String(describing: reason))
            )
            return nil
        }
    }

}
#endif
