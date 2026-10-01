//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewDataStoreIdentifierStore.swift
//
//  Created by Jacob Zivan Rakidzich on 8/10/26.
//

import Foundation

/// Persists the identifiers for RevenueCat's isolated website data store.
@_spi(Internal) public final class WebViewDataStoreIdentifierStore {

    /// Process-wide store shared by web-bundle prewarming, rendering, and cleanup.
    @_spi(Internal) public static let shared = WebViewDataStoreIdentifierStore()

    private let userDefaults: SynchronizedUserDefaults

    /// Creates a store that reads and writes identifiers in the default suite.
    @_spi(Internal) public convenience init() {
        self.init(userDefaults: Self.defaults)
    }

    /// Creates a store that reads and writes identifiers in `userDefaults`.
    @_spi(Internal) public init(userDefaults: UserDefaults) {
        self.userDefaults = SynchronizedUserDefaults(userDefaults: userDefaults)
    }

    /// Returns the stable identifier used by RevenueCat web views.
    @_spi(Internal) public func identifier() -> UUID {
        if let existing = self.currentIdentifier() {
            return existing
        }

        return self.createIdentifier()
    }

    /// Moves the current identifier into the pending-removal set without creating one.
    @discardableResult
    @_spi(Internal) public func retireCurrentIdentifier() -> UUID? {
        var retired: UUID?
        self.userDefaults.write { defaults in
            let current = defaults.string(forKey: Self.currentKey)
                .flatMap(UUID.init(uuidString:))
            defaults.removeObject(forKey: Self.currentKey)

            if let current {
                var pending = Self.pendingIdentifiers(in: defaults)
                pending.insert(current)
                Self.setPendingIdentifiers(pending, in: defaults)
            }

            retired = current
        }
        return retired
    }

    /// Identifiers whose website data stores still need to be deleted.
    @_spi(Internal) public func pendingRemovalIdentifiers() -> Set<UUID> {
        return self.userDefaults.read { defaults in
            return Self.pendingIdentifiers(in: defaults)
        }
    }

    /// Subtracts `identifiers` from the pending-removal set.
    /// IDs added after a sweep snapshot (for example by a concurrent logout) are preserved.
    @_spi(Internal) public func removeFromPending(_ identifiers: Set<UUID>) {
        guard !identifiers.isEmpty else { return }

        self.userDefaults.write { defaults in
            var pending = Self.pendingIdentifiers(in: defaults)
            pending.subtract(identifiers)
            Self.setPendingIdentifiers(pending, in: defaults)
        }
    }

}

extension WebViewDataStoreIdentifierStore {

    // swiftlint:disable:next force_unwrapping
    static let defaults = UserDefaults(suiteName: "com.revenuecat.webViewIDStore")!

    private static let currentKey = "com.revenuecat.webViewDataStoreIdentifier"
    private static let pendingKey = "com.revenuecat.webViewDataStorePendingRemovalIdentifiers"

    private func currentIdentifier() -> UUID? {
        return self.userDefaults.read { defaults in
            return defaults.string(forKey: Self.currentKey).flatMap(UUID.init(uuidString:))
        }
    }

    private func createIdentifier() -> UUID {
        let created = UUID()
        var result = created
        self.userDefaults.write { defaults in
            if let value = defaults.string(forKey: Self.currentKey),
               let current = UUID(uuidString: value) {
                result = current
                return
            }

            defaults.set(created.uuidString, forKey: Self.currentKey)
        }
        return result
    }

    private static func pendingIdentifiers(in userDefaults: UserDefaults) -> Set<UUID> {
        let strings = userDefaults.stringArray(forKey: Self.pendingKey) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private static func setPendingIdentifiers(_ identifiers: Set<UUID>, in userDefaults: UserDefaults) {
        if identifiers.isEmpty {
            userDefaults.removeObject(forKey: Self.pendingKey)
        } else {
            userDefaults.set(identifiers.map(\.uuidString), forKey: Self.pendingKey)
        }
    }

}
