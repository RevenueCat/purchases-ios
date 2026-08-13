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

/// Persists the identifier for RevenueCat's isolated website data store.
@_spi(Internal) public enum WebViewDataStoreIdentifierStore {

    private static let currentKey = "com.revenuecat.webViewDataStoreIdentifier"
    private static let pendingKey = "com.revenuecat.webViewDataStorePendingRemovalIdentifiers"
    private static let lock = Lock()

    private static let defaults = UserDefaults.revenueCatSuite

    /// Returns the stable identifier used by RevenueCat web views.
    public static func identifier() -> UUID {
        return self.identifier(in: Self.defaults)
    }

    static func identifier(in userDefaults: UserDefaults) -> UUID {
        return Self.lock.perform {
            if let value = userDefaults.string(forKey: Self.currentKey),
               let identifier = UUID(uuidString: value) {
                return identifier
            }

            let identifier = UUID()
            userDefaults.set(identifier.uuidString, forKey: Self.currentKey)
            return identifier
        }
    }

    /// Moves the current identifier into the pending-removal set without creating one.
    @discardableResult
    static func retireCurrentIdentifier() -> UUID? {
        return self.retireCurrentIdentifier(in: Self.defaults)
    }

    @discardableResult
    static func retireCurrentIdentifier(in userDefaults: UserDefaults) -> UUID? {
        return Self.lock.perform {
            let current = userDefaults.string(forKey: Self.currentKey)
                .flatMap(UUID.init(uuidString:))
            userDefaults.removeObject(forKey: Self.currentKey)

            if let current {
                var pending = Self.pendingIdentifiersLocked(in: userDefaults)
                pending.insert(current)
                Self.setPendingIdentifiersLocked(pending, in: userDefaults)
            }

            return current
        }
    }

    static func pendingRemovalIdentifiers() -> Set<UUID> {
        return self.pendingRemovalIdentifiers(in: Self.defaults)
    }

    static func pendingRemovalIdentifiers(in userDefaults: UserDefaults) -> Set<UUID> {
        return Self.lock.perform {
            return Self.pendingIdentifiersLocked(in: userDefaults)
        }
    }

    /// Subtracts `identifiers` from the pending-removal set.
    /// IDs added after a sweep snapshot (for example by a concurrent logout) are preserved.
    static func removeFromPending(_ identifiers: Set<UUID>) {
        self.removeFromPending(identifiers, in: Self.defaults)
    }

    static func removeFromPending(_ identifiers: Set<UUID>, in userDefaults: UserDefaults) {
        guard !identifiers.isEmpty else { return }

        Self.lock.perform {
            var pending = Self.pendingIdentifiersLocked(in: userDefaults)
            pending.subtract(identifiers)
            Self.setPendingIdentifiersLocked(pending, in: userDefaults)
        }
    }

    private static func pendingIdentifiersLocked(in userDefaults: UserDefaults) -> Set<UUID> {
        let strings = userDefaults.stringArray(forKey: Self.pendingKey) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private static func setPendingIdentifiersLocked(_ identifiers: Set<UUID>, in userDefaults: UserDefaults) {
        if identifiers.isEmpty {
            userDefaults.removeObject(forKey: Self.pendingKey)
        } else {
            userDefaults.set(identifiers.map(\.uuidString), forKey: Self.pendingKey)
        }
    }

}
