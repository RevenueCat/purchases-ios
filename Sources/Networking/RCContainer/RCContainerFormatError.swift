//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCContainerFormatError.swift
//
//  Created on RC Container Format v1 PoC.

import Foundation

/// Thrown when bytes cannot be parsed as a valid RC Container Format v1 payload
/// (bad magic, unsupported version, truncated data, or sizes that exceed the buffer).
struct RCContainerFormatError: Error, CustomStringConvertible {

    let message: String

    init(_ message: String) {
        self.message = message
    }

    var description: String { self.message }

}
