//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCContainerTests.swift
//
//  Created on RC Container Format v1 PoC.

import CryptoKit
import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class RCContainerTests: TestCase {

    func testParsesHeaderFieldsAndConfig() throws {
        let config = Data("{\"hello\":\"world\"}".utf8)
        let bytes = Self.buildContainer(version: 1, flags: 0x07, config: config)

        let container = try RCContainer.parse(bytes)

        expect(container.version) == 1
        expect(container.flags) == 0x07
        expect(container.config) == config
        expect(container.elements).to(beEmpty())
    }

    func testParsesSingleElement() throws {
        let element = Data("payload-bytes".utf8)
        let bytes = Self.buildContainer(config: Data("cfg".utf8), elements: [element])

        let container = try RCContainer.parse(bytes)

        expect(container.elements).to(haveCount(1))
        expect(container.elements[0].data) == element
    }

    func testParsesMultipleElementsOfDifferingSizes() throws {
        let elements: [Data] = [
            Data("a".utf8),
            Data("bb".utf8),
            Data((0..<100).map { UInt8($0) }),
            Data()
        ]
        let bytes = Self.buildContainer(elements: elements)

        let container = try RCContainer.parse(bytes)

        expect(container.elements).to(haveCount(elements.count))
        for (index, expected) in elements.enumerated() {
            expect(container.elements[index].data) == expected
        }
    }

    func testSkipsConfigPaddingWhenConfigSizeIsNotMultipleOf8() throws {
        // 3-byte config forces 5 bytes of padding before the first element.
        let element = Data("element".utf8)
        let bytes = Self.buildContainer(config: Data("abc".utf8), elements: [element])

        let container = try RCContainer.parse(bytes)

        expect(container.config) == Data("abc".utf8)
        expect(container.elements[0].data) == element
    }

    func testParsesEmptyConfig() throws {
        let element = Data("x".utf8)
        let bytes = Self.buildContainer(config: Data(), elements: [element])

        let container = try RCContainer.parse(bytes)

        expect(container.config).to(beEmpty())
        expect(container.elements[0].data) == element
    }

    func testReadsBigEndianSizes() throws {
        // 256-byte config encodes as 0x00,0x00,0x01,0x00 big-endian. A little-endian misread would
        // be 0x00010000 (65536) and overflow the buffer, so a successful parse proves big-endian.
        let config = Data((0..<256).map { UInt8($0 & 0xFF) })
        let bytes = Self.buildContainer(config: config)

        let container = try RCContainer.parse(bytes)

        expect(container.config).to(haveCount(256))
        expect(container.config) == config
    }

    func testIsChecksumValidReturnsTrueForCorrectChecksum() throws {
        let element = Data("verify-me".utf8)
        let bytes = Self.buildContainer(elements: [element])

        let container = try RCContainer.parse(bytes)

        expect(container.elements[0].isChecksumValid()) == true
    }

    func testIsChecksumValidReturnsFalseForCorruptedElement() throws {
        let element = Data("verify-me".utf8)
        // Store a checksum that does not match the element bytes.
        let bytes = Self.buildContainer(elements: [element], checksumOverride: { _, _ in Data(count: 32) })

        let container = try RCContainer.parse(bytes)

        expect(container.elements[0].isChecksumValid()) == false
    }

    func testElementDataIsZeroCopyViewOverSource() throws {
        let element = Data("ABCD".utf8)
        // Empty config: element bytes begin at offset 8 (header) + 36 (checksum + size) = 44.
        let bytes = Self.buildContainer(config: Data(), elements: [element])
        let elementOffset = 8 + 32 + 4

        let container = try RCContainer.parse(bytes)
        let data = container.elements[0].data

        expect(data.first) == UInt8(ascii: "A")

        // The slice points into the source buffer's storage — no copy was made during parsing.
        let sourceAddr = bytes.withUnsafeBytes { Int(bitPattern: $0.baseAddress) }
        let sliceAddr = data.withUnsafeBytes { Int(bitPattern: $0.baseAddress) }
        expect(sliceAddr) == sourceAddr + elementOffset
    }

    func testThrowsOnBufferTooSmallForHeader() {
        expect { try RCContainer.parse(Data([0x52, 0x43, 1, 0])) }
            .to(throwError(errorType: RCContainerFormatError.self))
    }

    func testThrowsOnInvalidMagic() {
        var bytes = Self.buildContainer()
        bytes[0] = UInt8(ascii: "X")
        expect { try RCContainer.parse(bytes) }
            .to(throwError(errorType: RCContainerFormatError.self))
    }

    func testThrowsOnUnsupportedVersion() {
        let bytes = Self.buildContainer(version: 2)
        expect { try RCContainer.parse(bytes) }
            .to(throwError(errorType: RCContainerFormatError.self))
    }

    func testThrowsWhenConfigSizeExceedsBuffer() {
        var bytes = Self.buildContainer(config: Data("abc".utf8))
        // Overwrite the high byte of config_size (offset 4, big-endian) with a value far past the end.
        bytes[4] = 0x7F
        expect { try RCContainer.parse(bytes) }
            .to(throwError(errorType: RCContainerFormatError.self))
    }

    func testThrowsOnTruncatedElementHeader() {
        let bytes = Self.buildContainer(config: Data(), elements: [Data("hi".utf8)])
        // Drop trailing bytes so an element is declared but its header is incomplete.
        let truncated = bytes.prefix(8 + 10)
        expect { try RCContainer.parse(Data(truncated)) }
            .to(throwError(errorType: RCContainerFormatError.self))
    }

    func testThrowsWhenElementSizeExceedsBuffer() {
        var bytes = Self.buildContainer(config: Data(), elements: [Data("hi".utf8)])
        // element_size is the 4 bytes after the 32-byte checksum: offset 8 + 32 = 40.
        bytes[40] = 0x7F
        expect { try RCContainer.parse(bytes) }
            .to(throwError(errorType: RCContainerFormatError.self))
    }

    // MARK: - Helpers

    private static func buildContainer(
        version: UInt8 = 1,
        flags: UInt8 = 0,
        config: Data = Data(),
        elements: [Data] = [],
        checksumOverride: ((Int, Data) -> Data)? = nil
    ) -> Data {
        var out = Data()
        out.append(UInt8(ascii: "R"))
        out.append(UInt8(ascii: "C"))
        out.append(version)
        out.append(flags)
        out.appendUInt32BE(config.count)
        out.append(config)
        out.padTo8()

        for (index, element) in elements.enumerated() {
            let checksum = checksumOverride?(index, element) ?? Data(SHA256.hash(data: element))
            out.append(checksum)
            out.appendUInt32BE(element.count)
            out.append(element)
            out.padTo8()
        }
        return out
    }

}

private extension Data {

    mutating func appendUInt32BE(_ value: Int) {
        let value = UInt32(value)
        self.append(UInt8((value >> 24) & 0xFF))
        self.append(UInt8((value >> 16) & 0xFF))
        self.append(UInt8((value >> 8) & 0xFF))
        self.append(UInt8(value & 0xFF))
    }

    mutating func padTo8() {
        while self.count % 8 != 0 {
            self.append(0)
        }
    }

}
