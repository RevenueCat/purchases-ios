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
 * - Important: The closures aren't re-entrant.
 * In other words, `Atomic` instances cannot be used from within the `modify` and `withValue` closures
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
        self._value = value
        self.lock = Lock()
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

// Syntactic sugar that allows initializing an `Atomic` optional value by directly assigning `nil`,
// i.e.: `let foo: Atomic<Foo?> = nil` instead of the more indirect `let foo: Atomic<Foo?> = .init(nil)`
extension Atomic: ExpressibleByNilLiteral where T: OptionalType {

    convenience init(nilLiteral: ()) {
        self.init(.init(optional: nil))
    }

}

// Syntactic sugar that allows initializing an `Atomic` `Bool` by directly assigning its value,
// i.e.: `let foo: Atomic<Bool> = false` instead of the more indirect `let foo: Atomic<Bool> = .init(false)`
extension Atomic: ExpressibleByBooleanLiteral where T == Bool {

    convenience init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }

}

// `@unchecked` because of the mutable `_value`, but it's thread-safety is guaranteed with `Lock`.
extension Atomic: @unchecked Sendable {}
