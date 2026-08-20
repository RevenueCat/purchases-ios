//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleCacheCoordinatorTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/26.
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class WebBundleCacheCoordinatorTests: TestCase {

    func testCacheClearRequestedRetiresTheCurrentIdentifier() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: makeCacheWarmer(),
            bus: bus,
            sweeper: NoOpSweeper()
        )
        let first = store.identifier()

        await bus.clearCache()

        withExtendedLifetime(coordinator) {
            XCTAssertEqual(store.pendingRemovalIdentifiers(), [first])
            XCTAssertNotEqual(store.identifier(), first)
        }
    }

    func testConsecutiveCacheClearsEachRetireTheCurrentIdentifier() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: makeCacheWarmer(),
            bus: bus,
            sweeper: NoOpSweeper()
        )

        let first = store.identifier()
        await bus.clearCache()

        let second = store.identifier()
        await bus.clearCache()

        withExtendedLifetime(coordinator) {
            XCTAssertEqual(store.pendingRemovalIdentifiers(), [first, second])
        }
    }

    func testCacheClearDoesNotCreateAnIdentifierWhenNoneExists() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: makeCacheWarmer(),
            bus: bus,
            sweeper: NoOpSweeper()
        )

        await bus.clearCache()

        withExtendedLifetime(coordinator) {
            XCTAssertTrue(store.pendingRemovalIdentifiers().isEmpty)
        }
    }

    func testReceivedAssetURLsDoNotRetireTheCurrentIdentifier() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: makeCacheWarmer(),
            bus: bus,
            sweeper: NoOpSweeper()
        )
        let identifier = store.identifier()
        let urls: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/a")!, checksum: nil)
        ]

        await bus.publish(urls)

        withExtendedLifetime(coordinator) {
            XCTAssertTrue(store.pendingRemovalIdentifiers().isEmpty)
            XCTAssertEqual(store.identifier(), identifier)
        }
    }

    func testCacheClearRequestedSweepsTheRetiredIdentifier() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let first = store.identifier()
        let swept = self.expectation(description: "sweep scheduled")
        var pendingAtSweep: Set<UUID>?
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: makeCacheWarmer(),
            bus: bus,
            sweeper: SweepProbe {
                pendingAtSweep = store.pendingRemovalIdentifiers()
                swept.fulfill()
            }
        )

        await bus.clearCache()

        await self.fulfillment(of: [swept], timeout: 1)
        XCTAssertEqual(pendingAtSweep, [first])
        withExtendedLifetime(coordinator) {}
    }

    func testReceivedAssetURLsPrewarmsUsingTheCurrentIdentifier() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let loaded = self.expectation(description: "URLs loaded")
        loaded.expectedFulfillmentCount = Self.urls.count
        let recorder = await LoadRecorder()
        let prewarmer = makeCacheWarmer { url, storeID in
            recorder.record(url: url, storeID: storeID)
            loaded.fulfill()
        }
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: prewarmer,
            bus: bus,
            sweeper: NoOpSweeper()
        )
        let identifier = store.identifier()
        let urls = Self.urls

        await bus.publish(urls)

        await self.fulfillment(of: [loaded], timeout: 1)
        let invocations = await recorder.invocations
        XCTAssertEqual(
            invocations,
            urls.map { .init(url: $0.url, storeID: identifier) }
        )
        withExtendedLifetime(coordinator) {}
    }

    func testReceivedAssetURLsDoesNotStartDuplicatePrewarms() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let started = self.expectation(description: "prewarm started")
        let duplicateStarted = self.expectation(description: "duplicate prewarm started")
        duplicateStarted.isInverted = true
        let gate = LoadGate()
        let recorder = await LoadRecorder()
        let prewarmer = makeCacheWarmer { url, storeID in
            let invocationCount = recorder.record(url: url, storeID: storeID)
            if invocationCount == 1 {
                started.fulfill()
            } else {
                duplicateStarted.fulfill()
            }
            await gate.wait()
        }
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: prewarmer,
            bus: bus,
            sweeper: NoOpSweeper()
        )
        let urls = [Self.urls[0]]

        await bus.publish(urls)
        await self.fulfillment(of: [started], timeout: 1)
        await bus.publish(urls)

        await self.fulfillment(of: [duplicateStarted], timeout: 0.05)
        let invocations = await recorder.invocations
        XCTAssertEqual(invocations.count, 1)

        await gate.open()
        withExtendedLifetime(coordinator) {}
    }

    func testReceivedAssetURLBatchesPrewarmInPublicationOrder() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let firstStarted = self.expectation(description: "first prewarm started")
        let secondStarted = self.expectation(description: "second prewarm started")
        let secondStartedOutOfOrder = self.expectation(description: "second prewarm started out of order")
        secondStartedOutOfOrder.isInverted = true
        let gate = LoadGate()
        let firstFinished: Atomic<Bool> = false
        let prewarmer = makeCacheWarmer { url, _ in
            switch url {
            case Self.urls[0].url:
                firstStarted.fulfill()
                await gate.wait()
                firstFinished.value = true
            case Self.urls[1].url:
                if firstFinished.value {
                    secondStarted.fulfill()
                } else {
                    secondStartedOutOfOrder.fulfill()
                }
            default:
                XCTFail("Unexpected URL: \(url)")
            }
        }
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: prewarmer,
            bus: bus,
            sweeper: NoOpSweeper()
        )

        await bus.publish([Self.urls[0]])
        await self.fulfillment(of: [firstStarted], timeout: 1)
        await bus.publish([Self.urls[1]])

        await self.fulfillment(of: [secondStartedOutOfOrder], timeout: 0.05)
        await gate.open()
        await self.fulfillment(of: [secondStarted], timeout: 1)

        withExtendedLifetime(coordinator) {}
    }

    func testEmptyEventAllowsCompletedPrewarmToBeStartedAgain() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let firstStarted = self.expectation(description: "first prewarm started")
        let secondStarted = self.expectation(description: "second prewarm started")
        let recorder = await LoadRecorder()
        let prewarmer = makeCacheWarmer { url, storeID in
            switch recorder.record(url: url, storeID: storeID) {
            case 1: firstStarted.fulfill()
            case 2: secondStarted.fulfill()
            default: break
            }
        }
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: prewarmer,
            bus: bus,
            sweeper: NoOpSweeper()
        )
        let urls = [Self.urls[0]]

        await bus.publish(urls)
        await self.fulfillment(of: [firstStarted], timeout: 1)
        await bus.empty()

        await bus.publish(urls)

        await self.fulfillment(of: [secondStarted], timeout: 1)
        let invocations = await recorder.invocations
        XCTAssertEqual(invocations.count, 2)

        withExtendedLifetime(coordinator) {}
    }

    func testCacheClearCancelsAndRemovesInFlightPrewarms() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let started = self.expectation(description: "prewarm started")
        let cancelled = self.expectation(description: "prewarm cancelled")
        let gate = LoadGate()
        let prewarmer = makeCacheWarmer { _, _ in
            started.fulfill()
            await gate.wait()
            if Task.isCancelled {
                cancelled.fulfill()
            }
        }
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            cacheWarmer: prewarmer,
            bus: bus,
            sweeper: NoOpSweeper()
        )
        let urls = [Self.urls[0]]

        await bus.publish(urls)
        await self.fulfillment(of: [started], timeout: 1)

        await bus.clearCache()
        await gate.open()

        await self.fulfillment(of: [cancelled], timeout: 1)

        withExtendedLifetime(coordinator) {}
    }

    private func makeStore() throws -> WebViewDataStoreIdentifierStore {
        let suiteName = "com.revenuecat.WebBundleCacheCoordinatorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock { [weak defaults] in
            defaults?.removePersistentDomain(forName: suiteName)
        }

        return WebViewDataStoreIdentifierStore(userDefaults: defaults)
    }

    private func makeCacheWarmer(
        load: @escaping @MainActor @Sendable (URL, UUID) async -> Void = { _, _ in }
    ) -> WebBundlePrewarmer {
        return WebBundlePrewarmer(load: load)
    }

    private static let urls: [URLWithValidation] = [
        .init(url: URL(string: "https://example.com/a")!, checksum: nil),
        .init(url: URL(string: "https://example.com/b")!, checksum: nil)
    ]

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class NoOpSweeper: WebViewDataStoreSweeping {

    func sweepStores() async {}

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
private final class LoadRecorder {

    struct Invocation: Equatable {
        let url: URL
        let storeID: UUID
    }

    private(set) var invocations: [Invocation] = []

    @discardableResult
    func record(url: URL, storeID: UUID) -> Int {
        self.invocations.append(.init(url: url, storeID: storeID))
        return self.invocations.count
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private actor LoadGate {

    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !self.isOpen else { return }

        await withCheckedContinuation { continuation in
            self.continuations.append(continuation)
        }
    }

    func open() {
        self.isOpen = true
        let continuations = self.continuations
        self.continuations = []
        continuations.forEach { $0.resume() }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class SweepProbe: WebViewDataStoreSweeping {

    private let onSweep: () -> Void

    init(onSweep: @escaping () -> Void) {
        self.onSweep = onSweep
    }

    func sweepStores() async {
        self.onSweep()
    }

}
