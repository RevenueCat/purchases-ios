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

@preconcurrency import Combine
@_spi(Internal) import RevenueCat

/// Isolates web-view storage on cache clear request, then deletes retired stores later.
final class WebBundleCacheCoordinator {

    private let store: WebViewDataStoreIdentifierStore
    private let sweeper: any WebViewDataStoreSweeping
    private let bus: WebBundleEventBus
    private var job: AnyCancellable?

    init(
        store: WebViewDataStoreIdentifierStore,
        bus: WebBundleEventBus
    ) {
        self.store = store
        self.sweeper = WebViewWebsiteDataStoreSweeper(store: store)
        self.bus = bus
        self.setUpSubscription()
    }

    #if DEBUG
    // Test Initializer -- invoking webkit apis in the unit test suite results in bad memory crashes
    init(
        store: WebViewDataStoreIdentifierStore,
        bus: WebBundleEventBus,
        sweeper: any WebViewDataStoreSweeping
    ) {
        self.store = store
        self.sweeper = sweeper
        self.bus = bus
        self.setUpSubscription()
    }
    #endif

    /// Production coordinator that retires identifiers and sweeps on a later main-thread pass.
    static let shared = WebBundleCacheCoordinator(store: .init(), bus: .shared)

    @MainActor
    private func scheduleSweep() async {
        await self.sweeper.sweepStores()
    }

    private func setUpSubscription() {
        self.job = bus.publisher.sink { [weak self] event in
            guard let self else { return }

            switch event {
            case .cacheClearRequested:
                self.store.retireCurrentIdentifier()
                Task(priority: .medium) {
                    // Allow other UI work to go through before we start destroying caches
                    await self.scheduleSweep()
                }
            case .receivedAssetURLs:
                break // will do in upcoming PRs
            case .empty:
                break
            }
        }
    }

}
