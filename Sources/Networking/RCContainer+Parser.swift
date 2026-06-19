//
//  RCContainer+Parser.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import CryptoKit
import Foundation

extension RCContainer {

    /// Validates and indexes the RC Container binary format.
    ///
    /// The parser walks the container with a byte offset cursor, validates each field before advancing
    /// past it, and records `Data.Index` ranges that point at the retained backing `Data`.
    struct Parser {

        // swiftlint:disable nesting
        /// Typed failures for malformed RC Container bytes.
        enum FormatError: Error, Equatable {

            case truncatedHeader
            case invalidMagic
            case unsupportedVersion(UInt8)
            case truncatedElementHeader(index: Int)
            case truncatedElement(index: Int)
            case nonZeroPadding(index: Int)
            case checksumMismatch(index: Int, expected: String, actual: String)
            case missingConfigElement

        }
        // swiftlint:enable nesting

        private var elementParser: ElementParser

        /// Creates a parser over the provided `Data` without copying it.
        init(data: Data) {
            self.elementParser = .init(data: data)
        }

        /// Parses the full container and returns the header flags plus indexed elements.
        mutating func parse() throws -> (flags: UInt8, elements: [Element]) {
            let flags = try self.elementParser.parseHeader()

            var elements: [Element] = []
            while self.elementParser.hasRemainingBytes {
                elements.append(try self.elementParser.parseElement(index: elements.count))
            }

            return (flags: flags, elements: elements)
        }

    }

    /// Cursor-based parser for the generic RC Container wire format.
    ///
    /// This type intentionally has no remote-config knowledge. It only knows how to validate the
    /// container header and parse individual elements from the current cursor position.
    struct ElementParser {

        private static let magicOffset = 0
        private static let magicSize = 2
        private static let versionOffset = magicOffset + magicSize
        private static let versionSize = 1
        private static let flagsOffset = versionOffset + versionSize
        private static let flagsSize = 1
        private static let headerReservedOffset = flagsOffset + flagsSize
        private static let headerReservedSize = 4
        private static let headerSize = headerReservedOffset + headerReservedSize

        private static let magic = (UInt8(ascii: "R"), UInt8(ascii: "C"))
        private static let version: UInt8 = 1
        private static let alignment = 8
        private static let uint32Size = 4
        private static let checksumSize = 24
        private static let elementSizeFieldSize = uint32Size
        private static let elementReservedFieldSize = uint32Size
        private static let elementHeaderSize = checksumSize + elementSizeFieldSize + elementReservedFieldSize

        private let data: Data
        private var offset = 0

        var hasRemainingBytes: Bool {
            return self.offset < self.data.count
        }

        init(data: Data) {
            self.data = data
        }

        /// Validates the container header and positions the cursor at the first element.
        mutating func moveToFirstElement() throws {
            _ = try self.parseHeader()
        }

        /// Parses the fixed-size container header and positions the cursor at the first element.
        ///
        /// Version 1 preserves the flags byte for future use and skips the reserved bytes so future
        /// server-side additions do not make older SDKs reject the whole container.
        mutating func parseHeader() throws -> UInt8 {
            guard self.hasBytes(Self.headerSize) else {
                throw Parser.FormatError.truncatedHeader
            }

            guard self.byte(at: Self.magicOffset) == Self.magic.0,
                  self.byte(at: Self.magicOffset + 1) == Self.magic.1 else {
                throw Parser.FormatError.invalidMagic
            }

            let version = self.byte(at: Self.versionOffset)
            guard version == Self.version else {
                throw Parser.FormatError.unsupportedVersion(version)
            }

            let flags = self.byte(at: Self.flagsOffset)
            self.offset = Self.headerSize
            return flags
        }

        /// Parses one element and returns an `Element` that points into the original container bytes.
        ///
        /// The stored checksum is read before the cursor moves into the payload. The payload checksum
        /// is then recomputed from the payload range so checksum validation does not depend on mutable
        /// cursor state after parsing continues.
        mutating func parseElement(index: Int) throws -> Element {
            guard self.hasBytes(Self.elementHeaderSize) else {
                throw Parser.FormatError.truncatedElementHeader(index: index)
            }

            let checksumStartOffset = self.offset
            let checksumEndOffset = checksumStartOffset + Self.checksumSize
            let checksumRange = self.dataRange(offset: checksumStartOffset, count: Self.checksumSize)
            let checksum = self.base64URLString(in: checksumStartOffset..<checksumEndOffset)

            self.offset = checksumEndOffset
            let elementSize = Int(self.littleEndianUInt32(at: self.offset))
            self.offset += Self.elementSizeFieldSize

            let reserved = self.littleEndianUInt32(at: self.offset)
            self.offset += Self.elementReservedFieldSize

            guard self.hasBytes(elementSize) else {
                throw Parser.FormatError.truncatedElement(index: index)
            }

            let payloadStartOffset = self.offset
            let payloadRange = self.dataRange(offset: payloadStartOffset, count: elementSize)
            let actualChecksum = self.checksumString(in: payloadStartOffset..<payloadStartOffset + elementSize)
            guard checksum == actualChecksum else {
                throw Parser.FormatError.checksumMismatch(
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
                checksum: checksum,
                reserved: reserved
            )
        }

        /// Consumes zero padding after a payload.
        ///
        /// Padding length is derived only from the element payload size, not from the absolute container
        /// offset. The final element may omit trailing padding bytes entirely, but any padding bytes that
        /// are present still need to be zero.
        private mutating func consumePadding(forElementSize elementSize: Int, elementIndex: Int) throws {
            let paddingSize = (Self.alignment - elementSize % Self.alignment) % Self.alignment
            guard paddingSize > 0 else {
                return
            }

            let remainingBytes = self.data.count - self.offset
            let availablePaddingBytes = min(paddingSize, remainingBytes)
            guard self.bytesAreZero(in: self.offset..<self.offset + availablePaddingBytes) else {
                throw Parser.FormatError.nonZeroPadding(index: elementIndex)
            }

            if remainingBytes < paddingSize {
                self.offset = self.data.count
            } else {
                self.offset += paddingSize
            }
        }

        /// Computes the blob-ref string for a payload range.
        ///
        /// Blob refs are the first 24 bytes of the SHA-256 digest encoded as unpadded base64url,
        /// producing a stable 32-character string that can be used as a content lookup key.
        private func checksumString(in range: Range<Int>) -> String {
            var hash = SHA256()
            self.withUnsafeBytes(in: range) { bytes in
                hash.update(bufferPointer: bytes)
            }

            return Self.base64URLString(from: Array(hash.finalize().prefix(Self.checksumSize)))
        }

        /// Encodes bytes already present in the container as an unpadded base64url string.
        private func base64URLString(in range: Range<Int>) -> String {
            var bytes: [UInt8] = []
            bytes.reserveCapacity(range.count)
            for offset in range {
                bytes.append(self.byte(at: offset))
            }

            return Self.base64URLString(from: bytes)
        }

        /// Encodes bytes as base64url without padding.
        private static func base64URLString(from bytes: [UInt8]) -> String {
            return Data(bytes)
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }

        /// Re-bases an integer byte range into the `Data` storage for temporary zero-copy access.
        private func withUnsafeBytes<T>(in range: Range<Int>, _ body: (UnsafeRawBufferPointer) -> T) -> T {
            return self.data.withUnsafeBytes { bytes in
                return body(UnsafeRawBufferPointer(rebasing: bytes[range]))
            }
        }

        /// Reads the wire-format little-endian `UInt32` used for payload sizes and reserved metadata.
        private func littleEndianUInt32(at offset: Int) -> UInt32 {
            return UInt32(self.byte(at: offset))
            | UInt32(self.byte(at: offset + 1)) << 8
            | UInt32(self.byte(at: offset + 2)) << 16
            | UInt32(self.byte(at: offset + 3)) << 24
        }

        /// Reads a byte at a container-relative offset.
        private func byte(at offset: Int) -> UInt8 {
            return self.data[self.data.index(self.data.startIndex, offsetBy: offset)]
        }

        /// Converts a container-relative offset and count into `Data.Index` bounds.
        ///
        /// `Data` indices are not guaranteed to be zero-based, especially for slices, so stored element
        /// ranges use real `Data.Index` values while parser math stays in container-relative byte offsets.
        private func dataRange(offset: Int, count: Int) -> Range<Data.Index> {
            let startIndex = self.data.index(self.data.startIndex, offsetBy: offset)
            let endIndex = self.data.index(startIndex, offsetBy: count)
            return startIndex..<endIndex
        }

        /// Checks whether the current cursor can read `count` bytes without overflowing the buffer.
        private func hasBytes(_ count: Int) -> Bool {
            return count >= 0 && self.offset <= self.data.count - count
        }

        /// Validates padding ranges.
        private func bytesAreZero(in range: Range<Int>) -> Bool {
            for offset in range where self.byte(at: offset) != 0 {
                return false
            }

            return true
        }

    }

}
