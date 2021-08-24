//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Date+Extensions.swift
//
//  Created by Josh Holtz on 6/28/21.
//

import Foundation

extension NSDate {

    func rc_millisecondsSince1970AsUInt64() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000.0)
    }

}

extension Date {

    func rc_millisecondsSince1970AsUInt64() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000.0)
    }

}
