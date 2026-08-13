//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewWebsiteDataStoreSweeperTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/26.
//

@testable import RevenueCatUI
import XCTest

final class WebViewWebsiteDataStoreSweeperTests: TestCase {

    func testSweepRemovesIdentifiersThatExistAndWereDeleted() async {
        let first = UUID()
        let second = UUID()
        var removed: [UUID] = []

        let remaining = await WebViewWebsiteDataStoreSweeper.sweep(
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

        let remaining = await WebViewWebsiteDataStoreSweeper.sweep(
            pending: [identifier],
            existing: [identifier],
            remove: { _ in false }
        )

        XCTAssertEqual(remaining, [identifier])
    }

    func testSweepDropsMissingIdentifiersWithoutCallingRemove() async {
        let identifier = UUID()
        var removeCalled = false

        let remaining = await WebViewWebsiteDataStoreSweeper.sweep(
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

    func testSweepStoresIsANoOpWhenNothingIsPending() async throws {
        let store = try self.makeStore()
        let sweeper = WebViewWebsiteDataStoreSweeper(idStore: store)

        await sweeper.sweepStores()

        XCTAssertTrue(store.pendingRemovalIdentifiers().isEmpty)
    }

    private func makeStore() throws -> WebViewDataStoreIdentifierStore {
        let suiteName = "com.revenuecat.WebViewWebsiteDataStoreSweeperTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock { [weak defaults] in
            defaults?.removePersistentDomain(forName: suiteName)
        }

        return WebViewDataStoreIdentifierStore(userDefaults: defaults)
    }

}
