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
    static func loadPublicKey(_ key: Data) throws -> PublicKey {
        guard !key.isEmpty else {
            throw ErrorUtils.configurationError(message: "Attempted to use an empty public key.")
        }

        guard let certificate = SecCertificateCreateWithData(nil, key as CFData) else {
            // TODO: add reference to docs here
            throw ErrorUtils.configurationError(
                message: "Failed to load certificate. Ensure that it's a valid X.509 certificate."
            )
        }

        guard let key = SecCertificateCopyKey(certificate) else {
            // TODO: add reference to docs here
            throw ErrorUtils.configurationError(
                message: "Failed to copy key from certificate. Ensure that it's a valid X.509 certificate."
            )
        }

        return key
    }

}
