//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequestBody+Signing.swift
//
//  Created by Nacho Soto on 7/6/23.

import CryptoKit
import Foundation

extension HTTPRequestBody {

    var postParameterHeader: String? {
        guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) else {
            // Signature verification is not available.
            return nil
        }

        let keys = self.keysToSign
        guard !keys.isEmpty else {
            return nil
        }

        let pieces = [
            keys.joined(separator: ","),
            postParameterHashingAlgorithmName,
            self.postParameterHash
        ]

        return pieces.joined(separator: ":")
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    var postParameterHash: String {
        var sha256 = SHA256()

        let values = self.contentForSignature.map(\.value)

        for (index, value) in values.enumerated() {
            if index > 0 {
                sha256.update(data: fieldSeparator)
            }

            sha256.update(data: value.asData)
        }

        return sha256.toString()
    }

}

private extension HTTPRequestBody {

    /// - Returns: an ordered list of keys that will be included in the signature.
    var keysToSign: [String] {
        return self.contentForSignature.map(\.key)
    }

}

private let postParameterHashingAlgorithmName = "sha256"
private let fieldSeparator = Data(bytes: [0x00], count: 1)
