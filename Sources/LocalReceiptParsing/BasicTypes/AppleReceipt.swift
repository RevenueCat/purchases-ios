//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppleReceipt.swift
//
//  Created by Andrés Boedo on 7/22/20.
//

import Foundation

/// The contents of a parsed IAP receipt parsed by ``PurchasesReceiptParser``.
/// - Seealso: [the official documentation](https://rev.cat/apple-receipt-fields).
public struct AppleReceipt: Equatable {

    /// The app's bundle identifier.
    /// This corresponds to the value of `CFBundleIdentifier` in the `Info.plist` file.
    /// Use this value to validate if the receipt was indeed generated for your app.
    public let bundleId: String

    /// The app's version number.
    /// This corresponds to the value of `CFBundleVersion` (in `iOS`)
    /// or `CFBundleShortVersionString` (in `macOS`) in the `Info.plist`.
    public let applicationVersion: String

    /// The version of the app that was originally purchased.
    /// This corresponds to the value of `CFBundleVersion` (in `iOS`)
    /// or `CFBundleShortVersionString` (in `macOS`) in the `Info.plist` file
    /// when the purchase was originally made.
    /// In the sandbox environment, the value of this field is always “1.0”.
    public let originalApplicationVersion: String?

    /// An opaque value used, with other data, to compute the SHA-1 hash during validation.
    public let opaqueValue: Data

    /// A SHA-1 hash, used to validate the receipt.
    public let sha1Hash: Data

    /// The date when the app receipt was created.
    /// When validating a receipt, use this date to validate the receipt’s signature.
    ///
    /// - Note: Many cryptographic libraries default to using the device’s current time and date when validating
    /// a PKCS7 package, but this may not produce the correct results when validating a receipt’s signature.
    /// For example, if the receipt was signed with a valid certificate, but the certificate has since expired,
    /// using the device’s current date incorrectly returns an invalid result.
    /// Therefore, make sure your app always uses the date from
    /// the Receipt Creation Date field to validate the receipt’s signature.
    public let creationDate: Date

    /// The date that the app receipt expires.
    /// This key is present only for apps purchased through the Volume Purchase Program.
    /// If this key is not present, the receipt does not expire.
    /// When validating a receipt, compare this date to the current date to determine whether the receipt is expired.
    /// Do not try to use this date to calculate any other information, such as the time remaining before expiration.
    public let expirationDate: Date?

    /// Individual purchases contained in this receipt.
    public let inAppPurchases: [InAppPurchase]

}

#if swift(>=5.7)
extension AppleReceipt: Sendable {}
#else
// `@unchecked` because:
// - `Date` is not `Sendable` until Swift 5.7
extension AppleReceipt: @unchecked Sendable {}
#endif

// MARK: - Extensions

extension AppleReceipt {

    var activeSubscriptionsProductIdentifiers: Set<String> {
        return Set(
            self.inAppPurchases
                .lazy
                .filter(\.isActiveSubscription)
                .map(\.productId)
        )
    }

    var expiredTrialProductIdentifiers: Set<String> {
        return Set(
            self.inAppPurchases
                .lazy
                .filter(\.isExpiredSubscription)
                .filter { $0.isInIntroOfferPeriod == true || $0.isInTrialPeriod == true }
                .map(\.productId)
        )
    }

    func containsActivePurchase(forProductIdentifier identifier: String) -> Bool {
        return (
            self.inAppPurchases.contains { $0.isActiveSubscription } ||
            self.inAppPurchases.contains { !$0.isSubscription && $0.productId == identifier }
        )
    }

    /// Returns the most recent subscription (see `InAppPurchase.isActiveSubscription`).
    var mostRecentActiveSubscription: InAppPurchase? {
        return self.inAppPurchases
            .lazy
            .filter { $0.isActiveSubscription }
            .min { $0.purchaseDate > $1.purchaseDate }
    }

}

// MARK: - Conformances

extension AppleReceipt: Codable {}

extension AppleReceipt: CustomDebugStringConvertible {

    /// swiftlint:disable:next missing_docs
    public var debugDescription: String {
        return (try? self.prettyPrintedJSON) ?? "<null>"
    }

}
