//
//  Data+Extension.swift
//  TPReceiptValidator
//
//  Created by Pavel Tikhonenko on 29/09/16.
//  Copyright © 2016-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation
    
extension Data
{
    init(hex: String)
    {
        self.init(Array<UInt8>(hex: hex))
    }
    
    var bytes: Array<UInt8>
    {
        return Array(self)
    }
    
    func toHexString() -> String
    {
        return bytes.`lazy`.reduce("")
        {
            var s = String($1, radix: 16)
            if s.count == 1
            {
                s = "0" + s
            }
            return $0 + s
        }
    }
    
    /// Array of UInt8, to use for SecKeyEncrypt
    func arrayOfBytes() -> [UInt8] {
        let count = self.count / MemoryLayout<UInt8>.size
        var bytesArray = [UInt8](repeating: 0, count: count)
        (self as NSData).getBytes(&bytesArray, length:count * MemoryLayout<UInt8>.size)
        return bytesArray
    }
    
}
