//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewWebsiteDataStoreSweeper.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/26.
//

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

import WebKit

#endif

protocol WebViewDataStoreSweeping: AnyObject {

    @MainActor
    func sweepStores() async

}

final class WebViewWebsiteDataStoreSweeper: WebViewDataStoreSweeping {

    private let idStore: WebViewDataStoreIdentifierStore
    private let existingIdentifiers: @MainActor () async -> Set<UUID>
    private let remove: @MainActor (UUID) async -> Bool

    init(
        idStore: WebViewDataStoreIdentifierStore = .init(),
        existingIdentifiers: (@MainActor () async -> Set<UUID>)? = nil,
        remove: (@MainActor (UUID) async -> Bool)? = nil
    ) {
        self.idStore = idStore
        self.existingIdentifiers = existingIdentifiers ?? Self.loadExistingIdentifiers
        self.remove = remove ?? Self.removeStore(for:)
    }

    @MainActor
    func sweepStores() async {
        let pending = self.idStore.pendingRemovalIdentifiers()
        guard !pending.isEmpty else { return }

        let existing = await self.existingIdentifiers()
        let remaining = await Self.sweep(
            pending: pending,
            existing: existing,
            remove: self.remove
        )
        // Subtract only IDs this pass cleared. Replacing the set would drop IDs
        // retired during the WebKit awaits (logout / overlapping sweeps).
        self.idStore.removeFromPending(pending.subtracting(remaining))
    }

    /// Drops pending IDs whose stores are already gone. Only calls `remove` for IDs that still exist.
    /// Failed removals stay pending so they can be retried later.
    static func sweep(
        pending: Set<UUID>,
        existing: Set<UUID>,
        remove: @MainActor (UUID) async -> Bool
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
    private static func loadExistingIdentifiers() async -> Set<UUID> {
        #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            return Set(await WKWebsiteDataStore.allDataStoreIdentifiers)
        }
        #endif

        return []
    }

    @MainActor
    private static func removeStore(for identifier: UUID) async -> Bool {
        #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            do {
                try await WKWebsiteDataStore.remove(forIdentifier: identifier)
                return true
            } catch {
                Logger.debug(Strings.web_view_data_store_removal_failed(identifier, error))
                return false
            }
        }
        #endif

        return true
    }

}
