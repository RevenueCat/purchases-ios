//
//  RCContainer+Element.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Compression
import CryptoKit
import Foundation

extension RCContainer {

    /// A single RC Container element backed by the original container bytes.
    ///
    /// `Element` stores byte ranges into the retained container `Data`. Use `withPayloadBytes` and
    /// `withChecksumBytes` to inspect bytes without materializing per-element `Data` copies. The
    /// backing data is private on purpose so callers cannot accidentally introduce copying behavior.
    struct Element {

        /// The element checksum encoded as a 32-character URL-safe base64 string with no padding.
        let checksum: String

        /// The wire payload size in bytes, excluding the element header and any alignment padding.
        let size: Int

        /// The per-element payload encoding used on the wire.
        let encoding: ContentEncoding

        private let storage: Data
        private let checksumRange: Range<Data.Index>
        private let payloadRange: Range<Data.Index>

        init(
            storage: Data,
            checksumRange: Range<Data.Index>,
            payloadRange: Range<Data.Index>,
            checksum: String,
            encoding: ContentEncoding
        ) {
            self.storage = storage
            self.checksumRange = checksumRange
            self.payloadRange = payloadRange
            self.checksum = checksum
            self.encoding = encoding
            self.size = storage.distance(from: payloadRange.lowerBound, to: payloadRange.upperBound)
        }

        // Keep byte access closure-based so callers do not accidentally materialize element payloads
        // as separate `Data` values. A convenience payload `Data` property would be easy to misuse and
        // would silently copy bytes out of the retained container storage.

        /// Provides read-only access to the payload bytes for the duration of `body`.
        func withPayloadBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
            return try self.withBytes(in: self.payloadRange, body)
        }

        /// Provides read-only access to the decoded payload bytes for the duration of `body`.
        ///
        /// Uncompressed elements borrow from the original container storage. Compressed elements are
        /// decoded into temporary storage because decompression necessarily materializes new bytes.
        func withDecodedPayloadBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) throws -> T {
            return try self.withPayloadBytes { bytes in
                try self.encoding.withDecodedBytes(from: bytes, body)
            }
        }

        /// Provides read-only access to the raw 24-byte checksum for the duration of `body`.
        func withChecksumBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
            return try self.withBytes(in: self.checksumRange, body)
        }

        /// Returns whether the decoded payload bytes match the element's stored checksum.
        func isChecksumValid() -> Bool {
            return (try? self.checksum == self.payloadChecksum()) == true
        }

        /// Returns whether already-decoded payload bytes match the element's stored checksum.
        func isChecksumValid(decodedPayloadBytes bytes: UnsafeRawBufferPointer) -> Bool {
            return self.checksum == self.payloadChecksum(decodedPayloadBytes: bytes)
        }

        /// Validates the decoded payload bytes against the element's stored checksum.
        func validateChecksum() throws {
            let actual = try self.payloadChecksum()
            guard self.checksum == actual else {
                throw Parser.FormatError.checksumMismatch(
                    expected: self.checksum,
                    actual: actual
                )
            }
        }

        /// Validates already-decoded payload bytes against the element's stored checksum.
        func validateChecksum(decodedPayloadBytes bytes: UnsafeRawBufferPointer) throws {
            let actual = self.payloadChecksum(decodedPayloadBytes: bytes)
            guard self.checksum == actual else {
                throw Parser.FormatError.checksumMismatch(
                    expected: self.checksum,
                    actual: actual
                )
            }
        }

        private func payloadChecksum() throws -> String {
            return try self.withDecodedPayloadBytes { bytes in
                self.payloadChecksum(decodedPayloadBytes: bytes)
            }
        }

        private func payloadChecksum(decodedPayloadBytes bytes: UnsafeRawBufferPointer) -> String {
            var hash = SHA256()
            hash.update(bufferPointer: bytes)

            return Self.base64URLString(from: Array(hash.finalize().prefix(Self.checksumSize)))
        }

        private func withBytes<T>(
            in range: Range<Data.Index>,
            _ body: (UnsafeRawBufferPointer) throws -> T
        ) rethrows -> T {
            let lowerBound = self.storage.distance(from: self.storage.startIndex, to: range.lowerBound)
            let upperBound = self.storage.distance(from: self.storage.startIndex, to: range.upperBound)

            return try self.storage.withUnsafeBytes { bytes in
                let range = lowerBound..<upperBound
                return try body(UnsafeRawBufferPointer(rebasing: bytes[range]))
            }
        }

    }

}

extension RCContainer.Element {

    /// Per-element content encoding stored in the RC Container element header.
    ///
    /// Encoding ids match the backend wire format:
    /// `0 = none`, `1 = gzip`, `2 = brotli`, `3 = zstd`.
    /// `zstd` is recognized but not decoded by iOS yet. Unknown ids are preserved as
    /// `unsupported` so structural parsing can succeed while decoded access fails clearly.
    enum ContentEncoding: Equatable {

        case none
        case gzip
        case brotli
        case zstd
        case unsupported(UInt8)

        init(rawValue: UInt8) {
            switch rawValue {
            case 0: self = .none
            case 1: self = .gzip
            case 2: self = .brotli
            case 3: self = .zstd
            default: self = .unsupported(rawValue)
            }
        }

        var rawValue: UInt8 {
            switch self {
            case .none: return 0
            case .gzip: return 1
            case .brotli: return 2
            case .zstd: return 3
            case let .unsupported(rawValue): return rawValue
            }
        }

        var elementEncodingHeaderValue: String? {
            switch self {
            case .none:
                return nil
            case .gzip:
                return "gzip"
            case .brotli:
                return "br"
            case .zstd:
                return "zstd"
            case .unsupported:
                return nil
            }
        }

        var isSupported: Bool {
            switch self {
            case .none, .gzip:
                return true
            case .brotli:
                // Brotli decoding relies on `Compression.Algorithm.brotli`, whose runtime symbol only
                // exists on iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+. Probe it via the C constant
                // rather than the case (see `brotliAlgorithm`) so we neither strong-link a missing
                // symbol nor advertise brotli support on runtimes that lack it.
                return Self.brotliAlgorithm != nil
            case .zstd, .unsupported:
                return false
            }
        }

        static var supportedEncodingsInPriorityOrder: [Self] {
            return Self.encodingPreference.filter(\.isSupported)
        }

        static var supportedRequestElementEncodingsInPriorityOrder: [Self] {
            return Self.supportedEncodingsInPriorityOrder.filter { $0.elementEncodingHeaderValue != nil }
        }

        static var requestElementEncodingHeaderValue: String {
            return Self.supportedRequestElementEncodingsInPriorityOrder
                .compactMap(\.elementEncodingHeaderValue)
                .joined(separator: ", ")
        }

        private static let encodingPreference: [Self] = [.brotli, .gzip, .none]

    }

}

private extension RCContainer.Element {

    static let checksumSize = 24

    static func base64URLString(from bytes: [UInt8]) -> String {
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}
