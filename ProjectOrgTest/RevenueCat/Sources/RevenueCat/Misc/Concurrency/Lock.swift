//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Lock.swift
//
//  Created by Nacho Soto on 11/15/21.

import Foundation

/// A lock abstraction over an instance of `NSLocking`
internal final class Lock {

    enum LockType {

        /// A lock backed by an `NSLock`
        case nonRecursive

        /// A lock backed by an `NSRecursiveLock`
        case recursive

    }

    private typealias UnderlyingType = NSLocking & Sendable

    private let lock: UnderlyingType
    private init(_ lock: UnderlyingType) { self.lock = lock }

    /// Creates an instance based on `LockType`
    convenience init(_ type: LockType = .nonRecursive) {
        self.init(type.create())
    }

    @discardableResult
    func perform<T>(_ block: () throws -> T) rethrows -> T {
        self.lock.lock()
        defer { self.lock.unlock() }

        return try block()
    }

}

extension Lock: Sendable {}

private extension Lock.LockType {

    func create() -> NSLocking {
        return {
            switch self {
            case .recursive:
                let lock = NSRecursiveLock()
                lock.name = "com.revenuecat.purchases.recursive_lock"

                return lock

            case .nonRecursive:
                let lock = NSLock()
                lock.name = "com.revenuecat.purchases.lock"

                return lock
            }
        }()
    }

}
