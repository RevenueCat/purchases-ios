//
//  RCContainerTestData.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Compression
import Foundation
import XCTest
import zlib

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
    static var firstElementEncodingOffset: Int { return Self.headerSize + Self.checksumSize + Self.uint32Size }
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
        ),
        Fixture(
            fileName: "v1_gzip_config.bin",
            config: Self.configJSON,
            configEncoding: .gzip
        ),
        Fixture(
            fileName: "v1_gzip_content.bin",
            config: Self.configJSON,
            contentElements: [
                .init(payload: Self.workflowBlob, encoding: .gzip)
            ]
        ),
        Fixture(
            fileName: "v1_brotli_config.bin",
            config: Self.configJSON,
            configEncoding: .brotli
        ),
        Fixture(
            fileName: "v1_brotli_content.bin",
            config: Self.configJSON,
            contentElements: [
                .init(payload: Self.workflowBlob, encoding: .brotli)
            ]
        ),
        Fixture(
            fileName: "v1_mixed_encodings.bin",
            config: Self.configJSON,
            configEncoding: .gzip,
            contentElements: [
                .init(payload: Self.smallBlob, encoding: .none),
                .init(payload: Self.workflowBlob, encoding: .gzip),
                .init(payload: Self.largeBlob, encoding: .brotli)
            ]
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

    static func container(fixture: Fixture) throws -> Data {
        return try Self.compressedContainer(
            config: fixture.config,
            configEncoding: fixture.configEncoding,
            contentElements: fixture.contentElements.map { ($0.payload, $0.encoding) },
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

    static func decodedData(from element: RCContainer.Element) throws -> Data {
        return try element.withDecodedPayloadBytes { Data($0) }
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

    static func compressedContainer(
        config: Data,
        configEncoding: RCContainer.Element.ContentEncoding = .none,
        contentElements: [(payload: Data, encoding: RCContainer.Element.ContentEncoding)] = [],
        version: UInt8 = 1,
        flags: UInt8 = 0
    ) throws -> Data {
        var data = Self.header(version: version, flags: flags)
        try data.appendElement(config, encoding: configEncoding)

        for element in contentElements {
            try data.appendElement(element.payload, encoding: element.encoding)
        }

        return data
    }

    static func compressedContainerWithTrailingGzipBytes(
        config: Data,
        trailingBytes: Data,
        contentElements: [(payload: Data, encoding: RCContainer.Element.ContentEncoding)] = []
    ) throws -> Data {
        var data = Self.header()
        try data.appendGzipElement(config, trailingBytes: trailingBytes)

        for element in contentElements {
            try data.appendElement(element.payload, encoding: element.encoding)
        }

        return data
    }

    static func compressedContainerWithTrailingGzipContentElement(
        config: Data,
        content: Data,
        trailingBytes: Data
    ) throws -> Data {
        var data = Self.header()
        try data.appendElement(config, encoding: .none)
        try data.appendGzipElement(content, trailingBytes: trailingBytes)

        return data
    }

}

extension RCContainerTestData {

    struct Fixture {

        let fileName: String
        let version: UInt8
        let flags: UInt8
        let config: Data
        let configEncoding: RCContainer.Element.ContentEncoding
        let contentElements: [Element]

        init(
            fileName: String,
            version: UInt8 = 1,
            flags: UInt8 = 0,
            config: Data,
            configEncoding: RCContainer.Element.ContentEncoding = .none,
            contentElements: [Data] = []
        ) {
            self.init(
                fileName: fileName,
                version: version,
                flags: flags,
                config: config,
                configEncoding: configEncoding,
                contentElements: contentElements.map { Element(payload: $0, encoding: .none) }
            )
        }

        init(
            fileName: String,
            version: UInt8 = 1,
            flags: UInt8 = 0,
            config: Data,
            configEncoding: RCContainer.Element.ContentEncoding = .none,
            contentElements: [Element]
        ) {
            self.fileName = fileName
            self.version = version
            self.flags = flags
            self.config = config
            self.configEncoding = configEncoding
            self.contentElements = contentElements
        }

    }

    struct Element {

        let payload: Data
        let encoding: RCContainer.Element.ContentEncoding

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
        "      \"wf1234\": { \"offering_identifier\": \"default\", " +
        "\"blob_ref\": \"\(RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob))\" },",
        "      \"wf5678\": { \"offering_identifier\": \"summerCampaign\", " +
        "\"blob_ref\": \"\(RCContainerTestData.blobRef(for: RCContainerTestData.summerWorkflowBlob))\" }",
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
        precondition(reserved == 0)
        // The current format uses the old reserved UInt32 slot as `encoding UInt8 + 3 reserved bytes`.
        // Keeping this helper uncompressed preserves the original fixture bytes when `reserved == 0`.
        try? self.appendElement(
            payload,
            encoding: .none,
            omitPadding: omitPadding,
            checksumOverride: checksumOverride
        )
    }

    mutating func appendElement(
        _ payload: Data,
        encoding: RCContainer.Element.ContentEncoding,
        omitPadding: Bool = false,
        checksumOverride: [UInt8]? = nil
    ) throws {
        let wirePayload = try RCContainerTestData.wirePayload(for: payload, encoding: encoding)

        self.append(contentsOf: checksumOverride ?? RCContainerTestData.checksum(for: payload))
        self.appendLittleEndianUInt32(UInt32(wirePayload.count))
        self.append(encoding.rawValue)
        self.append(contentsOf: [0, 0, 0])
        self.append(wirePayload)

        guard !omitPadding else {
            return
        }

        self.append(Data(repeating: 0, count: (8 - wirePayload.count % 8) % 8))
    }

    mutating func appendGzipElement(
        _ payload: Data,
        trailingBytes: Data
    ) throws {
        var wirePayload = try RCContainerTestData.gzipCompressed(payload)
        wirePayload.append(trailingBytes)

        self.append(contentsOf: RCContainerTestData.checksum(for: payload))
        self.appendLittleEndianUInt32(UInt32(wirePayload.count))
        self.append(RCContainer.Element.ContentEncoding.gzip.rawValue)
        self.append(contentsOf: [0, 0, 0])
        self.append(wirePayload)
        self.append(Data(repeating: 0, count: (8 - wirePayload.count % 8) % 8))
    }

    mutating func appendLittleEndianUInt32(_ value: UInt32) {
        self.append(UInt8(value & 0xff))
        self.append(UInt8((value >> 8) & 0xff))
        self.append(UInt8((value >> 16) & 0xff))
        self.append(UInt8((value >> 24) & 0xff))
    }

}

private extension RCContainerTestData {

    static let outputChunkSize = 64 * 1024

    static func wirePayload(
        for payload: Data,
        encoding: RCContainer.Element.ContentEncoding
    ) throws -> Data {
        switch encoding {
        case .none:
            return payload
        case .gzip:
            return try Self.gzipCompressed(payload)
        case .brotli:
            return try Self.brotliCompressed(payload)
        case .zstd, .unsupported:
            return payload
        }
    }

    static func gzipCompressed(_ data: Data) throws -> Data {
        var stream = z_stream()
        let streamSize = Int32(MemoryLayout<z_stream>.size)
        guard deflateInit2_(
            &stream,
            Z_BEST_COMPRESSION,
            Z_DEFLATED,
            MAX_WBITS + 16,
            MAX_MEM_LEVEL,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            streamSize
        ) == Z_OK else {
            throw RCContainer.Parser.FormatError.unsupportedContentEncoding(
                RCContainer.Element.ContentEncoding.gzip.rawValue
            )
        }
        defer { deflateEnd(&stream) }

        return try data.withUnsafeBytes { inputBytes in
            stream.next_in = UnsafeMutablePointer<Bytef>(
                mutating: inputBytes.bindMemory(to: Bytef.self).baseAddress
            )
            stream.avail_in = uInt(inputBytes.count)

            var output = Data()
            var status: Int32 = Z_OK
            repeat {
                var chunk = [UInt8](repeating: 0, count: Self.outputChunkSize)
                try chunk.withUnsafeMutableBytes { outputBytes in
                    stream.next_out = outputBytes.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBytes.count)

                    status = deflate(&stream, Z_FINISH)
                    guard status == Z_OK || status == Z_STREAM_END else {
                        throw RCContainer.Parser.FormatError.unsupportedContentEncoding(
                            RCContainer.Element.ContentEncoding.gzip.rawValue
                        )
                    }

                    let byteCount = outputBytes.count - Int(stream.avail_out)
                    output.append(contentsOf: outputBytes.prefix(byteCount))
                }
            } while status != Z_STREAM_END

            return output
        }
    }

    static func brotliCompressed(_ data: Data) throws -> Data {
        // Build the algorithm from the C constant instead of referencing `.brotli` directly. See
        // `RCContainer.Element.ContentEncoding.brotliAlgorithm`: referencing the case strong-links a
        // symbol that is missing on runtimes before iOS 16 / macOS 13 / tvOS 16 / watchOS 9, which
        // would crash this test bundle at load time on older simulators.
        guard let algorithm = RCContainer.Element.ContentEncoding.brotliAlgorithm else {
            throw RCContainer.Parser.FormatError.unsupportedContentEncoding(
                RCContainer.Element.ContentEncoding.brotli.rawValue
            )
        }

        var output = Data()
        let filter = try OutputFilter(.compress, using: algorithm) { chunk in
            if let chunk {
                output.append(chunk)
            }
        }

        try filter.write(data)
        try filter.finalize()

        return output
    }

}
