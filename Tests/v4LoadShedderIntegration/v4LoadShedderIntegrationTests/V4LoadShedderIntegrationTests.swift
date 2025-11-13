//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  V4LoadShedderIntegrationTests.swift
//
//  Created by Andrés Boedo on 3/29/23.

@testable import RevenueCat
import StoreKit
import StoreKitTest
@testable import v4LoadShedderIntegration
import XCTest

final class V4LoadShedderIntegrationTests: XCTestCase {
    let apiKey = "REVENUECAT_LOAD_SHEDDER_API_KEY"

    let skConfigFileName = "V4LoadShedderIntegrationTestsConfiguration"

    let entitlementIdentifier = "premium"
    let productIdentifier = "com.revenuecat.loadShedder.monthly"

    var testSession: SKTestSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        Purchases.logLevel = .debug
        let userDefaultsSuite = "V4LoadShedderIntegrationTests"
        let userDefaults = UserDefaults(suiteName: userDefaultsSuite)!
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        try configureTestSession()

        Purchases.configure(withAPIKey: self.apiKey + "bad",
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults,
                            platformInfo: nil,
                            responseVerificationMode: .disabled,
                            storeKit2Setting: .disabled,
                            storeKitTimeout: Configuration.storeKitRequestTimeoutDefault,
                            networkTimeout: Configuration.networkTimeoutDefault,
                            dangerousSettings: nil,
                            showStoreMessagesAutomatically: true,
                            diagnosticsEnabled: false)
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

    func testGetOfferings() async throws {
        let offerings = try await Purchases.shared.offerings()
        let offering = try XCTUnwrap(offerings.current)
        XCTAssert(offering.availablePackages.count > 0)
        let package = try XCTUnwrap(offering.availablePackages[0])
        XCTAssertEqual(package.storeProduct.productIdentifier, self.productIdentifier)
        XCTAssertEqual(offering.identifier, "default")
    }

    func testGetProductEntitlementMapping() async throws {
        let productEntitlementMapping = try await Purchases.shared.productEntitlementMapping()
        XCTAssertFalse(productEntitlementMapping.entitlementsByProduct.isEmpty)
        XCTAssertEqual(productEntitlementMapping.entitlements(for: self.productIdentifier),
                       Set([self.entitlementIdentifier]))
    }

    func testPurchasePackage() async throws {
        let offerings = try await Purchases.shared.offerings()
        let offering = try XCTUnwrap(offerings.current)
        XCTAssert(offering.availablePackages.count > 0)
        let package = try XCTUnwrap(offering.availablePackages[0])

        let (_, nullablePurchaserInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

        XCTAssert(!userCancelled)

        let purchaserInfo = try XCTUnwrap(nullablePurchaserInfo)
        let activeEntitlements = purchaserInfo.entitlements.active
        XCTAssert(activeEntitlements[self.entitlementIdentifier] != nil)
    }

}
