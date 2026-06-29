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
/// Elements repeat until the backing data is exhausted (the format stores no count). The final
/// element may omit trailing padding, but any padding bytes present in the container must be zero.
///
/// Elements are stored in wire order and are keyed by their checksum encoded as a 32-character
/// URL-safe base64 string with no padding. `Element` exposes closure-based byte access backed by
/// the original container data, so parsing does not create per-element `Data` copies.
struct RCContainer {

    /// Format flags from the container header.
    ///
    /// The parser preserves these bits for future use. Version 1 does not currently interpret them.
    let flags: UInt8

    /// Elements in the order they appear in the container.
    let elements: [Element]

    /// Elements keyed by their externally-referenced blob ref string.
    ///
    /// If the container contains duplicate checksums, the last element wins to match the
    /// content lookup behavior used by the backend and Android parser.
    let elementsByChecksum: [String: Element]

    init(
        flags: UInt8,
        elements: [Element]
    ) {
        self.flags = flags
        self.elements = elements
        self.elementsByChecksum = Dictionary(
            elements.map { ($0.checksum, $0) },
            uniquingKeysWith: { _, last in last }
        )
    }

    /// Parses and structurally validates an RC Container while retaining the original `Data` backing storage.
    ///
    /// Element payloads are exposed through closure-based byte access on `Element`, so constructing the
    /// container does not create per-element `Data` copies.
    init(data: Data) throws {
        var parser = Parser(data: data)
        let parsed = try parser.parse()

        self.init(flags: parsed.flags, elements: parsed.elements)
    }

}
