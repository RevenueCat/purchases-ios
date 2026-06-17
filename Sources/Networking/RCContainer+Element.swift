//
//  RCContainer+Element.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

extension RCContainer {

    struct Element {

        let checksum: String
        let size: Int

        private let storage: Data
        private let checksumRange: Range<Data.Index>
        private let payloadRange: Range<Data.Index>

        init(
            storage: Data,
            checksumRange: Range<Data.Index>,
            payloadRange: Range<Data.Index>,
            checksum: String
        ) {
            self.storage = storage
            self.checksumRange = checksumRange
            self.payloadRange = payloadRange
            self.checksum = checksum
            self.size = storage.distance(from: payloadRange.lowerBound, to: payloadRange.upperBound)
        }

        func withPayloadBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
            return try self.withBytes(in: self.payloadRange, body)
        }

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
