//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LoadShedderIntegrationTests.swift
//
//  Created by Nacho Soto on 3/21/23.

import Nimble
@testable import RevenueCat
import SnapshotTesting
import StoreKit
import XCTest

class LoadShedderStoreKit2IntegrationTests: LoadShedderStoreKit1IntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting {
        return .enabledForCompatibleDevices
    }

}

class LoadShedderStoreKit1IntegrationTests: BaseStoreKitIntegrationTests {

    override var apiKey: String { return Constants.loadShedderApiKey }

    override class var storeKit2Setting: StoreKit2Setting {
        return .disabled
    }

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        // Disabled until backend deploys signature verification
        // return Signing.enforcedVerificationMode()
        return .disabled
    }

    // MARK: -

    private var logger: TestLogHandler!

    override func setUp() async throws {
        self.logger = TestLogHandler(capacity: 500)

        try await super.setUp()
    }

    override func tearDown() async throws {
        self.logger = nil

        try await super.tearDown()
    }

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await Purchases.shared.offerings()

        expect(receivedOfferings.all).toNot(beEmpty())
        assertSnapshot(matching: receivedOfferings.response, as: .formattedJson)
    }

    func testOfferingsComeFromLoadShedder() async throws {
        self.logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(
                .getOfferings(appUserID: try Purchases.shared.appUserID.escapedOrError())
            ),
            level: .debug
        )
    }

    func testCanPurchasePackage() async throws {
        try await self.purchaseMonthlyOffering()

        self.logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(.postReceiptData),
            level: .debug
        )
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMapping() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let result = try await Purchases.shared.productEntitlementMapping()
        expect(result.entitlementsByProduct).to(haveCount(1))
        expect(result.entitlementsByProduct["com.revenuecat.loadShedder.monthly"]) == ["premium"]
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMappingComesFromLoadShedder() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.network.request_handled_by_load_shedder(.getProductEntitlementMapping).description,
            level: .debug,
            timeout: .seconds(5),
            pollInterval: .milliseconds(100)
        )
    }

}
