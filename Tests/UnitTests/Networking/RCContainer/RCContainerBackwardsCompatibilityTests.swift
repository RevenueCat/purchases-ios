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

        expect(container.flags) == 0
        expect(RCContainerTestData.data(from: container.config)) == RCContainerTestData.configJSON
        expect(container.config.checksum) == RCContainerTestData.blobRef(for: RCContainerTestData.configJSON)
        expect(container.config.withChecksumBytes { $0.count }) == RCContainerTestData.checksumSize
        expect(container.contentElements).to(beEmpty())
    }

    func testSingleElementFixtureParses() throws {
        let container = try Self.parseFixture("v1_single_element")
        let blob = RCContainerTestData.entitlementMappingBlob
        let element = try XCTUnwrap(container.contentElements[RCContainerTestData.blobRef(for: blob)])

        expect(RCContainerTestData.data(from: container.config)) == RCContainerTestData.configJSON
        expect(container.contentElements).to(haveCount(1))
        expect(RCContainerTestData.data(from: element)) == blob
        expect(element.checksum) == RCContainerTestData.blobRef(for: blob)
    }

    func testMultipleElementsFixtureParsesWithDifferingSizes() throws {
        let container = try Self.parseFixture("v1_multiple_elements")
        let expected = [
            RCContainerTestData.smallBlob,
            Data(),
            RCContainerTestData.entitlementMappingBlob,
            RCContainerTestData.largeBlob
        ]

        expect(RCContainerTestData.data(from: container.config)) == RCContainerTestData.configJSON
        expect(container.contentElements).to(haveCount(expected.count))

        for blob in expected {
            let element = try XCTUnwrap(container.contentElements[RCContainerTestData.blobRef(for: blob)])
            expect(RCContainerTestData.data(from: element)) == blob
        }

        let largeElement = try XCTUnwrap(
            container.contentElements[RCContainerTestData.blobRef(for: RCContainerTestData.largeBlob)]
        )
        expect(largeElement.size) == 300
    }

    func testEmptyConfigFixtureParses() throws {
        let container = try Self.parseFixture("v1_empty_config")
        let blob = RCContainerTestData.entitlementMappingBlob

        expect(container.config.size) == 0
        expect(RCContainerTestData.data(from: container.config)).to(beEmpty())
        expect(container.contentElements).to(haveCount(1))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(container.contentElements[RCContainerTestData.blobRef(for: blob)])
        )) == blob
    }

    func testFlagsSetFixturePreservesHeaderFlags() throws {
        let container = try Self.parseFixture("v1_flags_set")

        expect(container.flags) == 0x07
        expect(RCContainerTestData.data(from: container.config)) == RCContainerTestData.configJSON
    }

    func testDuplicateElementsFixtureCollapsesInContentAddressedMap() throws {
        let container = try Self.parseFixture("v1_duplicate_elements")

        expect(container.contentElements).to(haveCount(1))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(container.contentElements[
                RCContainerTestData.blobRef(for: RCContainerTestData.entitlementMappingBlob)
            ])
        )) == RCContainerTestData.entitlementMappingBlob
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

}
