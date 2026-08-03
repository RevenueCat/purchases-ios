//
//  ForceServerErrorStrategyStore.swift
//  Maestro
//
//  Created by Antonio Pallares on 7/30/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// The strategy the SDK's force-error hook consults on every request.
///
/// The strategy is kept here rather than read back from `UserDefaults` so that E2E tests can change it
/// mid-session: launch arguments land in the volatile argument domain, which shadows the standard
/// domain, so a write would be ignored for any flow launched with `force_server_error_strategy` set.
enum ForceServerErrorStrategyStore {

    private static let lock = NSLock()
    private static var strategy = Constants.forceServerErrorStrategy

    /// Read from network threads by the force-error hook, so every access is serialized.
    static var current: Constants.ForceServerErrorStrategy {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.strategy
    }

    static func update(to strategy: Constants.ForceServerErrorStrategy) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.strategy = strategy
    }

}
