//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Integer+Extensions.swift
//
//  Created by Nacho Soto on 6/26/23.

import Foundation

extension UInt32 {

    /// Converts 32 bits of little-endian `Data` into a `UInt32`.
    init(littleEndian32Bits data: Data) {
        assert(data.count == 4, "Data needs to be 32bits: \(data)")

        self.init(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
    }

    /// - Returns: the `Data` representation as little-endian 32 bits.
    var littleEndianData: Data {
        return Data(withUnsafeBytes(of: self.littleEndian, Array.init))
    }

}
