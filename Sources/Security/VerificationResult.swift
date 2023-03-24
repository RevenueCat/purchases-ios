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
/// if customerInfo.entitlements.verification != .verified {
///   print("Entitlements could not be verified")
/// }
/// ```
///
/// ### Related Symbols
/// - ``Configuration/EntitlementVerificationMode``
/// - ``Configuration/Builder/with(entitlementVerificationMode:)``
/// - ``EntitlementInfos/verification``
// Trusted Entitlements: internal until ready to be made public.
@objc(RCVerificationResult)
internal enum VerificationResult: Int {

    /// No verification was done.
    ///
    /// This can happen for multiple reasons:
    ///  1. Verification is not enabled in ``Configuration``
    ///  2. Verification can't be performed prior to iOS 13.0
    case notRequested = 0

    /// Entitlements were verified with our server.
    case verified = 1

    /// Entitlements were created and verified on device through `StoreKit 2`.
    case verifiedOnDevice = 3

    /// Entitlement verification failed, possibly due to a MiTM attack.
    /// ### Related Symbols
    /// - ``ErrorCode/signatureVerificationFailed``
    case failed = 2

}

extension VerificationResult: Sendable, Codable {}

extension VerificationResult: DefaultValueProvider {

    static let defaultValue: Self = .notRequested

}

extension VerificationResult {

    /// - Returns: the most restrictive ``VerificationResult`` based on the cached verification and
    /// the response verification.
    static func from(cache cachedResult: Self, response responseResult: Self) -> Self {
        switch (cachedResult, responseResult) {
        case (.notRequested, .notRequested),
            (.verified, .verified),
            (.verifiedOnDevice, .verifiedOnDevice),
            (.failed, .failed):
            return cachedResult

        case (.verified, .notRequested), (.verifiedOnDevice, .notRequested): return .notRequested
        case (.verified, .failed), (.verifiedOnDevice, .failed): return .failed

        case (.notRequested, .verified), (.notRequested, .verifiedOnDevice): return responseResult
        case (.notRequested, .failed): return .failed

        case (.failed, .notRequested): return .notRequested
        // If the cache verification failed, the etag won't be used
        // so the response would only be a 200 and not 304.
        // Therefore the cache verification error can be ignored
        case (.failed, .verified), (.failed, .verifiedOnDevice): return responseResult

        case (.verifiedOnDevice, .verified), (.verified, .verifiedOnDevice): return responseResult
        }
    }

}
