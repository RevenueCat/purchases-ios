//
//  RCContainerBackwardsCompatibilityTests.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RCContainerBackwardsCompatibilityTests: TestCase {

    func testConfigOnlyFixtureParses() throws {
        let container = try Self.parseFixture("v1_config_only")
        let configElement = try RCContainerTestData.firstElement(in: container)

        expect(container.flags) == 0
        expect(RCContainerTestData.data(from: configElement)) == RCContainerTestData.configJSON
        expect(configElement.checksum) == RCContainerTestData.blobRef(for: RCContainerTestData.configJSON)
        expect(configElement.withChecksumBytes { $0.count }) == RCContainerTestData.checksumSize
        expect(RCContainerTestData.contentElements(in: container)).to(beEmpty())
    }

    func testSingleElementFixtureParses() throws {
        let container = try Self.parseFixture("v1_single_element")
        let blob = RCContainerTestData.workflowBlob
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)
        let element = try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: blob)])

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) ==
        RCContainerTestData.configJSON
        expect(contentElementsByChecksum).to(haveCount(1))
        expect(RCContainerTestData.data(from: element)) == blob
        expect(element.checksum) == RCContainerTestData.blobRef(for: blob)
    }

    func testMultipleElementsFixtureParsesWithDifferingSizes() throws {
        let container = try Self.parseFixture("v1_multiple_elements")
        let expected = [
            RCContainerTestData.smallBlob,
            Data(),
            RCContainerTestData.workflowBlob,
            RCContainerTestData.largeBlob
        ]
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))) ==
        RCContainerTestData.configJSON
        expect(contentElementsByChecksum).to(haveCount(expected.count))

        for blob in expected {
            let element = try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: blob)])
            expect(RCContainerTestData.data(from: element)) == blob
        }

        let largeElement = try XCTUnwrap(
            contentElementsByChecksum[RCContainerTestData.blobRef(for: RCContainerTestData.largeBlob)]
        )
        expect(largeElement.size) == 300
    }

    func testEmptyConfigFixtureParses() throws {
        let container = try Self.parseFixture("v1_empty_config")
        let blob = RCContainerTestData.workflowBlob
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(try RCContainerTestData.firstElement(in: container).size) == 0
        expect(RCContainerTestData.data(from: try RCContainerTestData.firstElement(in: container))).to(beEmpty())
        expect(contentElementsByChecksum).to(haveCount(1))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[RCContainerTestData.blobRef(for: blob)])
        )) == blob
    }

    func testFlagsSetFixtureParses() throws {
        let container = try Self.parseFixture("v1_flags_set")

        expect(container.flags) == 0x07
    }

    func testDuplicateElementsFixtureCollapsesInContentAddressedMap() throws {
        let container = try Self.parseFixture("v1_duplicate_elements")
        let contentElementsByChecksum = RCContainerTestData.contentElements(in: container)

        expect(contentElementsByChecksum).to(haveCount(1))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(contentElementsByChecksum[
                RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob)
            ])
        )) == RCContainerTestData.workflowBlob
    }

    func testGenerateFixtures() throws {
        guard Self.shouldGenerateFixtures else {
            throw XCTSkip("Set GENERATE_RC_CONTAINER_FIXTURES=1 to regenerate RC Container fixtures.")
        }

        let directoryURL = Self.sourceFixtureDirectoryURL
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        for fixture in RCContainerTestData.allFixtures {
            let url = directoryURL.appendingPathComponent(fixture.fileName)
            try RCContainerTestData.container(fixture: fixture).write(to: url, options: .atomic)
        }
    }

}

// MARK: - Helpers

private extension RCContainerBackwardsCompatibilityTests {

    static var shouldGenerateFixtures: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["GENERATE_RC_CONTAINER_FIXTURES"] == "1"
        || environment["TEST_RUNNER_GENERATE_RC_CONTAINER_FIXTURES"] == "1"
    }

    static var sourceFixtureDirectoryURL: URL {
        let fileURL = URL(fileURLWithPath: #filePath)
        return fileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Responses", isDirectory: true)
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(RCContainerTestData.fixtureDirectory, isDirectory: true)
    }

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

    static func expectParsingFixture(
        _ fileName: String,
        throws expectedError: RCContainer.Parser.FormatError,
        file: FileString = #file,
        line: UInt = #line
    ) {
        do {
            _ = try Self.parseFixture(fileName, line: line)
            fail("Expected \(expectedError)", file: file, line: line)
        } catch let error as RCContainer.Parser.FormatError {
            expect(file: file, line: line, error) == expectedError
        } catch {
            fail("Expected RCContainer.Parser.FormatError, got \(error)", file: file, line: line)
        }
    }

}
