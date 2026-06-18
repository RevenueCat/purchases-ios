//
//  RCContainer+Element.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

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

        /// The payload size in bytes, excluding the element header and any alignment padding.
        let size: Int

        /// The element header's reserved field, currently unused and retained for future metadata.
        let reserved: UInt32

        private let storage: Data
        private let checksumRange: Range<Data.Index>
        private let payloadRange: Range<Data.Index>

        init(
            storage: Data,
            checksumRange: Range<Data.Index>,
            payloadRange: Range<Data.Index>,
            checksum: String,
            reserved: UInt32
        ) {
            self.storage = storage
            self.checksumRange = checksumRange
            self.payloadRange = payloadRange
            self.checksum = checksum
            self.reserved = reserved
            self.size = storage.distance(from: payloadRange.lowerBound, to: payloadRange.upperBound)
        }

        // Keep byte access closure-based so callers do not accidentally materialize element payloads
        // as separate `Data` values. A convenience payload `Data` property would be easy to misuse and
        // would silently copy bytes out of the retained container storage.

        /// Provides read-only access to the payload bytes for the duration of `body`.
        func withPayloadBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
            return try self.withBytes(in: self.payloadRange, body)
        }

        /// Provides read-only access to the raw 24-byte checksum for the duration of `body`.
        func withChecksumBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
            return try self.withBytes(in: self.checksumRange, body)
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
