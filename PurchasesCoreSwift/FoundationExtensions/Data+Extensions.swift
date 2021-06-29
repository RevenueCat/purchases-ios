//
//  Data+Extensions.swift
//  PurchasesCoreSwift
//
//  Created by Josh Holtz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

public extension NSData {
    @objc func rc_asString() -> String {
        var deviceTokenString = ""
        self.enumerateBytes { bytes, byteRange, _ in
            for index in stride(from: 0, to: byteRange.length, by: 1) {
                let byte = bytes.load(fromByteOffset: index, as: UInt8.self)
                deviceTokenString = deviceTokenString.appendingFormat("%02x", byte)
            }
        }
        return deviceTokenString
    }
}
