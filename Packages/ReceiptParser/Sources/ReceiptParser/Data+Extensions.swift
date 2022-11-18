//
//  File.swift
//  
//
//  Created by Nacho Soto on 11/18/22.
//

import Foundation

public extension NSData {

    func asString() -> String {
        // 2 characters per byte
        let deviceTokenString = NSMutableString(capacity: self.length * 2)

        self.enumerateBytes { bytes, byteRange, _ in
            for index in stride(from: 0, to: byteRange.length, by: 1) {
                let byte = bytes.load(fromByteOffset: index, as: UInt8.self)
                deviceTokenString.appendFormat("%02x", byte)
            }
        }

        return deviceTokenString as String
    }

}

public extension Data {

    var asString: String {
        return (self as NSData).asString()
    }

    /// Returns a string representing a fetch token.
    var asFetchToken: String {
        return self.base64EncodedString()
    }

}
