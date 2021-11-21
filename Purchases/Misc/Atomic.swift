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

/// An atomic variable.
internal final class Atomic<T> {

    private let lock: Lock
    private var _value: T

    /// Atomically get or set the value of the variable.
    var value: T {
        get { withValue { $0 } }
        set { modify { $0 = newValue } }
    }

    init(_ value: T) {
        _value = value
        lock = Lock()
    }

    /// Atomically modifies the variable.
    @discardableResult
    func modify<Result>(_ action: (inout T) throws -> Result) rethrows -> Result {
        return try lock.perform {
            try action(&_value)
        }
    }

    /// Atomically perform an action using the current value.
    @discardableResult
    func withValue<Result>(_ action: (T) throws -> Result) rethrows -> Result {
        return try lock.perform {
            try action(_value)
        }
    }

}
