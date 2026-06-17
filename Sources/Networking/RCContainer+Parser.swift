//
//  RCContainer+Parser.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import CryptoKit
import Foundation

extension RCContainer {

    struct Parser {

        // swiftlint:disable nesting
        enum FormatError: Error, Equatable {

            case truncatedHeader
            case invalidMagic
            case unsupportedVersion(UInt8)
            case nonZeroHeaderReservedBytes
            case truncatedElementHeader(index: Int)
            case truncatedElement(index: Int)
            case nonZeroElementReserved(index: Int)
            case nonZeroPadding(index: Int)
            case checksumMismatch(index: Int, expected: String, actual: String)
            case missingConfigElement

        }
        // swiftlint:enable nesting

        private static let headerSize = 8
        private static let magic = (UInt8(ascii: "R"), UInt8(ascii: "C"))
        private static let version: UInt8 = 1
        private static let alignment = 8
        private static let checksumSize = 24
        private static let elementHeaderSize = checksumSize + 4 + 4

        private let data: Data
        private var offset = 0

        init(data: Data) {
            self.data = data
        }

        mutating func parse() throws -> (flags: UInt8, elements: [Element]) {
            let flags = try self.parseHeader()

            var elements: [Element] = []
            while self.offset < self.data.count {
                elements.append(try self.parseElement(index: elements.count))
            }

            return (flags: flags, elements: elements)
        }

        private mutating func parseHeader() throws -> UInt8 {
            guard self.hasBytes(Self.headerSize) else {
                throw FormatError.truncatedHeader
            }

            guard self.byte(at: 0) == Self.magic.0,
                  self.byte(at: 1) == Self.magic.1 else {
                throw FormatError.invalidMagic
            }

            let version = self.byte(at: 2)
            guard version == Self.version else {
                throw FormatError.unsupportedVersion(version)
            }

            guard self.bytesAreZero(in: 4..<Self.headerSize) else {
                throw FormatError.nonZeroHeaderReservedBytes
            }

            let flags = self.byte(at: 3)
            self.offset = Self.headerSize
            return flags
        }

        private mutating func parseElement(index: Int) throws -> Element {
            guard self.hasBytes(Self.elementHeaderSize) else {
                throw FormatError.truncatedElementHeader(index: index)
            }

            let checksumStartOffset = self.offset
            let checksumEndOffset = checksumStartOffset + Self.checksumSize
            let checksumRange = self.dataRange(offset: checksumStartOffset, count: Self.checksumSize)
            let checksum = self.base64URLString(in: checksumStartOffset..<checksumEndOffset)

            self.offset = checksumEndOffset
            let elementSize = Int(self.littleEndianUInt32(at: self.offset))
            self.offset += 4

            let reserved = self.littleEndianUInt32(at: self.offset)
            guard reserved == 0 else {
                throw FormatError.nonZeroElementReserved(index: index)
            }
            self.offset += 4

            guard self.hasBytes(elementSize) else {
                throw FormatError.truncatedElement(index: index)
            }

            let payloadStartOffset = self.offset
            let payloadRange = self.dataRange(offset: payloadStartOffset, count: elementSize)
            let actualChecksum = self.checksumString(in: payloadStartOffset..<payloadStartOffset + elementSize)
            guard checksum == actualChecksum else {
                throw FormatError.checksumMismatch(
                    index: index,
                    expected: checksum,
                    actual: actualChecksum
                )
            }

            self.offset += elementSize
            try self.consumePadding(forElementSize: elementSize, elementIndex: index)

            return Element(
                storage: self.data,
                checksumRange: checksumRange,
                payloadRange: payloadRange,
                checksum: checksum
            )
        }

        private mutating func consumePadding(forElementSize elementSize: Int, elementIndex: Int) throws {
            let paddingSize = (Self.alignment - elementSize % Self.alignment) % Self.alignment
            guard paddingSize > 0 else {
                return
            }

            let remainingBytes = self.data.count - self.offset
            let availablePaddingBytes = min(paddingSize, remainingBytes)
            guard self.bytesAreZero(in: self.offset..<self.offset + availablePaddingBytes) else {
                throw FormatError.nonZeroPadding(index: elementIndex)
            }

            if remainingBytes < paddingSize {
                self.offset = self.data.count
            } else {
                self.offset += paddingSize
            }
        }

        private func checksumString(in range: Range<Int>) -> String {
            var hash = SHA256()
            self.withUnsafeBytes(in: range) { bytes in
                hash.update(bufferPointer: bytes)
            }

            return Self.base64URLString(from: Array(hash.finalize().prefix(Self.checksumSize)))
        }

        private func base64URLString(in range: Range<Int>) -> String {
            var bytes: [UInt8] = []
            bytes.reserveCapacity(range.count)
            for offset in range {
                bytes.append(self.byte(at: offset))
            }

            return Self.base64URLString(from: bytes)
        }

        private static func base64URLString(from bytes: [UInt8]) -> String {
            let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".utf8)
            var encoded: [UInt8] = []
            encoded.reserveCapacity((bytes.count / 3) * 4)

            var offset = 0
            while offset + 2 < bytes.count {
                let value = (UInt32(bytes[offset]) << 16)
                | (UInt32(bytes[offset + 1]) << 8)
                | UInt32(bytes[offset + 2])

                encoded.append(alphabet[Int((value >> 18) & 0x3f)])
                encoded.append(alphabet[Int((value >> 12) & 0x3f)])
                encoded.append(alphabet[Int((value >> 6) & 0x3f)])
                encoded.append(alphabet[Int(value & 0x3f)])

                offset += 3
            }

            return String(bytes: encoded, encoding: .utf8) ?? ""
        }

        private func withUnsafeBytes<T>(in range: Range<Int>, _ body: (UnsafeRawBufferPointer) -> T) -> T {
            return self.data.withUnsafeBytes { bytes in
                return body(UnsafeRawBufferPointer(rebasing: bytes[range]))
            }
        }

        private func littleEndianUInt32(at offset: Int) -> UInt32 {
            return UInt32(self.byte(at: offset))
            | UInt32(self.byte(at: offset + 1)) << 8
            | UInt32(self.byte(at: offset + 2)) << 16
            | UInt32(self.byte(at: offset + 3)) << 24
        }

        private func byte(at offset: Int) -> UInt8 {
            return self.data[self.data.index(self.data.startIndex, offsetBy: offset)]
        }

        private func dataRange(offset: Int, count: Int) -> Range<Data.Index> {
            let startIndex = self.data.index(self.data.startIndex, offsetBy: offset)
            let endIndex = self.data.index(startIndex, offsetBy: count)
            return startIndex..<endIndex
        }

        private func hasBytes(_ count: Int) -> Bool {
            return count >= 0 && self.offset <= self.data.count - count
        }

        private func bytesAreZero(in range: Range<Int>) -> Bool {
            for offset in range where self.byte(at: offset) != 0 {
                return false
            }

            return true
        }

    }

}
