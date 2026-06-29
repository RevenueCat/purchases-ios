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

        let container = try RCContainer(data: RCContainerTestData.container(config: config, contentElements: [
            productMapping,
            paywall
        ]))
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == config
        expect(container.flags) == 0
        expect(try RCContainerTestData.firstElement(in: container).size) == config.count
        expect(contentElementsByChecksum).to(haveCount(2))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: productMapping)])
        )) == productMapping
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: paywall)])
        )) == paywall
    }

    func testParsesEmptyConfigWithContentElement() throws {
        let content = "content".asData

        let container = try RCContainer(data: RCContainerTestData.container(
            config: Data(),
            contentElements: [content]
        ))
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(try RCContainerTestData.firstElement(in: container).size) == 0
        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))).to(beEmpty())
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: content)])
        )) == content
    }

    func testParsesMultipleContentElementsOfDifferingSizesIncludingEmptyElement() throws {
        let contentElements = [
            "a".asData,
            "bb".asData,
            Data(repeating: 0xab, count: 100),
            Data()
        ]

        let container = try RCContainer(data: RCContainerTestData.container(
            config: "config".asData,
            contentElements: contentElements
        ))
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(contentElementsByChecksum).to(haveCount(contentElements.count))
        for contentElement in contentElements {
            expect(RCContainerTestData.data(
                from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: contentElement)])
            )) == contentElement
        }
    }

    func testUsesTwentyFourByteChecksumsAndThirtyTwoCharacterBase64URLReferences() throws {
        let config = "config".asData
        let content = "content".asData

        let container = try RCContainer(data: RCContainerTestData.container(config: config, contentElements: [content]))
        let ref = RCContainerTestData.blobRef(for: content)
        let element = try XCTUnwrap(RCContainerTestData.contentElements(in: container)[ref])

        expect(ref).to(haveCount(32))
        expect(ref).toNot(contain("="))
        expect(ref.range(of: #"^[A-Za-z0-9_-]{32}$"#, options: .regularExpression)).toNot(beNil())
        expect(element.checksum) == ref
        expect(element.withChecksumBytes { $0.count }) == 24
    }

    func testDuplicateContentElementsCollapseToOneLookupEntry() throws {
        let content = "same payload".asData

        let container = try RCContainer(data: RCContainerTestData.container(config: "config".asData, contentElements: [
            content,
            content
        ]))
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(contentElementsByChecksum).to(haveCount(1))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: content)])
        )) == content
    }

    func testParsesLittleEndianElementSizes() throws {
        let config = Data(repeating: 0xab, count: 257)

        let container = try RCContainer(data: RCContainerTestData.container(config: config))

        expect(try RCContainerTestData.firstElement(in: container).size) == 257
        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == config
    }

    func testParsesNonZeroFlags() throws {
        let container = try RCContainer(data: RCContainerTestData.container(config: "config".asData, flags: 0x07))

        expect(container.flags) == 0x07
        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == "config".asData
    }

    func testIgnoresReservedFields() throws {
        let container = try RCContainer(data: RCContainerTestData.container(
            config: "config".asData,
            headerReservedBytes: [1, 2, 3, 4],
            elementReserved: 0x01020304
        ))

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == "config".asData
        expect(try RCContainerTestData.firstElement(in: container).reserved) == 0x01020304
    }

    func testAcceptsOmittedFinalPadding() throws {
        let config = "abc".asData

        let container = try RCContainer(data: RCContainerTestData.container(
            config: config,
            omitFinalPadding: true
        ))

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == config
    }

    func testAcceptsPartiallyOmittedFinalPadding() throws {
        var data = RCContainerTestData.container(config: "abc".asData)
        data.removeLast(3)

        let container = try RCContainer(data: data)

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == "abc".asData
    }

    func testParsesDataSliceWithNonZeroStartIndex() throws {
        let prefix = Data([0, 1, 2, 3, 4])
        let containerData = RCContainerTestData.container(config: "config".asData, contentElements: ["blob".asData])
        let prefixedData = prefix + containerData
        let slicedData = prefixedData[prefix.count..<prefixedData.endIndex]

        let container = try RCContainer(data: slicedData)
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == "config".asData
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: "blob".asData)])
        )) == "blob".asData
    }

    func testRejectsInvalidHeaderFields() {
        var invalidMagic = RCContainerTestData.container(config: "config".asData)
        invalidMagic[invalidMagic.startIndex] = UInt8(ascii: "X")
        Self.expectParsing(invalidMagic, throws: .invalidMagic)

        var unsupportedVersion = RCContainerTestData.container(config: "config".asData)
        let versionIndex = unsupportedVersion.index(
            unsupportedVersion.startIndex,
            offsetBy: RCContainerTestData.headerVersionOffset
        )
        unsupportedVersion[versionIndex] = 2
        Self.expectParsing(unsupportedVersion, throws: .unsupportedVersion(2))
    }

    func testRejectsTruncatedContainers() {
        Self.expectParsing(Data([UInt8(ascii: "R")]), throws: .truncatedHeader)
        Self.expectParsing(
            RCContainerTestData.header() + Data([0]),
            throws: .truncatedElementHeader(index: 0)
        )

        var truncatedElement = RCContainerTestData.header()
        truncatedElement.append(contentsOf: RCContainerTestData.checksum(for: "abcdefgh".asData))
        truncatedElement.appendLittleEndianUInt32(8)
        truncatedElement.appendLittleEndianUInt32(0)
        truncatedElement.append("abcdefg".asData)
        Self.expectParsing(truncatedElement, throws: .truncatedElement(index: 0))
    }

    func testParsesStructurallyValidEmptyContainer() throws {
        let container = try RCContainer(data: RCContainerTestData.header())

        expect(container.elements).to(beEmpty())
        expect(container.elementsByChecksum).to(beEmpty())
    }

    func testRejectsNonZeroPadding() {
        var data = RCContainerTestData.container(config: "abc".asData)
        let lastIndex = data.index(before: data.endIndex)
        data[lastIndex] = 1

        Self.expectParsing(data, throws: .nonZeroPadding(index: 0))
    }

    func testParsesStructurallyValidContainerWithConfigChecksumMismatch() throws {
        var data = RCContainerTestData.container(config: "config".asData)
        data[data.index(data.startIndex, offsetBy: RCContainerTestData.firstPayloadOffset)] = UInt8(ascii: "x")

        let container = try RCContainer(data: data)

        expect(try RCContainerTestData.firstElement(in: container).isChecksumValid()) == false
        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) == "xonfig".asData
    }

    func testParsesStructurallyValidContainerWithContentChecksumMismatch() throws {
        let content = "content".asData
        let data = RCContainerTestData.container(
            config: "config".asData,
            contentElements: [content],
            checksumOverride: { index, payload in
                return index == 1
                    ? Array(repeating: 0, count: RCContainerTestData.checksumSize)
                    : RCContainerTestData.checksum(for: payload)
            }
        )

        let container = try RCContainer(data: data)
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)
        let element = try XCTUnwrap(contentElementsByChecksum["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"])

        expect(element.isChecksumValid()) == false
        expect(RCContainerTestData.data(from: element)) == content
    }

    func testElementValidateChecksumThrowsChecksumMismatch() throws {
        let data = RCContainerTestData.container(
            config: "config".asData,
            checksumOverride: { _, _ in Array(repeating: 0, count: RCContainerTestData.checksumSize) }
        )
        let container = try RCContainer(data: data)

        do {
            try RCContainerTestData.firstElement(in: container).validateChecksum()
            fail("Expected checksum mismatch")
        } catch let error as RCContainer.Parser.FormatError {
            guard case let .checksumMismatch(expected, actual) = error else {
                fail("Expected checksum mismatch, got \(error)")
                return
            }

            expect(expected) == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            expect(actual) == RCContainerTestData.blobRef(for: "config".asData)
        } catch {
            fail("Expected RCContainer.Parser.FormatError, got \(error)")
        }
    }

    func testExposesPayloadThroughBorrowedByteClosure() throws {
        let payload = "borrowed bytes".asData
        let container = try RCContainer(data: RCContainerTestData.container(config: payload))

        let size = try RCContainerTestData.firstElement(in: container).withPayloadBytes { bytes in
            return bytes.count
        }
        let bytes = try RCContainerTestData.firstElement(in: container).withPayloadBytes { bytes in
            return Array(bytes)
        }

        expect(size) == payload.count
        expect(bytes) == Array(payload)
    }

    func testPayloadBytesPointIntoOriginalContainerStorage() throws {
        let payload = Data(repeating: 0xab, count: 128)
        let data = RCContainerTestData.container(config: payload)
        let container = try RCContainer(data: data)

        try data.withUnsafeBytes { containerBytes in
            let containerBaseAddress = UInt(bitPattern: try XCTUnwrap(containerBytes.baseAddress))

            try RCContainerTestData.firstElement(in: container).withPayloadBytes { payloadBytes in
                let payloadBaseAddress = UInt(bitPattern: try XCTUnwrap(payloadBytes.baseAddress))

                expect(payloadBaseAddress) == containerBaseAddress + UInt(RCContainerTestData.firstPayloadOffset)
            }
        }
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

}

private extension Data {

    mutating func appendLittleEndianUInt32(_ value: UInt32) {
        self.append(UInt8(value & 0xff))
        self.append(UInt8((value >> 8) & 0xff))
        self.append(UInt8((value >> 16) & 0xff))
        self.append(UInt8((value >> 24) & 0xff))
    }

}
