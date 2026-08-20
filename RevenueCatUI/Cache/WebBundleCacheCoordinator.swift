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

import Combine
import Foundation
@_spi(Internal) import RevenueCat

/// Isolates web-view storage on cache clear request, then deletes retired stores later.
final class WebBundleCacheCoordinator {

    private let store: WebViewDataStoreIdentifierStore
    private let sweeper: any WebViewDataStoreSweeping
    private let cacheWarmer: WebBundlePrewarmer
    private let bus: WebBundleEventBus
    private var job: AnyCancellable?
    private(set) var inFlightTasks = [[URLWithValidation]: Task<Void, Never>]()

    init(
        store: WebViewDataStoreIdentifierStore,
        cacheWarmer: WebBundlePrewarmer,
        bus: WebBundleEventBus
    ) {
        self.store = store
        self.sweeper = WebViewWebsiteDataStoreSweeper(store: store)
        self.cacheWarmer = cacheWarmer
        self.bus = bus
        self.setUpSubscription()
    }

    #if DEBUG
    // Test Initializer -- invoking webkit apis in the unit test suite results in bad memory crashes
    init(
        store: WebViewDataStoreIdentifierStore,
        cacheWarmer: WebBundlePrewarmer,
        bus: WebBundleEventBus,
        sweeper: any WebViewDataStoreSweeping
    ) {
        self.store = store
        self.sweeper = sweeper
        self.cacheWarmer = cacheWarmer
        self.bus = bus
        self.setUpSubscription()
    }
    #endif

    /// Production coordinator that retires identifiers and sweeps on a later main-thread pass.
    static let shared = WebBundleCacheCoordinator(store: .init(), cacheWarmer: .init(), bus: .shared)

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
                    await self.scheduleSweep()
                }
                self.inFlightTasks.values.forEach {
                    $0.cancel()
                }
                self.inFlightTasks = [:]
            case .receivedAssetURLs(let urls):
                if inFlightTasks[urls] == nil {
                    let id = self.store.identifier()
                    inFlightTasks[urls] = Task { [weak self] in
                        defer { self?.inFlightTasks[urls] = nil }
                        await self?.cacheWarmer.prewarm(urls, storeID: id)
                    }
                }
            case .empty:
                break
            }
        }
    }

}
