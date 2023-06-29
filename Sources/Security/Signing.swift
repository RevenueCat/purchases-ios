//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Signing.swift
//
//  Created by Nacho Soto on 1/13/23.

import CryptoKit
import Foundation

/// A type that can verify signatures.
protocol SigningType {

    static func verify(
        signature: String,
        with parameters: Signing.SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> Bool

}

/// Utilities for handling signature verification.
enum Signing: SigningType {

    /// An object that represents a cryptographic key.
    typealias PublicKey = SigningPublicKey

    /// Parameters used for signature creation / verification.
    struct SignatureParameters {

        let message: Data?
        let nonce: Data?
        let etag: String?
        let requestDate: UInt64

    }

    /// Parses the binary `key` and returns a `PublicKey`
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func loadPublicKey() -> PublicKey {
        func fail(_ error: CustomStringConvertible) -> Never {
            // This would crash the SDK, but the key is known at compile time
            // so if it's encoded incorrectly we would know during tests
            fatalError(error.description)
        }

        guard let key = Data(base64Encoded: Self.publicKey) else {
            fail(Strings.signing.invalid_public_key(Self.publicKey))
        }

        do {
            return try Curve25519.Signing.PublicKey(rawRepresentation: key)
        } catch {
            fail(Strings.signing.invalid_public_key(error.localizedDescription))
        }
    }

    static func verify(
        signature: String,
        with parameters: SignatureParameters,
        publicKey: Signing.PublicKey
    ) -> Bool {
        guard let signature = Data(base64Encoded: signature) else {
            Logger.warn(Strings.signing.signature_not_base64(signature))
            return false
        }

        guard signature.count == SignatureComponent.totalSize else {
            Logger.warn(Strings.signing.signature_invalid_size(signature))
            return false
        }

        // Fixme: verify public key

        let salt = signature.component(.salt)
        let payload = signature.component(.payload)
        let messageToVerify = salt + parameters.asData

        #if DEBUG
        Logger.verbose(Strings.signing.verifying_signature(
            signature: signature,
            parameters: parameters,
            salt: salt,
            payload: payload,
            message: messageToVerify
        ))
        #endif

        let isValid = publicKey.isValidSignature(payload, for: messageToVerify)

        if !isValid {
            Logger.warn(Strings.signing.signature_failed_verification)
        }

        return isValid
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func verificationMode(
        with setting: Configuration.EntitlementVerificationMode
    ) -> ResponseVerificationMode {
        switch setting {
        case .disabled: return .disabled
        case .informational: return .informational(Self.loadPublicKey())
        case .enforced: return .enforced(Self.loadPublicKey())
        }
    }

    /// - Returns: `ResponseVerificationMode.enforced`
    /// This is useful while ``Configuration.EntitlementVerificationMode`` is unavailable.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func enforcedVerificationMode() -> ResponseVerificationMode {
        return .enforced(Self.loadPublicKey())
    }

    // MARK: -

    private static let publicKey = "drCCA+6YAKOAjT7b2RosYNTrRexVWnu+dR5fw/JuKeA="

}

extension Signing {

    /// Verification level with a loaded `PublicKey`
    /// - Seealso: ``Configuration/EntitlementVerificationMode``
    enum ResponseVerificationMode {

        case disabled
        case informational(PublicKey)
        case enforced(PublicKey)

        static let `default`: Self = .disabled

        var publicKey: PublicKey? {
            switch self {
            case .disabled: return nil
            case let .informational(key): return key
            case let .enforced(key): return key
            }
        }

        var isEnabled: Bool {
            switch self {
            case .disabled: return false
            case .informational, .enforced: return true
            }
        }

        var isEnforced: Bool {
            switch self {
            case .disabled, .informational: return false
            case .enforced: return true
            }
        }

    }

}

/// A type representing a public key that can be used to validate signatures
/// The current type used is `CryptoKit.Curve25519.Signing.PublicKey`
protocol SigningPublicKey {

    func isValidSignature(_ signature: Data, for data: Data) -> Bool

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension CryptoKit.Curve25519.Signing.PublicKey: SigningPublicKey {}

// MARK: - Internal implementation (visible for tests)

extension Signing {

    enum SignatureComponent: CaseIterable, Comparable {

        case intermediatePublicKey
        case intermediateKeyExpiration
        case intermediateKeySignature
        case salt
        case payload

        var size: Int {
            switch self {
            case .intermediatePublicKey: return 32
            case .intermediateKeyExpiration: return 4
            case .intermediateKeySignature: return 64
            case .salt: return 16
            case .payload: return 64
            }
        }

        static let signedPublicKeySize: Int = [Self]([
            .intermediatePublicKey,
            .intermediateKeyExpiration,
            .intermediateKeySignature
        ])
        .map(\.size)
        .sum()

        static let totalSize: Int = Self.allCases.map(\.size).sum()

        /// Number of bytes where the component begins
        fileprivate var offset: Int {
            return Self.offsets[self]!
        }

        fileprivate static let offsets: [SignatureComponent: Int] = Set(Self.allCases)
            .dictionaryWithValues { component in
                Self.allCases
                    .prefix(while: { $0 != component })
                    .map(\.size)
                    .sum()
            }
    }

}

extension Signing.SignatureParameters {

    var asData: Data {
        return (
            (self.nonce ?? .init()) +
            String(self.requestDate).asData +
            (self.etag ?? "").asData +
            (self.message ?? .init())
        )
    }

}

// MARK: - Private

private final class BundleToken: NSObject {}

// MARK: - Data extensions

private extension Data {

    /// Extracts `Signing.SignatureComponent` from the receiver.
    func component(_ component: Signing.SignatureComponent) -> Data {
        let offset = component.offset
        let size = component.size

        return self.subdata(in: offset ..< offset + size)
    }

}
