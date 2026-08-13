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

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

import WebKit

#endif

final class WebViewWebsiteDataStoreSweeper {
    let idStore: WebViewDataStoreIdentifierStore

    init(idStore: WebViewDataStoreIdentifierStore = .init()) {
        self.idStore = idStore
    }

    @MainActor
    func sweepStores() async {
        let pending = idStore.pendingRemovalIdentifiers()
        guard !pending.isEmpty else { return }

        #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let existing = Set(await WKWebsiteDataStore.allDataStoreIdentifiers)
            let remaining = await Self.sweep(
                pending: pending,
                existing: existing,
                remove: { identifier in
                    await Self.removeStore(for: identifier)
                }
            )
            // Subtract only IDs this pass cleared. Replacing the set would drop IDs
            // retired during the WebKit awaits (logout / overlapping sweeps).
            idStore.removeFromPending(pending.subtracting(remaining))
            return
        }
        #endif

        idStore.removeFromPending(pending)
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

    #if !os(tvOS) && !os(watchOS) && canImport(WebKit)

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    private static func removeStore(for identifier: UUID) async -> Bool {
        do {
            try await WKWebsiteDataStore.remove(forIdentifier: identifier)
            return true
        } catch {
            // Logger.debug(Strings.paywalls.web_view_data_store_removal_failed(identifier, error))
            return false
        }
    }

    #endif

}
