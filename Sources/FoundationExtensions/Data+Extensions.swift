//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Data+Extensions.swift
//  Purchases
//
//  Created by Josh Holtz on 6/28/21.
//

import CommonCrypto
import CryptoKit
import Foundation

extension NSData {

    func asString() -> String {
        // 2 characters per byte
        let deviceTokenString = NSMutableString(capacity: self.length * 2)

        self.enumerateBytes { bytes, byteRange, _ in
            for index in stride(from: 0, to: byteRange.length, by: 1) {
                let byte = bytes.load(fromByteOffset: index, as: UInt8.self)
                deviceTokenString.appendFormat("%02x", byte)
            }
        }

        return deviceTokenString as String
    }

}

extension Data {

    var asString: String {
        return (self as NSData).asString()
    }

    /// - Returns: `UUID` from the first 16 bytes of the underlying data.
    var uuid: UUID? {
        /// This implementation is equivalent to `return NSUUID(uuidBytes: [UInt8](self)) as UUID`
        /// but ensures that the `Data` isn't unnecessarily copied in memory.
        return self.withUnsafeBytes {
            guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
                return nil
            }

            return NSUUID(uuidBytes: baseAddress) as UUID
        }
    }

    /// - Returns: a string representing a fetch token.
    var asFetchToken: String {
        return self.base64EncodedString()
    }

    /// - Returns: a hash representation of the underlying bytes.
    var hashString: String {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            var sha256 = SHA256()
            sha256.update(data: self)

            return Self.hexString(sha256.finalize().makeIterator())
        } else {
            let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
                var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
                return hash
            }

            return Self.hexString(hash.makeIterator())
        }
    }

    private static func hexString(_ iterator: Array<UInt8>.Iterator) -> String {
        return iterator
            .lazy
            .map { String(format: "%02x", $0) }
            .joined()
    }

}

extension Data {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    static func randomNonce() -> Data {
        return Data(ChaChaPoly.Nonce())
    }

    static let nonceLength = 12

}
