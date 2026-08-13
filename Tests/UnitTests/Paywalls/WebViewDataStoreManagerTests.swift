//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewDataStoreManagerTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/26.
//

import Combine
@_spi(Internal) @testable import RevenueCat
import XCTest

final class WebViewDataStoreManagerTests: TestCase {

    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        self.cancellables = []
        super.tearDown()
    }

    func testIdentifierIsGeneratedOnceAndPersisted() throws {
        let manager = try self.makeManager()

        let firstIdentifier = manager.currentIdentifier()
        let secondIdentifier = manager.currentIdentifier()

        XCTAssertEqual(firstIdentifier, secondIdentifier)
    }

    func testRetiringIdentifierEnqueuesItAndRotatesOnNextUse() throws {
        let manager = try self.makeManager()
        let firstIdentifier = manager.currentIdentifier()

        manager.retireCurrentStore()

        XCTAssertEqual(manager.pendingRemovalIdentifiers(), [firstIdentifier])
        XCTAssertNotEqual(manager.currentIdentifier(), firstIdentifier)
    }

    func testRetireDoesNotCreateAnIdentifierWhenNoneExists() throws {
        let manager = try self.makeManager()

        var received = 0
        manager.storeRetired
            .sink { received += 1 }
            .store(in: &self.cancellables)

        manager.retireCurrentStore()

        XCTAssertTrue(manager.pendingRemovalIdentifiers().isEmpty)
        XCTAssertEqual(received, 0)
    }

    func testMultipleRetiresAccumulatePendingIdentifiers() throws {
        let manager = try self.makeManager()

        let first = manager.currentIdentifier()
        manager.retireCurrentStore()
        let second = manager.currentIdentifier()
        manager.retireCurrentStore()

        XCTAssertEqual(manager.pendingRemovalIdentifiers(), [first, second])
    }

    func testRemoveFromPendingSubtractsWithoutReplacingTheSet() throws {
        let manager = try self.makeManager()

        let first = manager.currentIdentifier()
        manager.retireCurrentStore()
        let second = manager.currentIdentifier()
        manager.retireCurrentStore()

        manager.removeFromPending([first])

        XCTAssertEqual(manager.pendingRemovalIdentifiers(), [second])
    }

    func testRemoveFromPendingPreservesIdentifiersAddedAfterSnapshot() throws {
        let manager = try self.makeManager()

        let first = manager.currentIdentifier()
        manager.retireCurrentStore()
        let second = manager.currentIdentifier()
        manager.retireCurrentStore()

        let snapshot = manager.pendingRemovalIdentifiers()

        let third = manager.currentIdentifier()
        manager.retireCurrentStore()

        let remainingAfterSweep: Set<UUID> = [second]
        manager.removeFromPending(snapshot.subtracting(remainingAfterSweep))

        XCTAssertEqual(manager.pendingRemovalIdentifiers(), [second, third])
        XCTAssertFalse(manager.pendingRemovalIdentifiers().contains(first))
    }

    func testStoreRetiredFiresOnRetire() throws {
        let manager = try self.makeManager()
        _ = manager.currentIdentifier()

        var received = 0
        manager.storeRetired
            .sink { received += 1 }
            .store(in: &self.cancellables)

        manager.retireCurrentStore()

        XCTAssertEqual(received, 1)
    }

    func testLateSubscriberDoesNotReceivePriorRetire() throws {
        let manager = try self.makeManager()
        _ = manager.currentIdentifier()
        manager.retireCurrentStore()

        var received = 0
        manager.storeRetired
            .sink { received += 1 }
            .store(in: &self.cancellables)

        XCTAssertEqual(received, 0)
    }

    func testMultipleSubscribersReceiveTheSameRetirePulse() throws {
        let manager = try self.makeManager()
        _ = manager.currentIdentifier()

        var firstReceived = 0
        var secondReceived = 0
        manager.storeRetired
            .sink { firstReceived += 1 }
            .store(in: &self.cancellables)
        manager.storeRetired
            .sink { secondReceived += 1 }
            .store(in: &self.cancellables)

        manager.retireCurrentStore()

        XCTAssertEqual(firstReceived, 1)
        XCTAssertEqual(secondReceived, 1)
    }

    func testSweepRemovesIdentifiersThatExistAndWereDeleted() async {
        let first = UUID()
        let second = UUID()
        var removed: [UUID] = []

        let remaining = await WebViewDataStoreManager.sweep(
            pending: [first, second],
            existing: [first, second],
            remove: { identifier in
                removed.append(identifier)
                return true
            }
        )

        XCTAssertEqual(Set(removed), [first, second])
        XCTAssertTrue(remaining.isEmpty)
    }

    func testSweepKeepsIdentifiersWhenRemoveFails() async {
        let identifier = UUID()

        let remaining = await WebViewDataStoreManager.sweep(
            pending: [identifier],
            existing: [identifier],
            remove: { _ in false }
        )

        XCTAssertEqual(remaining, [identifier])
    }

    func testSweepDropsMissingIdentifiersWithoutCallingRemove() async {
        let identifier = UUID()
        var removeCalled = false

        let remaining = await WebViewDataStoreManager.sweep(
            pending: [identifier],
            existing: [],
            remove: { _ in
                removeCalled = true
                return true
            }
        )

        XCTAssertFalse(removeCalled)
        XCTAssertTrue(remaining.isEmpty)
    }

    private func makeManager() throws -> WebViewDataStoreManager {
        let suiteName = "com.revenuecat.WebViewDataStoreManagerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock { [weak defaults] in
            defaults?.removePersistentDomain(forName: suiteName)
        }

        return WebViewDataStoreManager(userDefaults: defaults)
    }

}
