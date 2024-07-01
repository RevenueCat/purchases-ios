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
/// if !customerInfo.entitlements.verification.isVerified {
///   print("Entitlements could not be verified")
/// }
/// ```
///
/// ### Related Articles
/// - [Documentation](https://rev.cat/trusted-entitlements)
///
/// ### Related Symbols
/// - ``Configuration/EntitlementVerificationMode``
/// - ``Configuration/Builder/with(entitlementVerificationMode:)``
/// - ``EntitlementInfos/verification``
@objc(RCVerificationResult)
public enum VerificationResult: Int {

    /// No verification was done.
    ///
    /// This can happen due to:
    /// - Verification is not enabled in ``Configuration``
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

extension VerificationResult {

    /// Whether the result is ``VerificationResult/verified`` or ``VerificationResult/verifiedOnDevice``.
    public var isVerified: Bool {
        switch self {
        case .verified, .verifiedOnDevice:
            return true
        case .notRequested, .failed:
            return false
        }
    }

}

extension VerificationResult: DefaultValueProvider {

    static let defaultValue: Self = .notRequested

}

extension VerificationResult: CustomDebugStringConvertible {

    // swiftlint:disable:next missing_docs
    public var debugDescription: String {
        let prefix = "\(type(of: self))"

        switch self {
        case .notRequested: return "\(prefix).notRequested"
        case .verified: return "\(prefix).verified"
        case .verifiedOnDevice: return "\(prefix).verifiedOnDevice"
        case .failed: return "\(prefix).failed"
        }
    }

}

extension VerificationResult {

    var name: String {
        switch self {
        case .notRequested:
            return "NOT_REQUESTED"
        case .verified:
            return "VERIFIED"
        case .verifiedOnDevice:
            return "VERIFIED_ON_DEVICE"
        case .failed:
            return "FAILED"
        }
    }

}
