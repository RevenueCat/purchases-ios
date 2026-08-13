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
        let coordinator = WebBundleCacheCoordinator(store: store, bus: bus, sweeper: NoOpSweeper())
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
        let coordinator = WebBundleCacheCoordinator(store: store, bus: bus, sweeper: NoOpSweeper())

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
        let coordinator = WebBundleCacheCoordinator(store: store, bus: bus, sweeper: NoOpSweeper())

        await bus.clearCache()

        withExtendedLifetime(coordinator) {
            XCTAssertTrue(store.pendingRemovalIdentifiers().isEmpty)
        }
    }

    func testReceivedAssetURLsDoNotRetireTheCurrentIdentifier() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let coordinator = WebBundleCacheCoordinator(store: store, bus: bus, sweeper: NoOpSweeper())
        let identifier = store.identifier()
        let urls: Set<URLWithValidation> = [
            .init(url: URL(string: "https://example.com/a")!, checksum: nil)
        ]

        await bus.publish(urls)

        withExtendedLifetime(coordinator) {
            XCTAssertTrue(store.pendingRemovalIdentifiers().isEmpty)
            XCTAssertEqual(store.identifier(), identifier)
        }
    }

    func testCacheClearRequestedSchedulesASweep() async throws {
        let store = try self.makeStore()
        let bus = WebBundleEventBus()
        let swept = self.expectation(description: "sweep scheduled")
        let coordinator = WebBundleCacheCoordinator(
            store: store,
            bus: bus,
            sweeper: SweepProbe { swept.fulfill() }
        )
        store.identifier()

        await bus.clearCache()

        await self.fulfillment(of: [swept], timeout: 1)
        XCTAssertNotNil(coordinator.job)
    }

    private func makeStore() throws -> WebViewDataStoreIdentifierStore {
        let suiteName = "com.revenuecat.WebBundleCacheCoordinatorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock { [weak defaults] in
            defaults?.removePersistentDomain(forName: suiteName)
        }

        return WebViewDataStoreIdentifierStore(userDefaults: defaults)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class NoOpSweeper: WebViewDataStoreSweeping {

    func sweepStores() async {}

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
