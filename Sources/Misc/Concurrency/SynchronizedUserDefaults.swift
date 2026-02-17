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

/// A `UserDefaults` wrapper that provides a consistent API for reading and writing.
///
/// `UserDefaults` is already thread-safe according to Apple's documentation:
/// "The UserDefaults type is thread-safe, and you can use the same object in multiple threads or tasks
/// simultaneously."
/// https://developer.apple.com/documentation/foundation/userdefaults#overview
///
/// This wrapper previously used a lock (`Atomic`) for synchronization, but this caused deadlocks
/// in scenarios where:
/// 1. Main thread tries to acquire the lock for a read operation
/// 2. A background thread holding the lock writes to UserDefaults, which posts
///    a `didChangeNotification` to the main queue
/// 3. The background thread waits for the notification to complete
/// 4. Deadlock: main thread waiting for lock, background thread waiting for main thread
///
/// Since `UserDefaults` handles thread-safety internally, we no longer wrap it with additional locking.
///
/// - SeeAlso: https://github.com/RevenueCat/purchases-ios/issues/4137
/// - SeeAlso: https://github.com/RevenueCat/purchases-ios/issues/5729
internal final class SynchronizedUserDefaults {

    private nonisolated(unsafe) let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func read<T>(_ action: (UserDefaults) throws -> T) rethrows -> T {
        return try action(self.userDefaults)
    }

    func write(_ action: (UserDefaults) throws -> Void) rethrows {
        try action(self.userDefaults)

        // While Apple states `this method is unnecessary and shouldn't be used`
        // https://developer.apple.com/documentation/foundation/userdefaults/1414005-synchronize
        // It didn't become unnecessary until iOS 12 and macOS 10.14 (Mojave):
        // https://developer.apple.com/documentation/macos-release-notes/foundation-release-notes
        // there are reports it is still needed if you save to defaults then immediately kill the app.
        // Also, it has not been marked deprecated... yet.
        self.userDefaults.synchronize()
    }

}

extension SynchronizedUserDefaults: Sendable {}

/// A `UserDefaults` wrapper that uses a lock to synchronize access.
///
/// This is the original implementation that provides thread-safe read-modify-write operations.
/// Use this for operations that need atomicity (e.g., subscriber attributes).
///
/// - Warning: This can cause deadlocks in scenarios where the main thread is waiting for the lock
///   while a background thread holds it and writes to UserDefaults (which posts `didChangeNotification`
///   to the main queue). Use `SynchronizedUserDefaults` for simple read/write operations that don't
///   require atomicity.
///
/// - SeeAlso: `SynchronizedUserDefaults` for a lock-free alternative.
/// - SeeAlso: https://github.com/RevenueCat/purchases-ios/issues/4137
internal final class LockingSynchronizedUserDefaults {

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

extension LockingSynchronizedUserDefaults: Sendable {}
