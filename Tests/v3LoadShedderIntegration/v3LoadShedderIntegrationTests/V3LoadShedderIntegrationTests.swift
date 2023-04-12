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

@testable import Purchases
import StoreKit
import StoreKitTest
@testable import v3LoadShedderIntegration
import XCTest

final class V3LoadShedderIntegrationTests: XCTestCase {
    let apiKey = "REVENUECAT_LOAD_SHEDDER_API_KEY"

    let skConfigFileName = "V3LoadShedderIntegrationTestsConfiguration"
    let entitlementIdentifier = "premium"

    var testSession: SKTestSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
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

    override func tearDownWithError() throws {
        self.testSession = nil
        try super.tearDownWithError()
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

    func testGetOfferings() async throws {
        let offerings = try await Purchases.shared.offerings()
        let offering = try XCTUnwrap(offerings.current)
        XCTAssert(offering.availablePackages.count > 0)
        let package = try XCTUnwrap(offering.availablePackages[0])
        XCTAssertEqual(package.product.productIdentifier, "com.revenuecat.loadShedder.monthly")
        XCTAssertEqual(offering.identifier, "default")
    }

    func testPurchasePackage() async throws {
        let offerings = try await Purchases.shared.offerings()
        let offering = try XCTUnwrap(offerings.current)
        XCTAssert(offering.availablePackages.count > 0)
        let package = try XCTUnwrap(offering.availablePackages[0])

        let (_, nullablePurchaserInfo, userCancelled) = try await Purchases.shared.purchasePackage(package)

        XCTAssert(!userCancelled)

        let purchaserInfo = try XCTUnwrap(nullablePurchaserInfo)
        let activeEntitlements = purchaserInfo.entitlements.active
        XCTAssert(activeEntitlements[self.entitlementIdentifier] != nil)
    }

}
