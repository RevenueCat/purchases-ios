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
final class WebViewDataStoreIdentifierStore {
    let userDefualts: UserDefaults

    init(userDefualts: UserDefaults = WebViewDataStoreIdentifierStore.defaults) {
        self.userDefualts = userDefualts
    }

    /// Returns the stable identifier used by RevenueCat web views.
    public func identifier() -> UUID {
        return Self.identifier(in: userDefualts)
    }

    /// Moves the current identifier into the pending-removal set without creating one.
    @discardableResult
    func retireCurrentIdentifier() -> UUID? {
        return Self.retireCurrentIdentifier(in: userDefualts)
    }

    func pendingRemovalIdentifiers() -> Set<UUID> {
        return Self.pendingRemovalIdentifiers(in: userDefualts)
    }

    /// Subtracts `identifiers` from the pending-removal set.
    /// IDs added after a sweep snapshot (for example by a concurrent logout) are preserved.
    func removeFromPending(_ identifiers: Set<UUID>) {
        Self.removeFromPending(identifiers, in: userDefualts)
    }

}

extension WebViewDataStoreIdentifierStore {

    // swiftlint:disable:next force_unwrapping
    static let defaults = UserDefaults(suiteName: "com.revenuecat.webViewIDStore")!

    private static let currentKey = "com.revenuecat.webViewDataStoreIdentifier"
    private static let pendingKey = "com.revenuecat.webViewDataStorePendingRemovalIdentifiers"
    private static let lock = NSLock()

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

    static func pendingRemovalIdentifiers(in userDefaults: UserDefaults) -> Set<UUID> {
        return Self.lock.perform {
            return Self.pendingIdentifiersLocked(in: userDefaults)
        }
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

    static func removeFromPending(_ identifiers: Set<UUID>, in userDefaults: UserDefaults) {
        guard !identifiers.isEmpty else { return }

        Self.lock.perform {
            var pending = Self.pendingIdentifiersLocked(in: userDefaults)
            pending.subtract(identifiers)
            Self.setPendingIdentifiersLocked(pending, in: userDefaults)
        }
    }
}

extension NSLock {

    @discardableResult
    func perform<T>(_ block: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try block()
        }

        lock()
        defer { unlock() }
        return try block()
    }
}
