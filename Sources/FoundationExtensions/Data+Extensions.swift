//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Data+Extensions.swift
//  Purchases
//
//  Created by Josh Holtz on 6/28/21.
//

import Foundation

extension NSData {

    var uuid: UUID? {
        let bytes = [UInt8](self)
        return NSUUID(uuidBytes: bytes) as UUID
    }

}

extension Data {

    var uuid: UUID? {
        (self as NSData).uuid
    }

}

/// A type that can read data from disk
/// Useful for mocking.
protocol FileReader {

    func contents(of url: URL) -> Data?

}

/// Default implementation of `FileReader` that simply uses `Data`'s implementation.
final class DefaultFileReader: FileReader {

    func contents(of url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }

}
