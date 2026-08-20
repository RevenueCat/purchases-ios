//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewDataStoreIdentifierStoreTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/26.
//

@_spi(Internal) @testable import RevenueCat
import XCTest

final class WebViewDataStoreIdentifierStoreTests: TestCase {

    func testIdentifierIsGeneratedOnceAndPersisted() throws {
        let store = try self.makeStore()

        let firstIdentifier = store.identifier()
        let secondIdentifier = store.identifier()

        XCTAssertEqual(firstIdentifier, secondIdentifier)
    }

    func testRetiringIdentifierEnqueuesItAndRotatesOnNextUse() throws {
        let store = try self.makeStore()
        let firstIdentifier = store.identifier()

        store.retireCurrentIdentifier()

        XCTAssertEqual(store.pendingRemovalIdentifiers(), [firstIdentifier])
        XCTAssertNotEqual(store.identifier(), firstIdentifier)
    }

    func testRetireDoesNotCreateAnIdentifierWhenNoneExists() throws {
        let store = try self.makeStore()

        let retired = store.retireCurrentIdentifier()

        XCTAssertNil(retired)
        XCTAssertTrue(store.pendingRemovalIdentifiers().isEmpty)
    }

    func testMultipleRetiresAccumulatePendingIdentifiers() throws {
        let store = try self.makeStore()

        let first = store.identifier()
        store.retireCurrentIdentifier()
        let second = store.identifier()
        store.retireCurrentIdentifier()

        XCTAssertEqual(store.pendingRemovalIdentifiers(), [first, second])
    }

    func testRemoveFromPendingSubtractsWithoutReplacingTheSet() throws {
        let store = try self.makeStore()

        let first = store.identifier()
        store.retireCurrentIdentifier()
        let second = store.identifier()
        store.retireCurrentIdentifier()

        store.removeFromPending([first])

        XCTAssertEqual(store.pendingRemovalIdentifiers(), [second])
    }

    func testRemoveFromPendingPreservesIdentifiersAddedAfterSnapshot() throws {
        let store = try self.makeStore()

        let first = store.identifier()
        store.retireCurrentIdentifier()
        let second = store.identifier()
        store.retireCurrentIdentifier()

        let snapshot = store.pendingRemovalIdentifiers()

        let third = store.identifier()
        store.retireCurrentIdentifier()

        let remainingAfterSweep: Set<UUID> = [second]
        store.removeFromPending(snapshot.subtracting(remainingAfterSweep))

        XCTAssertEqual(store.pendingRemovalIdentifiers(), [second, third])
        XCTAssertFalse(store.pendingRemovalIdentifiers().contains(first))
    }

    private func makeStore() throws -> WebViewDataStoreIdentifierStore {
        let suiteName = "com.revenuecat.WebViewDataStoreIdentifierStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock { [weak defaults] in
            defaults?.removePersistentDomain(forName: suiteName)
        }

        return WebViewDataStoreIdentifierStore(userDefaults: defaults)
    }

}
