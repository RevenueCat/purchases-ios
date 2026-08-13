//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewDataStoreManager.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/26.
//

@preconcurrency import Combine
import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

import WebKit

#endif

/// Isolates web-view storage on message receipt, then deletes retired stores later.
@_spi(Internal) public final class WebViewDataStoreManager {

    /// Shared manager backed by the SDK's UserDefaults suite.
    public static let shared = WebViewDataStoreManager(userDefaults: .revenueCatSuite)

    /// Fires when the current store is retired. Late subscribers receive nothing.
    public let storeRetired: AnyPublisher<Void, Never>

    private let userDefaults: UserDefaults
    private let lock = NSLock()
    private let storeRetiredSubject = PassthroughSubject<Void, Never>()
    private var _isSweeping: Bool = false
    private var isSweeping: Bool {
        get {
            lock.withLock {
                return _isSweeping
            }
        }
        set {
            lock.withLock {
                self._isSweeping = newValue
            }
        }
    }

    private static let currentKey = "com.revenuecat.webViewDataStoreIdentifier"
    private static let pendingKey = "com.revenuecat.webViewDataStorePendingRemovalIdentifiers"

    /// Creates a manager that persists identifiers in `userDefaults`.
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.storeRetired = self.storeRetiredSubject.eraseToAnyPublisher()
    }

    /// Stable identifier for the current store; creates and persists one on first use.
    public func currentIdentifier() -> UUID {
        return self.lock.withLock {
            if let value = self.userDefaults.string(forKey: Self.currentKey),
               let identifier = UUID(uuidString: value) {
                return identifier
            }

            let identifier = UUID()
            self.userDefaults.set(identifier.uuidString, forKey: Self.currentKey)
            return identifier
        }
    }

    /// Moves the current identifier (if any) into the pending-removal set and fires `storeRetired`.
    /// Does not create an identifier.
    public func retireCurrentStore() {
        let retired = self.lock.withLock { () -> UUID? in
            let current = self.userDefaults.string(forKey: Self.currentKey)
                .flatMap(UUID.init(uuidString:))
            self.userDefaults.removeObject(forKey: Self.currentKey)

            if let current {
                var pending = self.pendingIdentifiersLocked()
                pending.insert(current)
                self.setPendingIdentifiersLocked(pending)
            }

            return current
        }

        guard retired != nil else { return }
        self.storeRetiredSubject.send(())
    }

    /// Schedules async deletion of pending stores on the main actor.
    /// Failed removals stay pending for a later pass.
    public func sweepPendingStores() {
        if isSweeping { return }
        isSweeping = true

        Task { @MainActor [weak self] in
            defer { self?.isSweeping = false }
            await self?.performSweep()
        }
    }

    func pendingRemovalIdentifiers() -> Set<UUID> {
        return self.lock.withLock {
            return self.pendingIdentifiersLocked()
        }
    }

    /// Subtracts `identifiers` from the pending-removal set.
    /// IDs added after a sweep snapshot (for example by a concurrent logout) are preserved.
    func removeFromPending(_ identifiers: Set<UUID>) {
        guard !identifiers.isEmpty else { return }

        self.lock.withLock {
            var pending = self.pendingIdentifiersLocked()
            pending.subtract(identifiers)
            self.setPendingIdentifiersLocked(pending)
        }
    }

    /// Drops pending IDs whose stores are already gone. Only calls `remove` for IDs that still exist.
    /// Failed removals stay pending so they can be retried later.
    static func sweep(
        pending: Set<UUID>,
        existing: Set<UUID>,
        remove: (UUID) async -> Bool
    ) async -> Set<UUID> {
        var remaining = pending

        for identifier in pending {
            if !existing.contains(identifier) {
                remaining.remove(identifier)
                continue
            }

            if await remove(identifier) {
                remaining.remove(identifier)
            }
        }

        return remaining
    }

    @MainActor
    private func performSweep() async {
        let pending = self.pendingRemovalIdentifiers()
        guard !pending.isEmpty else { return }

        #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let existing = Set(await WKWebsiteDataStore.allDataStoreIdentifiers)
            let remaining = await Self.sweep(
                pending: pending,
                existing: existing,
                remove: { identifier in
                    await self.removeStore(for: identifier)
                }
            )
            // Subtract only IDs this pass cleared. Replacing the set would drop IDs
            // retired during the WebKit awaits (logout / overlapping sweeps).
            self.removeFromPending(pending.subtracting(remaining))
            return
        }
        #endif

        self.removeFromPending(pending)
    }

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    private func removeStore(for identifier: UUID) async -> Bool {
        do {
            try await WKWebsiteDataStore.remove(forIdentifier: identifier)
            return true
        } catch {
//            Logger.debug(Strings.paywalls.web_view_data_store_removal_failed(identifier, error))
            return false
        }
    }

#endif

    private func pendingIdentifiersLocked() -> Set<UUID> {
        let strings = self.userDefaults.stringArray(forKey: Self.pendingKey) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private func setPendingIdentifiersLocked(_ identifiers: Set<UUID>) {
        if identifiers.isEmpty {
            self.userDefaults.removeObject(forKey: Self.pendingKey)
        } else {
            self.userDefaults.set(identifiers.map(\.uuidString), forKey: Self.pendingKey)
        }
    }

}
