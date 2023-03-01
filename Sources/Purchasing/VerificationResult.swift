//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementVerification.swift
//
//  Created by Nacho Soto on 2/10/23.

import Foundation

/// The result of data verification process.
///
/// This is accomplished by preventing MiTM attacks between the SDK and the RevenueCat server.
/// With verification enabled, the SDK ensures that the response created by the server was not
/// modified by a third-party, and the entitlements received are exactly what was sent.
/// 
/// - Note: Entitlements are only verified if enabled using
/// ``Configuration/Builder/with(entitlementVerificationMode:)``, which is disabled by default.
///
/// ### Example:
/// ```swift
/// let purchases = Purchases.configure(
///   with: Configuration
///     .builder(withAPIKey: "")
///     .with(entitlementVerificationMode: .informational)
/// )
///
/// let customerInfo = try await purchases.customerInfo()
/// if customerInfo.entitlementVerification != .verified {
///   print("Entitlements could not be verified")
/// }
/// ```
///
/// ### Related Symbols
/// - ``Configuration/EntitlementVerificationMode``
/// - ``Configuration/Builder/with(entitlementVerificationMode:)``
/// - ``CustomerInfo/entitlementVerification``
/// - ``EntitlementInfos/verification``
@objc(RCVerificationResult)
public enum VerificationResult: Int {

    /// No verification was done.
    ///
    /// This can happen for multiple reasons:
    ///  1. Verification is not enabled in ``Configuration``
    ///  2. Verification can't be performed prior to iOS 13.0
    ///  3. Data was cached in an older version of the SDK not supporting verification
    case notVerified = 0

    /// Entitlements were verified with our server.
    case verified = 1

    /// Entitlement verification failed, possibly due to a MiTM attack.
    /// ### Related Symbols
    /// - ``ErrorCode/signatureVerificationFailed``
    case failed = 2

}

extension VerificationResult: Sendable, Codable {}

extension VerificationResult: DefaultValueProvider {

    static let defaultValue: Self = .notVerified

}

extension VerificationResult {

    /// - Returns: the most restrictive ``VerificationResult`` based on the cached verification and
    /// the response verification.
    static func from(cache cachedResult: Self, response responseResult: Self) -> Self {
        switch (cachedResult, responseResult) {
        case (.notVerified, .notVerified),
            (.verified, .verified),
            (.failed, .failed):
            return cachedResult

        case (.verified, .notVerified): return .notVerified
        case (.verified, .failed): return .failed

        // These shouldn't happen because `ETagManager` will ignore not verified cached responses
        // if verification is enabled.
        case (.notVerified, .verified): return .notVerified
        case (.notVerified, .failed): return .failed

        // These shouldn't happen because `ETagManager` won't store responses with failed verification.
        case (.failed, .notVerified): return .failed
        case (.failed, .verified): return .failed
        }
    }

}
