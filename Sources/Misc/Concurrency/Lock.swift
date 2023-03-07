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

    #if swift(>=5.7)
    private typealias UnderlyingType = NSLocking & Sendable
    #else
    // `NSRecursiveLock` and `NSLock` aren't `Sendable` until iOS 16.0 / Swift 5.7
    private typealias UnderlyingType = NSLocking
    #endif

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

#if swift(>=5.7)
extension Lock: Sendable {}
#else
// `Lock.UnderlyingType` isn't `Sendable` until Swift 5.7
extension Lock: @unchecked Sendable {}
#endif

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
