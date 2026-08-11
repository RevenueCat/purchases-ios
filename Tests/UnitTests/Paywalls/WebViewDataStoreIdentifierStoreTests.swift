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

    func testClearingIdentifierRotatesItOnNextUse() throws {
        let (userDefaults, suiteName) = try makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let firstIdentifier = WebViewDataStoreIdentifierStore.identifier(in: userDefaults)

        XCTAssertEqual(
            WebViewDataStoreIdentifierStore.clearIdentifier(in: userDefaults),
            firstIdentifier
        )
        XCTAssertNotEqual(
            WebViewDataStoreIdentifierStore.identifier(in: userDefaults),
            firstIdentifier
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
