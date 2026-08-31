//
//  RCContainerCompressionFixtureTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 30/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RCContainerCompressionFixtureTests: TestCase {

    func testGzipConfigFixtureParsesAndDecodes() throws {
        let container = try Self.parseFixture("v1_gzip_config")
        let configElement = try RCContainerTestData.firstElement(in: container)

        expect(configElement.encoding) == .gzip
        expect(RCContainerTestData.data(from: configElement)) != RCContainerTestData.configJSON
        expect(try RCContainerTestData.decodedData(from: configElement)) == RCContainerTestData.configJSON
        expect(configElement.isChecksumValid()) == true
        expect(RCContainerTestData.contentElements(in: container)).to(beEmpty())
    }

    func testGzipContentFixtureParsesAndDecodes() throws {
        let container = try Self.parseFixture("v1_gzip_content")
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)
        let contentElement = try XCTUnwrap(
            contentElementsByChecksum[RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob)]
        )

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) ==
        RCContainerTestData.configJSON
        expect(contentElement.encoding) == .gzip
        expect(RCContainerTestData.data(from: contentElement)) != RCContainerTestData.workflowBlob
        expect(try RCContainerTestData.decodedData(from: contentElement)) == RCContainerTestData.workflowBlob
        expect(contentElement.isChecksumValid()) == true
    }

    func testBrotliConfigFixtureParsesAndDecodesWhenSupported() throws {
        try Self.skipIfBrotliIsUnsupported()

        let container = try Self.parseFixture("v1_brotli_config")
        let configElement = try RCContainerTestData.firstElement(in: container)

        expect(configElement.encoding) == .brotli
        expect(RCContainerTestData.data(from: configElement)) != RCContainerTestData.configJSON
        expect(try RCContainerTestData.decodedData(from: configElement)) == RCContainerTestData.configJSON
        expect(configElement.isChecksumValid()) == true
        expect(RCContainerTestData.contentElements(in: container)).to(beEmpty())
    }

    func testBrotliContentFixtureParsesAndDecodesWhenSupported() throws {
        try Self.skipIfBrotliIsUnsupported()

        let container = try Self.parseFixture("v1_brotli_content")
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)
        let contentElement = try XCTUnwrap(
            contentElementsByChecksum[RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob)]
        )

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) ==
        RCContainerTestData.configJSON
        expect(contentElement.encoding) == .brotli
        expect(RCContainerTestData.data(from: contentElement)) != RCContainerTestData.workflowBlob
        expect(try RCContainerTestData.decodedData(from: contentElement)) == RCContainerTestData.workflowBlob
        expect(contentElement.isChecksumValid()) == true
    }

    func testMixedEncodingsFixtureParsesAndDecodesWhenSupported() throws {
        try Self.skipIfBrotliIsUnsupported()

        let container = try Self.parseFixture("v1_mixed_encodings")
        let configElement = try RCContainerTestData.firstElement(in: container)
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(configElement.encoding) == .gzip
        expect(try RCContainerTestData.decodedData(from: configElement)) == RCContainerTestData.configJSON

        let expectedContent = [
            (RCContainerTestData.smallBlob, RCContainer.Element.ContentEncoding.none),
            (RCContainerTestData.workflowBlob, .gzip),
            (RCContainerTestData.largeBlob, .brotli)
        ]

        for (payload, encoding) in expectedContent {
            let element = try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: payload)])
            expect(element.encoding) == encoding
            expect(try RCContainerTestData.decodedData(from: element)) == payload
            expect(element.isChecksumValid()) == true
        }
    }

}

private extension RCContainerCompressionFixtureTests {

    static func parseFixture(
        _ fileName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> RCContainer {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: fileName,
                withExtension: "bin",
                subdirectory: "Fixtures/\(RCContainerTestData.fixtureDirectory)"
            ),
            "Could not find RC Container fixture: \(fileName).bin",
            file: file,
            line: line
        )
        return try RCContainer(data: Data(contentsOf: url))
    }

    static func skipIfBrotliIsUnsupported() throws {
        guard RCContainer.Element.ContentEncoding.brotli.isSupported else {
            throw XCTSkip("Brotli fixtures require OS support for decoding.")
        }
    }

}
