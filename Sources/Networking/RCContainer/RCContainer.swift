//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCContainer.swift
//
//  Created on RC Container Format v1 PoC.

import Foundation

/// A parsed RC Container Format v1 payload, providing zero-copy access to its fields.
///
/// Layout:
/// ```
/// Header:  magic byte[2]="RC" | version u8 | flags u8 | config_size u32 | config[config_size] | pad→8
/// Element: checksum byte[32]  | element_size u32 | element[element_size] | pad→8   (repeat until EOF)
/// ```
/// All `u32` fields are big-endian (network order). The number of elements is not stored;
/// elements are read until the backing buffer is exhausted.
///
/// ``config`` and each ``RCElement`` expose `Data` slices that share the backing buffer's
/// storage, so parsing does not copy field bytes.
struct RCContainer {

    /// Format version from the header (always ``Constants/supportedVersion`` for a successful parse).
    let version: Int
    /// Reserved header flags (compression/encryption/etc.); currently unused.
    let flags: Int
    /// A zero-copy slice over the config JSON bytes.
    let config: Data
    /// The container's elements, in order.
    let elements: [RCElement]

    private init(version: Int, flags: Int, config: Data, elements: [RCElement]) {
        self.version = version
        self.flags = flags
        self.config = config
        self.elements = elements
    }

    private enum Constants {
        static let magicR: UInt8 = 0x52 // ASCII 'R'
        static let magicC: UInt8 = 0x43 // ASCII 'C'
        static let supportedVersion = 1
        static let headerFixedSize = 8 // magic(2) + version(1) + flags(1) + config_size(4)
        static let alignment = 8
        static let checksumSize = 32
        static let uint32Size = 4
        static let elementHeaderSize = checksumSize + uint32Size
    }

    /// Parses `data` as an RC Container Format v1 payload.
    ///
    /// The returned ``config`` and element slices reference `data`'s storage directly (no copy).
    ///
    /// - Throws: ``RCContainerFormatError`` if the bytes are not a valid RC Container Format v1 payload.
    static func parse(_ data: Data) throws -> RCContainer {
        var reader = Reader(data)
        try reader.require(Constants.headerFixedSize) {
            "Buffer too small for header: need at least \(Constants.headerFixedSize) bytes, "
                + "got \(reader.remaining)."
        }

        let (version, flags) = try reader.readAndValidateHeaderMeta()
        let configSize = reader.readUInt32()
        let config = try reader.sliceBytes(configSize, field: "config")
        reader.alignTo(Constants.alignment)

        var elements: [RCElement] = []
        while reader.hasRemaining {
            try reader.require(Constants.elementHeaderSize) {
                "Truncated element header: need \(Constants.elementHeaderSize) bytes, "
                    + "got \(reader.remaining)."
            }
            let checksum = try reader.sliceBytes(UInt32(Constants.checksumSize), field: "checksum")
            let elementSize = reader.readUInt32()
            let elementData = try reader.sliceBytes(elementSize, field: "element")
            reader.alignTo(Constants.alignment)
            elements.append(RCElement(checksum: checksum, data: elementData))
        }

        return RCContainer(version: version, flags: flags, config: config, elements: elements)
    }

    /// A cursor over a `Data` value, tracking a 0-based position from the start of the payload.
    private struct Reader {

        private let data: Data
        private let base: Data.Index
        private let count: Int
        private var pos: Int = 0

        init(_ data: Data) {
            self.data = data
            self.base = data.startIndex
            self.count = data.count
        }

        var remaining: Int { self.count - self.pos }
        var hasRemaining: Bool { self.pos < self.count }

        /// Throws ``RCContainerFormatError`` with `message` if fewer than `needed` bytes remain.
        func require(_ needed: Int, _ message: () -> String) throws {
            if self.remaining < needed {
                throw RCContainerFormatError(message())
            }
        }

        private mutating func readByte() -> UInt8 {
            let byte = self.data[self.base + self.pos]
            self.pos += 1
            return byte
        }

        /// Reads a big-endian unsigned 32-bit integer. Assumes 4 bytes remain (callers `require` first).
        mutating func readUInt32() -> UInt32 {
            let byte0 = UInt32(self.data[self.base + self.pos])
            let byte1 = UInt32(self.data[self.base + self.pos + 1])
            let byte2 = UInt32(self.data[self.base + self.pos + 2])
            let byte3 = UInt32(self.data[self.base + self.pos + 3])
            self.pos += Constants.uint32Size
            return (byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3
        }

        /// Returns a zero-copy slice of `size` bytes at the current position, advancing past them.
        mutating func sliceBytes(_ size: UInt32, field: String) throws -> Data {
            // Compare as UInt32 so an adversarial size near UInt32.max can't overflow `Int`.
            guard size <= UInt32(clamping: self.remaining) else {
                throw RCContainerFormatError(
                    "Declared \(field) size \(size) exceeds remaining \(self.remaining) bytes."
                )
            }
            let length = Int(size) // safe: size <= remaining <= count
            let start = self.base + self.pos
            let view = self.data[start..<(start + length)]
            self.pos += length
            return view
        }

        /// Advances the position to the next multiple of `alignment` (no-op if already aligned).
        mutating func alignTo(_ alignment: Int) {
            let remainder = self.pos % alignment
            guard remainder != 0 else { return }
            // Trailing alignment padding may run past the end of the buffer; clamp to the end.
            self.pos = min(self.pos + (alignment - remainder), self.count)
        }

        /// Reads and validates magic + version, returning the `(version, flags)` pair.
        mutating func readAndValidateHeaderMeta() throws -> (version: Int, flags: Int) {
            guard self.readByte() == Constants.magicR, self.readByte() == Constants.magicC else {
                throw RCContainerFormatError("Invalid magic bytes. Expected ASCII \"RC\".")
            }
            let version = Int(self.readByte())
            guard version == Constants.supportedVersion else {
                throw RCContainerFormatError(
                    "Unsupported version \(version). Expected \(Constants.supportedVersion)."
                )
            }
            let flags = Int(self.readByte())
            return (version, flags)
        }

    }

}
