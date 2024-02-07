//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Operators+Extensions.swift
//
//  Created by Nacho Soto on 5/23/22.

infix operator ???

/// Equivalent to `??` but allows an `async` default value.
/// See https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md#future-directions
func ??? <T>(value: T?, defaultValue: @autoclosure () async throws -> T) async rethrows -> T {
    if let value = value {
        return value
    } else {
        return try await defaultValue()
    }
}
