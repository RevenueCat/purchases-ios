//
//  Date+Extensions.swift
//  PurchasesCoreSwift
//
//  Created by Josh Holtz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

public extension NSDate {
    func rc_millisecondsSince1970AsUInt64() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000.0)
    }
}

public extension Date {
    func rc_millisecondsSince1970AsUInt64() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000.0)
    }
}
