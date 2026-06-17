//
//  RCContainerTests.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RCContainerTests: TestCase {

    func testParsesConfigAndContentElements() throws {
        let config = #"{"manifest":{}}"#.asData
        let productMapping = #"{"products":[]}"#.asData
        let paywall = #"{"paywall":"default"}"#.asData

        let container = try RCContainer(data: Self.container(config: config, contentElements: [
            productMapping,
            paywall
        ]))

        expect(Self.data(from: container.config)) == config
        expect(container.flags) == 0
        expect(container.config.size) == config.count
        expect(container.contentElements).to(haveCount(2))
        expect(Self.data(from: try XCTUnwrap(container.contentElements[Self.blobRef(for: productMapping)])))
        == productMapping
        expect(Self.data(from: try XCTUnwrap(container.contentElements[Self.blobRef(for: paywall)])))
        == paywall
    }

    func testUsesTwentyFourByteChecksumsAndThirtyTwoCharacterBase64URLReferences() throws {
        let config = "config".asData
        let content = "content".asData

        let container = try RCContainer(data: Self.container(config: config, contentElements: [content]))
        let ref = Self.blobRef(for: content)
        let element = try XCTUnwrap(container.contentElements[ref])

        expect(ref).to(haveCount(32))
        expect(ref).toNot(contain("="))
        expect(ref.range(of: #"^[A-Za-z0-9_-]{32}$"#, options: .regularExpression)).toNot(beNil())
        expect(element.checksum) == ref
        expect(element.withChecksumBytes { $0.count }) == 24
    }

    func testDuplicateContentElementsCollapseToOneLookupEntry() throws {
        let content = "same payload".asData

        let container = try RCContainer(data: Self.container(config: "config".asData, contentElements: [
            content,
            content
        ]))

        expect(container.contentElements).to(haveCount(1))
        expect(Self.data(from: try XCTUnwrap(container.contentElements[Self.blobRef(for: content)]))) == content
    }

    func testParsesLittleEndianElementSizes() throws {
        let config = Data(repeating: 0xab, count: 257)

        let container = try RCContainer(data: Self.container(config: config))

        expect(container.config.size) == 257
        expect(Self.data(from: container.config)) == config
    }

    func testParsesNonZeroFlags() throws {
        let container = try RCContainer(data: Self.container(config: "config".asData, flags: 0x07))

        expect(container.flags) == 0x07
        expect(Self.data(from: container.config)) == "config".asData
    }

    func testAcceptsOmittedFinalPadding() throws {
        let config = "abc".asData

        let container = try RCContainer(data: Self.container(
            config: config,
            omitFinalPadding: true
        ))

        expect(Self.data(from: container.config)) == config
    }

    func testAcceptsPartiallyOmittedFinalPadding() throws {
        var data = Self.container(config: "abc".asData)
        data.removeLast(3)

        let container = try RCContainer(data: data)

        expect(Self.data(from: container.config)) == "abc".asData
    }

    func testParsesDataSliceWithNonZeroStartIndex() throws {
        let prefix = Data([0, 1, 2, 3, 4])
        let containerData = Self.container(config: "config".asData, contentElements: ["blob".asData])
        let prefixedData = prefix + containerData
        let slicedData = prefixedData[prefix.count..<prefixedData.endIndex]

        let container = try RCContainer(data: slicedData)

        expect(Self.data(from: container.config)) == "config".asData
        expect(Self.data(from: try XCTUnwrap(container.contentElements[Self.blobRef(for: "blob".asData)])))
        == "blob".asData
    }

    func testRejectsInvalidHeaderFields() {
        var invalidMagic = Self.container(config: "config".asData)
        invalidMagic[invalidMagic.startIndex] = UInt8(ascii: "X")
        Self.expectParsing(invalidMagic, throws: .invalidMagic)

        var unsupportedVersion = Self.container(config: "config".asData)
        unsupportedVersion[unsupportedVersion.index(unsupportedVersion.startIndex, offsetBy: 2)] = 2
        Self.expectParsing(unsupportedVersion, throws: .unsupportedVersion(2))

        var nonZeroReserved = Self.container(config: "config".asData)
        nonZeroReserved[nonZeroReserved.index(nonZeroReserved.startIndex, offsetBy: 4)] = 1
        Self.expectParsing(nonZeroReserved, throws: .nonZeroHeaderReservedBytes)
    }

    func testRejectsTruncatedContainers() {
        Self.expectParsing(Data([UInt8(ascii: "R")]), throws: .truncatedHeader)
        Self.expectParsing(Self.header(), throws: .missingConfigElement)
        Self.expectParsing(Self.header() + Data([0]), throws: .truncatedElementHeader(index: 0))

        var truncatedElement = Self.header()
        truncatedElement.append(contentsOf: Self.checksum(for: "abcdefgh".asData))
        truncatedElement.appendLittleEndianUInt32(8)
        truncatedElement.appendLittleEndianUInt32(0)
        truncatedElement.append("abcdefg".asData)
        Self.expectParsing(truncatedElement, throws: .truncatedElement(index: 0))
    }

    func testRejectsNonZeroElementReservedField() {
        var data = Self.container(config: "config".asData)
        let reservedOffset = 8 + 24 + 4
        data[data.index(data.startIndex, offsetBy: reservedOffset)] = 1

        Self.expectParsing(data, throws: .nonZeroElementReserved(index: 0))
    }

    func testRejectsNonZeroPadding() {
        var data = Self.container(config: "abc".asData)
        let lastIndex = data.index(before: data.endIndex)
        data[lastIndex] = 1

        Self.expectParsing(data, throws: .nonZeroPadding(index: 0))
    }

    func testRejectsChecksumMismatch() {
        var data = Self.container(config: "config".asData)
        let payloadOffset = 8 + 24 + 4 + 4
        data[data.index(data.startIndex, offsetBy: payloadOffset)] = UInt8(ascii: "x")

        do {
            _ = try RCContainer(data: data)
            fail("Expected checksum mismatch")
        } catch let error as RCContainer.Parser.FormatError {
            guard case let .checksumMismatch(index, expected, actual) = error else {
                fail("Expected checksum mismatch, got \(error)")
                return
            }

            expect(index) == 0
            expect(expected).to(haveCount(32))
            expect(actual).to(haveCount(32))
            expect(expected) != actual
        } catch {
            fail("Expected RCContainer.Parser.FormatError, got \(error)")
        }
    }

    func testExposesPayloadThroughBorrowedByteClosure() throws {
        let payload = "borrowed bytes".asData
        let container = try RCContainer(data: Self.container(config: payload))

        let size = container.config.withPayloadBytes { bytes in
            return bytes.count
        }
        let bytes = container.config.withPayloadBytes { bytes in
            return Array(bytes)
        }

        expect(size) == payload.count
        expect(bytes) == Array(payload)
    }

}

// MARK: - Helpers

private extension RCContainerTests {

    static func expectParsing(
        _ data: Data,
        throws expectedError: RCContainer.Parser.FormatError,
        file: FileString = #file,
        line: UInt = #line
    ) {
        do {
            _ = try RCContainer(data: data)
            fail("Expected \(expectedError)", file: file, line: line)
        } catch let error as RCContainer.Parser.FormatError {
            expect(file: file, line: line, error) == expectedError
        } catch {
            fail("Expected RCContainer.Parser.FormatError, got \(error)", file: file, line: line)
        }
    }

    static func container(
        config: Data,
        contentElements: [Data] = [],
        flags: UInt8 = 0,
        omitFinalPadding: Bool = false
    ) -> Data {
        var data = Self.header(flags: flags)
        let elements = [config] + contentElements

        for (index, element) in elements.enumerated() {
            let isFinalElement = index == elements.count - 1
            data.appendElement(element, omitPadding: omitFinalPadding && isFinalElement)
        }

        return data
    }

    static func header(flags: UInt8 = 0) -> Data {
        return Data([UInt8(ascii: "R"), UInt8(ascii: "C"), 1, flags, 0, 0, 0, 0])
    }

    static func data(from element: RCContainer.Element) -> Data {
        return element.withPayloadBytes { Data($0) }
    }

    static func blobRef(for data: Data) -> String {
        return Data(Self.checksum(for: data))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func checksum(for data: Data) -> [UInt8] {
        return Array(data.sha256.prefix(24))
    }

}

private extension Data {

    mutating func appendElement(_ payload: Data, omitPadding: Bool = false) {
        self.append(contentsOf: RCContainerTests.checksum(for: payload))
        self.appendLittleEndianUInt32(UInt32(payload.count))
        self.appendLittleEndianUInt32(0)
        self.append(payload)

        guard !omitPadding else {
            return
        }

        self.append(Data(repeating: 0, count: (8 - payload.count % 8) % 8))
    }

    mutating func appendLittleEndianUInt32(_ value: UInt32) {
        self.append(UInt8(value & 0xff))
        self.append(UInt8((value >> 8) & 0xff))
        self.append(UInt8((value >> 16) & 0xff))
        self.append(UInt8((value >> 24) & 0xff))
    }

}
