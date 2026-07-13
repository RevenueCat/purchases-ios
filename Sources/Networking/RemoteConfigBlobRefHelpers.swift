//
//  RemoteConfigBlobRefHelpers.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import CryptoKit
import Foundation

enum RemoteConfigBlobRefHelpers {

    static func isValid(_ ref: String) -> Bool {
        return ref.range(of: Self.validRefPattern, options: .regularExpression) != nil
    }

    static func ref(for bytes: UnsafeRawBufferPointer) -> String {
        var hash = SHA256()
        hash.update(bufferPointer: bytes)

        return Self.base64URLString(from: Array(hash.finalize().prefix(Self.checksumSize)))
    }

    static func isValidPayload(
        _ bytes: UnsafeRawBufferPointer,
        expectedRef ref: String
    ) -> Bool {
        return self.isValid(ref) && self.ref(for: bytes) == ref
    }

}

private extension RemoteConfigBlobRefHelpers {

    static let checksumSize = 24
    static let validRefPattern = #"^[A-Za-z0-9_-]{32}$"#

    static func base64URLString(from bytes: [UInt8]) -> String {
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}
