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

extension Data {

    var asString: String {
        return Self.hexString(
            self
                .lazy
                .map { $0 } // Extract byte
                .makeIterator()
        )
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

    /// - Returns: a hash representation of the underlying bytes, using SHA256.
    var hashString: String {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            var sha256 = SHA256()
            return self.hashString(with: &sha256)
        } else {
            return self.hashString(CC_SHA256, length: CC_SHA256_DIGEST_LENGTH)
        }
    }

    /// - Returns: the SHA1 hash of the underlying bytes.
    var sha1: Data {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            var sha1 = Insecure.SHA1()
            return self.hash(with: &sha1)
        } else {
            return Data(self.hash(CC_SHA1, length: CC_SHA1_DIGEST_LENGTH))
        }
    }

    fileprivate static func hexString(_ iterator: Array<UInt8>.Iterator) -> String {
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

// MARK: - Hashing

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension HashFunction {

    func toString() -> String {
        return Data.hexString(self.finalize().makeIterator())
    }

}

private extension Data {

    typealias HashingFunction = (
        _ data: UnsafeRawPointer?,
        _ len: CC_LONG,
        _ md: UnsafeMutablePointer<UInt8>?
    ) -> UnsafeMutablePointer<UInt8>?

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func hashString<T: HashFunction>(with digest: inout T) -> String {
        digest.update(data: self)
        return digest.toString()
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func hash<T: HashFunction>(with digest: inout T) -> Data {
        digest.update(data: self)

        return Data(digest.finalize())
    }

    func hash(_ hashingFunction: HashingFunction, length: Int32) -> [UInt8] {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(length))
            _ = hashingFunction(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
    }

    func hashString(_ hashingFunction: HashingFunction, length: Int32) -> String {
        return Self.hexString(
            self.hash(hashingFunction, length: length)
                .makeIterator()
        )
    }

}
