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

internal final class Lock {

    private let recursiveLock: NSRecursiveLock = {
        let lock = NSRecursiveLock()
        lock.name = "com.revenuecat.purchases.lock"

        return lock
    }()

    @discardableResult
    func perform<T>(_ block: () throws -> T) rethrows -> T {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }

        return try block()
    }

}
