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

    func asString() -> String {
        var deviceTokenString = ""
        self.enumerateBytes { bytes, byteRange, _ in
            for index in stride(from: 0, to: byteRange.length, by: 1) {
                let byte = bytes.load(fromByteOffset: index, as: UInt8.self)
                deviceTokenString = deviceTokenString.appendingFormat("%02x", byte)
            }
        }
        return deviceTokenString
    }

    var uuid: UUID? {
        let bytes = [UInt8](self)
        return NSUUID(uuidBytes: bytes) as UUID
    }

}

extension Data {

    var asString: String {
        return (self as NSData).asString()
    }

    // Returns a string representing a fetch token.
    var asFetchToken: String {
        return self.base64EncodedString()
    }

    var uuid: UUID? {
        (self as NSData).uuid
    }

}
