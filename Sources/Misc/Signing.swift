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

/// Utilities for handling keys and signing.
enum Signing {

    /// A type object representing an X.509 certificate.
    typealias PublicKey = SecCertificate

    /// Parses the binary `key` and returns a `PublicKey`
    /// - Throws: ``ErrorCode/configurationError`` if the certificate couldn't be loaded.
    static func loadPublicKey(_ key: Data) throws -> PublicKey {
        guard !key.isEmpty else {
            throw ErrorUtils.configurationError(message: "Attempted to use an empty public key.")
        }

        guard let result = SecCertificateCreateWithData(nil, key as CFData) else {
            // TODO: add reference to docs here
            throw ErrorUtils.configurationError(
                message: "Failed to load public key. Ensure that it's a valid X.509 certificate."
            )
        }

        return result
    }

}
