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
//  Created by Jacob Zivan Rakidzich on 8/10/26.
//

@_spi(Internal) @testable import RevenueCat
import XCTest

final class WebViewDataStoreIdentifierStoreTests: TestCase {

    func testIdentifierIsGeneratedOnceAndPersisted() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let firstIdentifier = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        let secondIdentifier = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)

        XCTAssertEqual(firstIdentifier, secondIdentifier)
    }

    func testRetiringIdentifierEnqueuesItAndRotatesOnNextUse() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let firstIdentifier = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)

        XCTAssertEqual(
            WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults),
            firstIdentifier
        )
        XCTAssertEqual(
            WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults),
            [firstIdentifier]
        )
        XCTAssertNotEqual(
            WebViewDataStoreIdentifierStore.identifier(in: userDefaults),
            firstIdentifier
        )
    }

    func testRetireDoesNotCreateAnIdentifierWhenNoneExists() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults))
        XCTAssertTrue(WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults).isEmpty)
    }

    func testMultipleRetiresAccumulatePendingIdentifiers() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let first = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)
        let second = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)

        XCTAssertEqual(
            WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults),
            [first, second]
        )
    }

    func testRemoveFromPendingSubtractsWithoutReplacingTheSet() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let first = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)
        let second = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)

        WebViewDataStoreIdentifierStore.removeFromPending([first], in: userDefaults)

        XCTAssertEqual(
            WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults),
            [second]
        )
    }

    func testRemoveFromPendingPreservesIdentifiersAddedAfterSnapshot() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let first = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)
        let second = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)

        let snapshot = WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults)

        let third = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)
        _ = WebViewDataStoreIdentifierStore.retireCurrentIdentifier(in: userDefaults)

        let remainingAfterSweep: Set<UUID> = [second]
        WebViewDataStoreIdentifierStore.removeFromPending(
            snapshot.subtracting(remainingAfterSweep),
            in: userDefaults
        )

        XCTAssertEqual(
            WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults),
            [second, third]
        )
        XCTAssertFalse(
            WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers(in: userDefaults).contains(first)
        )
    }

    private func makeUserDefaults() throws -> (UserDefaults, String) {
        let suiteName = "com.revenuecat.WebViewDataStoreIdentifierStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        addTeardownBlock { [weak defaults] in
            defaults?.removePersistentDomain(forName: suiteName)
        }

        return (defaults, suiteName)
    }

}
