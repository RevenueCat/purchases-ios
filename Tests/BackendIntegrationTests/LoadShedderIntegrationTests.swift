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

// swiftlint:disable type_name

import Nimble
@testable import RevenueCat
import SnapshotTesting
import StoreKit
import XCTest

class LoadShedderStoreKit2IntegrationTests: LoadShedderStoreKit1IntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

}

class LoadShedderStoreKit1IntegrationTests: BaseStoreKitIntegrationTests {

    override var apiKey: String { return Constants.loadShedderApiKey }

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    override class var responseVerificationMode: Signing.ResponseVerificationMode {
        return Signing.enforcedVerificationMode()
    }

    // MARK: -

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await self.purchases.offerings()

        expect(receivedOfferings.all).toNot(beEmpty())
        assertSnapshot(matching: receivedOfferings.response, as: .formattedJson)
    }

    func testOfferingsComeFromLoadShedder() async throws {
        self.logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(
                HTTPRequest.Path.getOfferings(appUserID: try self.purchases.appUserID)
            ),
            level: .debug
        )
    }

    func testCanPurchaseSubsPackage() async throws {
        try await self.purchaseMonthlyOffering()

        self.logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(HTTPRequest.Path.postReceiptData),
            level: .debug
        )

        self.verifyCustomerInfoWasNotComputedOffline(logger: self.logger)
    }

    func testCanPurchaseConsumablePackage() async throws {
        // WIP: remove this check so we also verify in this case once backend supports this case
        if disableHeaderSignatureVerification {
            throw XCTSkip("Currently does not work with disabled header signature verification.")
        }
        let purchaseData = try await self.purchaseConsumablePackage()

        let purchasedProductIds = purchaseData.customerInfo.allPurchasedProductIdentifiers
        expect(purchasedProductIds.count) == 1

        let purchasedProductId = try XCTUnwrap(purchasedProductIds.first)

        expect(purchasedProductId) == "consumable.10_coins"

        self.logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(HTTPRequest.Path.postReceiptData),
            level: .debug
        )

        self.verifyCustomerInfoWasNotComputedOffline(logger: self.logger)
    }

    func testCanPurchaseNonConsumablePackage() async throws {
        // WIP: remove this check so we also verify in this case once backend supports this case
        if disableHeaderSignatureVerification {
            throw XCTSkip("Currently does not work with disabled header signature verification.")
        }
        let purchaseData = try await self.purchaseNonConsumablePackage()

        try await self.verifyEntitlementWentThrough(purchaseData.customerInfo)

        self.logger.verifyMessageWasLogged(
            Strings.network.request_handled_by_load_shedder(HTTPRequest.Path.postReceiptData),
            level: .debug
        )
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMapping() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let result = try await self.purchases.productEntitlementMapping()
        expect(result.entitlementsByProduct).to(haveCount(3))
        expect(result.entitlementsByProduct["com.revenuecat.loadShedder.monthly"]) == ["premium"]
        expect(result.entitlementsByProduct["consumable.10_coins"]) == []
        expect(result.entitlementsByProduct["lifetime"]) == ["premium"]
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMappingComesFromLoadShedder() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.network.request_handled_by_load_shedder(HTTPRequest.Path.getProductEntitlementMapping).description,
            level: .debug,
            timeout: .seconds(5),
            pollInterval: .milliseconds(100)
        )
    }

}

/// Header verification (see `HTTPRequest.headerParametersForSignatureHeader`) is enabled by default,
/// but this helps verify that the backend is still signing correctly without it for older SDK versions.
/// See also `SignatureVerificationWithoutHeaderHashIntegrationTests`.
class LoadShedderSignatureVerificationWithoutHeaderHashIntegrationTests: LoadShedderStoreKit1IntegrationTests {

    override var disableHeaderSignatureVerification: Bool { return true }

    override func tearDown() {
        self.logger.verifyMessageWasLogged(
            "Disabling header parameter signature verification",
            level: .warn
        )

        super.tearDown()
    }

}
