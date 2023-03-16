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

extension Date {

    init(millisecondsSince1970: UInt64) {
        self.init(timeIntervalSince1970: TimeInterval(millisecondsSince1970) / 1000)
    }

    /// - Important: this needs to be 64 bits because `Int` is 32 bits in watchOS
    var millisecondsSince1970: UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000)
    }

}
