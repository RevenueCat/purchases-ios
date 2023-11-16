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

        return HTTPRequest.signatureHashHeader(keys: keys, hash: self.postParameterHash)
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    private var postParameterHash: String {
        return HTTPRequest.signingParameterHash(self.contentForSignature.map(\.value))
    }

}

private extension HTTPRequestBody {

    /// - Returns: an ordered list of keys that will be included in the signature.
    var keysToSign: [String] {
        return self.contentForSignature.map(\.key)
    }

}
