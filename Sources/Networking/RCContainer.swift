//
//  RCContainer.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Parsed representation of an RC Container response.
///
/// Layout (all multi-byte integers little-endian):
/// ```
/// Header (8 bytes): magic byte[2]="RC" | version u8 | flags u8 | reserved byte[4]
/// Element:          checksum byte[24]  | element_size u32 | reserved u32 | element[element_size] | pad -> 8
/// ```
/// Elements repeat until the backing data is exhausted (the format stores no count). Element 0 is
/// always `config`; the remaining elements are content-addressed by checksum. The final element may
/// omit trailing padding, but any padding bytes present in the container must be zero.
///
/// Content elements are keyed by their checksum encoded as a 32-character URL-safe base64 string
/// with no padding. `config` and each `Element` expose closure-based byte access backed by the
/// original container data, so parsing does not create per-element `Data` copies.
struct RCContainer {

    /// Format flags from the container header.
    ///
    /// The parser preserves these bits for future use. Version 1 does not currently interpret them.
    let flags: UInt8

    /// The first element in the container. This contains the remote config payload.
    let config: Element

    /// Remaining elements, keyed by their externally-referenced blob ref string.
    ///
    /// If the container contains duplicate content checksums, the last element wins to match the
    /// content lookup behavior used by the backend and Android parser.
    let contentElements: [String: Element]

    /// Parses and validates an RC Container while retaining the original `Data` backing storage.
    ///
    /// Element payloads are exposed through closure-based byte access on `Element`, so constructing the
    /// container does not create per-element `Data` copies.
    init(data: Data) throws {
        var parser = Parser(data: data)
        let parsed = try parser.parse()
        let elements = parsed.elements
        guard let config = elements.first else {
            throw Parser.FormatError.missingConfigElement
        }

        self.flags = parsed.flags
        self.config = config
        self.contentElements = Dictionary(
            elements.dropFirst().map { ($0.checksum, $0) },
            uniquingKeysWith: { _, last in last }
        )
    }

}

extension RCContainer: HTTPResponseBody {

    static func create(with data: Data) throws -> RCContainer {
        return try .init(data: data)
    }

}
