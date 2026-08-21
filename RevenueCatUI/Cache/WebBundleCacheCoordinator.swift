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
    private let taskQueue = WebBundleTaskQueue()
    private let prewarmDeduplicator = WebBundlePrewarmDeduplicator()
    private var job: AnyCancellable?

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
        self.job = bus.publisher
            .removeDuplicates(by: { previous, current in
                guard case let .receivedAssetURLs(previousURLs) = previous,
                      case let .receivedAssetURLs(currentURLs) = current else {
                    return false
                }

                return previousURLs == currentURLs
            })
            .sink { [weak self] event in
                guard let self else { return }

                switch event {
                case .cacheClearRequested:
                    self.store.retireCurrentIdentifier()
                    self.prewarmDeduplicator.clear()
                    self.taskQueue.cancelAll {
                        Task { await self.scheduleSweep() }
                    }
                case .receivedAssetURLs(let urls):
                    let id = self.store.identifier()
                    let urlsToLoad = urls.filter { self.prewarmDeduplicator.insert($0) }
                    self.taskQueue.add { [weak self] in
                        guard let self else { return }
                        await self.cacheWarmer.prewarm(urlsToLoad, storeID: id)
                    }
                case .empty:
                    break
                @unknown default:
                    break
                }
            }
    }

}

/// Runs prewarm operations in insertion order and synchronously tracks their tasks for cancellation.
private final class WebBundleTaskQueue: @unchecked Sendable {

    private struct Entry {
        let id: UUID
        let task: Task<Void, Never>
    }

    private let queue = DispatchQueue(label: "com.revenuecat.web-bundle-task-cache")
    private var tasks: [Entry] = []

    func add(_ operation: @escaping @Sendable () async -> Void) {
        self.queue.sync {
            let id = UUID()
            let previousTask = self.tasks.last?.task
            let task = Task { [weak self] in
                defer { self?.removeTask(withID: id) }
                await previousTask?.value
                guard !Task.isCancelled else { return }
                await operation()
            }
            self.tasks.append(.init(id: id, task: task))
        }
    }

    func cancelAll(completion: @escaping () -> Void) {
        self.queue.sync {
            self.tasks.forEach { $0.task.cancel() }
            Task {
                waitForQueueToEmpty()
                completion()
            }
        }
    }

    private func waitForQueueToEmpty() {
        let deadline = Date().addingTimeInterval(2)
        while !tasks.isEmpty, Date() < deadline {
            continue
        }
        if !tasks.isEmpty {
            Logger.debug(Strings.web_view_cache_queue_ejection_exceeded_deadline)
        }
    }

    private func removeTask(withID id: UUID) {
        self.queue.async {
            self.tasks.removeAll { $0.id == id }
        }
    }

}

private final class WebBundlePrewarmDeduplicator {
    private var urls: Set<URLWithValidation> = Set()
    private let lock: NSLock = .init()
    init() { }

    func insert(_ url: URLWithValidation) -> Bool {
        return lock.withLock {
            urls.insert(url).inserted
        }
    }

    func clear() {
        lock.withLock {
            urls.removeAll()
        }
    }
}
