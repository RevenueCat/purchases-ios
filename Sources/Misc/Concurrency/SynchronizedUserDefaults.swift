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
///
/// - SeeAlso: `Atomic`.
internal final class SynchronizedUserDefaults {

    private let atomic: Atomic<UserDefaults>

    init(userDefaults: UserDefaults) {
        self.atomic = .init(userDefaults)
    }

    func read<T>(_ action: (UserDefaults) throws -> T) rethrows -> T {
        return try self.atomic.withValue {
            return try action($0)
        }
    }

    func write(_ action: (UserDefaults) throws -> Void) rethrows {
        return try self.atomic.withValue {
            try action($0)

            // While Apple states `this method is unnecessary and shouldn't be used`
            // https://developer.apple.com/documentation/foundation/userdefaults/1414005-synchronize
            // It didn't become unnecessary until iOS 12 and macOS 10.14 (Mojave):
            // https://developer.apple.com/documentation/macos-release-notes/foundation-release-notes
            // there are reports it is still needed if you save to defaults then immediately kill the app.
            // Also, it has not been marked deprecated... yet.
            $0.synchronize()
        }
    }

}

extension SynchronizedUserDefaults: Sendable {}
