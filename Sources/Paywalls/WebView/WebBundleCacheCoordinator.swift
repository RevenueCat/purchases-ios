//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleCacheCoordinator.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/26.
//

import Foundation

/// Isolates web-view storage on identity change, then deletes retired stores later.
///
/// Logout only retires the current identifier and notifies live web views. Actual
/// `WKWebsiteDataStore` removal happens on a later main-thread pass (configure / foreground)
/// so `logOut` is not blocked on WebKit and in-use stores can be retried after they are released.
@_spi(Internal) public final class WebBundleCacheCoordinator {

    let retireCurrentStore: () -> Void
    let sweepPendingStores: () -> Void

    /// Creates a coordinator. Tests inject no-op closures; production uses ``shared``.
    public init(
        retireCurrentStore: @escaping () -> Void,
        sweepPendingStores: @escaping () -> Void = {}
    ) {
        self.retireCurrentStore = retireCurrentStore
        self.sweepPendingStores = sweepPendingStores
    }

    /// Production coordinator that retires identifiers on logout and sweeps on a later main-thread pass.
    public static let shared = WebBundleCacheCoordinator(
        retireCurrentStore: WebBundleCacheCoordinator.retireCurrentStoreAndNotify,
        sweepPendingStores: WebBundleCacheCoordinator.scheduleSweep
    )

    static func retireCurrentStoreAndNotify() {
        WebViewDataStoreIdentifierStore.retireCurrentIdentifier()

        Task {
            await WebBundleEventBus.shared.clearCache()
        }
    }

    static func scheduleSweep() {
        Task { @MainActor in
            await WebViewWebsiteDataStoreSweeper.sweepPendingStores()
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

}
