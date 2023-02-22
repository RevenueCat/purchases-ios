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
        message: Data,
        nonce: Data,
        hasValidSignature signature: String,
        with publicKey: Signing.PublicKey
    ) -> Bool

}

/// Utilities for handling signature verification.
enum Signing: SigningType {

    /// An object that represents a cryptographic key.
    typealias PublicKey = SigningPublicKey

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
        message: Data,
        nonce: Data,
        hasValidSignature signature: String,
        with publicKey: PublicKey
    ) -> Bool {
        guard let signature = Data(base64Encoded: signature) else {
            Logger.warn(Strings.signing.signature_not_base64(signature))
            return false
        }

        let salt = signature.subdata(in: 0..<Self.saltSize)
        let signatureToVerify = signature.subdata(in: Self.saltSize..<signature.count)
        let messageToVerify = salt + nonce + message

        let isValid = publicKey.isValidSignature(signatureToVerify, for: messageToVerify)

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

    // MARK: -

    private static let publicKey = "UC1upXWg5QVmyOSwozp755xLqquBKjjU+di6U8QhMlM="

    internal static let saltSize = 16
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

    /// Loads the key in `url` and returns a `PublicKey`
    /// - Throws: ``ErrorCode/configurationError`` if the certificate couldn't be loaded.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func loadPublicKey(in url: URL) throws -> PublicKey {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ErrorUtils.configurationError(
                message: Strings.configure.public_key_could_not_be_found(fileName: url.relativeString).description,
                underlyingError: error
            )
        }

        return try Self.loadPublicKey(with: data)
    }

    /// Parses the binary `key` and returns a `PublicKey`
    /// - Throws: ``ErrorCode/configurationError`` if the certificate couldn't be loaded.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func loadPublicKey(with data: Data) throws -> PublicKey {
        guard !data.isEmpty else {
            throw ErrorUtils.configurationError(message: Strings.configure.public_key_is_empty.description)
        }

        do {
            // Fix-me: figure out the prefix with the final production key.
            return try CryptoKit.Curve25519.Signing.PublicKey(rawRepresentation: data.prefix(32))
        } catch {
            throw ErrorUtils.configurationError(
                message: Strings.configure.public_key_could_not_load_key.description,
                underlyingError: error
            )
        }
    }

}

// MARK: - Private

private final class BundleToken: NSObject {}
