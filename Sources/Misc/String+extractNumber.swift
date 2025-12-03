//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  String+extractNumber.swift
//
//  Created by Jacob Zivan Rakidzich on 12/3/25.

import Foundation

@_spi(Internal) public extension String {

    /// Take all numbers out of a string and return an Int if present
    func extractNumber() -> Int? {
        return Int(filter { "0"..."9" ~= $0 })
    }
}
