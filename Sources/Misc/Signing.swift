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

import Foundation
import Security

/// Utilities for handling certificates and keys.
enum Signing {

    /// A type object representing an X.509 certificate.
    typealias Certificate = SecCertificate
    /// An object that represents a cryptographic key.
    typealias PublicKey = SecKey

    /// Parses the binary `key` and returns a `PublicKey`
    /// - Throws: ``ErrorCode/configurationError`` if the certificate couldn't be loaded.
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    static func loadPublicKey() throws -> PublicKey {
        guard let url = Bundle(for: BundleToken.self)
            .url(forResource: Self.publicKeyFileName, withExtension: Self.publicKeyFileExtension) else {
            throw ErrorUtils.configurationError(
                message: Strings.configure.public_key_could_not_be_found(
                    fileName: "\(Self.publicKeyFileName).\(Self.publicKeyFileExtension)"
                ).description
            )
        }

        return try Self.loadPublicKey(in: url)
    }

    /// - Throws: ``ErrorCode/configurationError``
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    static func verificationLevel(
        with setting: Configuration.EntitlementVerificationLevel
    ) throws -> EntitlementVerificationLevel {
        switch setting {
        case .disabled: return .disabled
        case .informationOnly: return try .informationOnly(Self.loadPublicKey())
        case .enforced: return try .enforced(Self.loadPublicKey())
        }
    }

    // MARK: -

    private static let publicKeyFileName = "public_key"
    private static let publicKeyFileExtension = "cer"

}

extension Signing {

    /// Verification level with a loaded `PublicKey`
    /// - Seealso: ``Configuration/EntitlementVerificationLevel``
    enum EntitlementVerificationLevel {

        case disabled
        case informationOnly(PublicKey)
        case enforced(PublicKey)

        static let `default`: Self = .disabled

        var publicKey: PublicKey? {
            switch self {
            case .disabled: return nil
            case let .informationOnly(key): return key
            case let .enforced(key): return key
            }
        }

    }

}

// MARK: - Internal implementation (visible for tests)

extension Signing {

    /// Loads the key in `url` and returns a `PublicKey`
    /// - Throws: ``ErrorCode/configurationError`` if the certificate couldn't be loaded.
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
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
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    static func loadPublicKey(with data: Data) throws -> PublicKey {
        guard !data.isEmpty else {
            throw ErrorUtils.configurationError(message: Strings.configure.public_key_is_empty.description)
        }

        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            throw ErrorUtils.configurationError(
                message: Strings.configure.public_key_could_not_load_certificate.description
            )
        }

        guard let key = SecCertificateCopyKey(certificate) else {
            throw ErrorUtils.configurationError(
                message: Strings.configure.public_key_could_not_copy_certificate.description
            )
        }

        return key
    }

}

// MARK: - Private

private final class BundleToken: NSObject {}
