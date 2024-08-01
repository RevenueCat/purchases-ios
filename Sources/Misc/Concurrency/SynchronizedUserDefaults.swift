//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SynchronizedUserDefaults.swift
//
//  Created by Nacho Soto on 11/20/21.

import Foundation

/// A `UserDefaults` wrapper to synchronize access and writes.

internal final class SynchronizedUserDefaults {

    private let userDefaults: UserDefaults
    private let queue: DispatchQueue

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.queue = DispatchQueue(label: "com.example.SynchronizedUserDefaultsQueue")
    }

    func read<T>(_ action: (UserDefaults) throws -> T) rethrows -> T {
        return try queue.sync {
            return try action(userDefaults)
        }
    }

    func write(_ action: (UserDefaults) throws -> Void) rethrows {
        try queue.sync {
            try action(userDefaults)
            userDefaults.synchronize()
        }
    }
}

extension SynchronizedUserDefaults: Sendable {}
