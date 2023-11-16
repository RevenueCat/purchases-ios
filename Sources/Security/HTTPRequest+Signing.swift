//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequest+Signing.swift
//
//  Created by Nacho Soto on 11/16/23.

import CryptoKit
import Foundation

extension HTTPRequest {

    static func headerParametersForSignatureHeader(headers: Headers) -> String? {
        guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) else {
            // Signature verification is not available.
            return nil
        }

        let headersToSign = Self.headersToSign.map(\.rawValue)

        if !headersToSign.isEmpty, let hash = Self.postParameterHash(headers) {
            return Self.signatureHashHeader(keys: headersToSign, hash: hash)
        } else {
            return nil
        }
    }

    /// - Returns: `nil` if none of the requested headers are found
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    private static func postParameterHash(_ headers: Headers) -> String? {
        let headersToSign = Self.headersToSign.map(\.rawValue)
        let values = headers
            .filter { headersToSign.contains($0.key) }
            .map(\.value)

        guard !values.isEmpty else { return nil }

        return Self.signingParameterHash(values)
    }

}

extension HTTPRequest {

    static func signatureHashHeader(
        keys: [String],
        hash: String
    ) -> String {
        return [
            keys.joined(separator: ","),
            postParameterHashingAlgorithmName,
            hash
        ].joined(separator: ":")
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func signingParameterHash(_ values: [String]) -> String {
        var sha256 = SHA256()

        for (index, value) in values.enumerated() {
            if index > 0 {
                sha256.update(data: fieldSeparator)
            }

            sha256.update(data: value.asData)
        }

        return sha256.toString()
    }

}

// MARK: - Private

private extension HTTPRequest {

    /// Ordered list of header keys that will be included in the signature.
    static let headersToSign: [HTTPClient.RequestHeader] = [
        .sandbox
    ]

}

private let postParameterHashingAlgorithmName = "sha256"
private let fieldSeparator = Data(bytes: [0x00], count: 1)
