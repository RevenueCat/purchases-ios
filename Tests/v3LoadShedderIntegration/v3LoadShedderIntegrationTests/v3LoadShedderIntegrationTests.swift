//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  v3LoadShedderIntegrationTests.swift
//
//  Created by Andrés Boedo on 3/29/23.

import XCTest
@testable import v3LoadShedderIntegration
import StoreKit
import StoreKitTest
@testable import Purchases

final class v3LoadShedderIntegrationTests: XCTestCase {
    let apiKey = "API_KEY"

    let skConfigFileName = "v3LoadShedderIntegrationTestsConfiguration"

    var testSession: SKTestSession!

    override func setUpWithError() throws {
        Purchases.logLevel = .debug
        let userDefaultsSuite = "v3LoadShedderIntegrationTests"
        let userDefaults = UserDefaults(suiteName: userDefaultsSuite)!
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        try configureTestSession()

        Purchases.configure(withAPIKey: self.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        clearReceiptIfExists()
    }

    func configureTestSession() throws {
        assert(self.testSession == nil, "Attempted to configure session multiple times")

        self.testSession = try SKTestSession(configurationFileNamed: skConfigFileName)
        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true
        self.testSession.clearTransactions()
    }

    func clearReceiptIfExists() {
        let manager = FileManager.default

        guard let url = Bundle.main.appStoreReceiptURL, manager.fileExists(atPath: url.path) else { return }

        do {
            print("Removing receipt from url: \(url)")
            try manager.removeItem(at: url)
        } catch {
            print("Error attempting to remove receipt URL '\(url)': \(error)")
        }
    }

    override func tearDownWithError() throws {
    }

    func testGetOfferings() async throws {
        let offerings = try await Purchases.shared.offerings()
        let offering = try XCTUnwrap(offerings.current)
        let package = try XCTUnwrap(offering.availablePackages.first)
        XCTAssert(package.product.productIdentifier == "com.revenuecat.loadShedder.monthly")
    }

}
