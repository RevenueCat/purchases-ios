//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Atomic.swift
//
//  Created by Nacho Soto on 11/20/21.

import Foundation

/**
 * A generic object that performs all write and read operations atomically.
 * Use it to prevent data races when accessing an object.
 *
 * Usage:
 * ```swift
 * let foo = Atomic<MyClass>
 *
 * // read values
 * foo.withValue {
 *     let currentBar = $0.bar
 *     let currentX = $0.x
 * }
 *
 * // write value
 * foo.modify {
 *     $0.bar = 2
 *     $0.x = "new X"
 * }
 * ```
 *
 * Or for single-line read/writes:
 * ```swift
 * let currentX = foo.value.x
 * foo.value = MyClass()
 * ```
 **/
internal final class Atomic<T> {

    private let lock: Lock
    private var _value: T

    var value: T {
        get { withValue { $0 } }
        set { modify { $0 = newValue } }
    }

    init(_ value: T) {
        _value = value
        lock = Lock()
    }

    @discardableResult
    func modify<Result>(_ action: (inout T) throws -> Result) rethrows -> Result {
        return try lock.perform {
            try action(&_value)
        }
    }

    @discardableResult
    func withValue<Result>(_ action: (T) throws -> Result) rethrows -> Result {
        return try lock.perform {
            try action(_value)
        }
    }

}
