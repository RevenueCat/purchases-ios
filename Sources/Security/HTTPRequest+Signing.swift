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

    static func headerParametersForSignatureHeader(
        headers: Headers,
        path: HTTPRequestPath
    ) -> String? {
        guard path.needsNonceForSigning else {
            // Static signatures cannot sign header parameters
            return nil
        }

        if let hash = Self.postParameterHash(headers) {
            return Self.signatureHashHeader(keys: Self.headersToSign.map(\.rawValue),
                                            hash: hash)
        } else {
            return nil
        }
    }

    /// - Returns: `nil` if none of the requested headers are found
    private static func postParameterHash(_ headers: Headers) -> String? {
        let values = Self.headersToSign.compactMap { headers[$0.rawValue] }

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

extension HTTPRequest {

    /// Ordered list of header keys that will be included in the signature.
    static let headersToSign: [HTTPClient.RequestHeader] = [
        .sandbox
    ]

}

// MARK: - Private

private let postParameterHashingAlgorithmName = "sha256"
private let fieldSeparator = Data(bytes: [0x00], count: 1)
