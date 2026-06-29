//
//  RCContainerTestData.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import XCTest

@testable import RevenueCat

enum RCContainerTestData {

    static let fixtureDirectory = "RCContainer"

    static let headerSize = 8
    static let headerMagicSize = 2
    static let headerReservedSize = 4
    static let checksumSize = 24
    static let uint32Size = 4
    static var headerVersionOffset: Int { return Self.headerMagicSize }
    static var elementHeaderSize: Int { return Self.checksumSize + Self.uint32Size + Self.uint32Size }
    static var firstPayloadOffset: Int { return Self.headerSize + Self.elementHeaderSize }

    static let workflowBlob = Self.workflowBlobText.asData
    static let summerWorkflowBlob = Self.summerWorkflowBlobText.asData
    static let configJSON = Self.configJSONText.asData
    static let largeBlob = Data((0..<300).map { UInt8($0 % 256) })
    static let smallBlob = "a".asData

    static let allFixtures: [Fixture] = [
        Fixture(
            fileName: "v1_config_only.bin",
            config: Self.configJSON
        ),
        Fixture(
            fileName: "v1_single_element.bin",
            config: Self.configJSON,
            contentElements: [Self.workflowBlob]
        ),
        Fixture(
            fileName: "v1_multiple_elements.bin",
            config: Self.configJSON,
            contentElements: [Self.smallBlob, Data(), Self.workflowBlob, Self.largeBlob]
        ),
        Fixture(
            fileName: "v1_empty_config.bin",
            config: Data(),
            contentElements: [Self.workflowBlob]
        ),
        Fixture(
            fileName: "v1_flags_set.bin",
            flags: 0x07,
            config: Self.configJSON
        ),
        Fixture(
            fileName: "v1_duplicate_elements.bin",
            config: Self.configJSON,
            contentElements: [Self.workflowBlob, Self.workflowBlob]
        )
    ]

    static func container(
        config: Data,
        contentElements: [Data] = [],
        version: UInt8 = 1,
        flags: UInt8 = 0,
        headerReservedBytes: [UInt8] = [0, 0, 0, 0],
        elementReserved: UInt32 = 0,
        omitFinalPadding: Bool = false,
        checksumOverride: ((Int, Data) -> [UInt8])? = nil
    ) -> Data {
        var data = Self.header(version: version, flags: flags, reservedBytes: headerReservedBytes)
        let elements = [config] + contentElements

        for (index, element) in elements.enumerated() {
            let isFinalElement = index == elements.count - 1
            data.appendElement(
                element,
                reserved: elementReserved,
                omitPadding: omitFinalPadding && isFinalElement,
                checksumOverride: checksumOverride?(index, element)
            )
        }

        return data
    }

    static func container(fixture: Fixture) -> Data {
        return Self.container(
            config: fixture.config,
            contentElements: fixture.contentElements,
            version: fixture.version,
            flags: fixture.flags
        )
    }

    static func header(
        version: UInt8 = 1,
        flags: UInt8 = 0,
        reservedBytes: [UInt8] = [0, 0, 0, 0]
    ) -> Data {
        var data = Data([UInt8(ascii: "R"), UInt8(ascii: "C"), version, flags])
        data.append(contentsOf: reservedBytes.prefix(Self.headerReservedSize))
        data.append(Data(repeating: 0, count: max(0, Self.headerReservedSize - reservedBytes.count)))
        return data
    }

    static func data(from element: RCContainer.Element) -> Data {
        return element.withPayloadBytes { Data($0) }
    }

    static func firstElement(in container: RCContainer) throws -> RCContainer.Element {
        return try XCTUnwrap(container.elements.first)
    }

    static func contentElements(in container: RCContainer) -> [String: RCContainer.Element] {
        return Dictionary(
            container.elements.dropFirst().map { ($0.checksum, $0) },
            uniquingKeysWith: { _, last in last }
        )
    }

    static func blobRef(for data: Data) -> String {
        return Data(Self.checksum(for: data))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func checksum(for data: Data) -> [UInt8] {
        return Array(data.sha256.prefix(Self.checksumSize))
    }

}

extension RCContainerTestData {

    struct Fixture {

        let fileName: String
        let version: UInt8
        let flags: UInt8
        let config: Data
        let contentElements: [Data]

        init(
            fileName: String,
            version: UInt8 = 1,
            flags: UInt8 = 0,
            config: Data,
            contentElements: [Data] = []
        ) {
            self.fileName = fileName
            self.version = version
            self.flags = flags
            self.config = config
            self.contentElements = contentElements
        }

    }

}

private extension RCContainerTestData {

    static let workflowBlobText = [
        "{",
        "  \"id\": \"wf1234\",",
        "  \"steps\": [ { \"type\": \"paywall\", \"offering\": \"default\" } ]",
        "}"
    ].joined(separator: "\n")

    static let summerWorkflowBlobText = [
        "{",
        "  \"id\": \"wf5678\",",
        "  \"steps\": [ { \"type\": \"paywall\", \"offering\": \"summerCampaign\" } ]",
        "}"
    ].joined(separator: "\n")

    static let configJSONText = [
        "{",
        "  \"domain\": \"app\",",
        "  \"manifest\": \"v1.1710000000.workflows:etag1\",",
        "  \"active_topics\": [\"workflows\"],",
        "  \"prefetch_blobs\": [\"\(RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob))\"],",
        "  \"topics\": {",
        "    \"workflows\": {",
        "      \"wf1234\": { \"offering_identifier\": \"default\", \"blob_ref\": \"\(RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob))\" },",
        "      \"wf5678\": { \"offering_identifier\": \"summerCampaign\", \"blob_ref\": \"\(RCContainerTestData.blobRef(for: RCContainerTestData.summerWorkflowBlob))\" }",
        "    }",
        "  }",
        "}"
    ].joined(separator: "\n")

}

private extension Data {

    mutating func appendElement(
        _ payload: Data,
        reserved: UInt32 = 0,
        omitPadding: Bool = false,
        checksumOverride: [UInt8]? = nil
    ) {
        self.append(contentsOf: checksumOverride ?? RCContainerTestData.checksum(for: payload))
        self.appendLittleEndianUInt32(UInt32(payload.count))
        self.appendLittleEndianUInt32(reserved)
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
