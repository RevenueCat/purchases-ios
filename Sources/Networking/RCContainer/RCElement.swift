//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCElement.swift
//
//  Created on RC Container Format v1 PoC.

import CryptoKit
import Foundation

/// A single element within an ``RCContainer``.
///
/// Both ``checksum`` and ``data`` are zero-copy slices over the container's backing buffer:
/// no element bytes are copied or hashed during parsing. Callers that need integrity
/// verification opt in explicitly via ``isChecksumValid()``.
struct RCElement {

    /// The stored SHA-256 of ``data``, as a 32-byte slice.
    let checksum: Data

    /// A zero-copy slice over this element's bytes.
    let data: Data

    /// Computes the SHA-256 of ``data`` and compares it against the stored ``checksum``.
    ///
    /// The element bytes are not hashed or copied during parsing; this work happens only
    /// when a caller explicitly opts into verification.
    func isChecksumValid() -> Bool {
        let computed = SHA256.hash(data: self.data)
        return computed.elementsEqual(self.checksum)
    }

}
