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

/// A ``UserDefaults`` wrapper to synchronize access and writes.
///
/// - Seealso: ``Atomic``.
internal class SynchronizedUserDefaults {

    private let atomic: Atomic<UserDefaults>

    init(userDefaults: UserDefaults) {
        self.atomic = .init(userDefaults)
    }

    func perform<T>(_ action: (UserDefaults) throws -> T) rethrows -> T {
        return try self.atomic.withValue {
            return try action($0)
        }
    }

}
