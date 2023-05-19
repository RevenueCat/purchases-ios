//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitObserverModeIntegrationTests.swift
//
//  Created by Nacho Soto on 12/15/22.

import Foundation

@testable import RevenueCat
import StoreKit
import StoreKitTest
import XCTest

// swiftlint:disable type_name

class BaseStoreKitObserverModeIntegrationTests: BaseStoreKitIntegrationTests {

    override class var observerMode: Bool { return true }

}

class StoreKit2ObserverModeIntegrationTests: StoreKit1ObserverModeIntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseInDevicePostsReceipt() async throws {
        try await self.purchaseProductFromStoreKit()

        try await asyncWait(
            until: {
                let entitlement = try? await Purchases.shared
                    .customerInfo(fetchPolicy: .fetchCurrent)
                    .entitlements[Self.entitlementIdentifier]

                return entitlement?.isActive == true
            },
            timeout: .seconds(60),
            pollInterval: .seconds(2),
            description: "Entitlement didn't become active"
        )
    }

}

class StoreKit1ObserverModeIntegrationTests: BaseStoreKitObserverModeIntegrationTests {

    func testPurchaseOutsideTheAppPostsReceipt() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.monthlyNoIntroProductID)

        let info = try await Purchases.shared.restorePurchases()
        try await self.verifyEntitlementWentThrough(info)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit2ObserverModeWithExistingPurchasesTests: StoreKit1ObserverModeWithExistingPurchasesTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

}

/// Purchases a product before configuring `Purchases` to verify behavior upon initialization in observer mode.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit1ObserverModeWithExistingPurchasesTests: BaseStoreKitObserverModeIntegrationTests {

    // MARK: - Transactions observation

    private static var transactionsObservation: Task<Void, Never>?

    override class func setUp() {
        Self.transactionsObservation?.cancel()
        Self.transactionsObservation = Task {
            // Silence warning in tests:
            // "Making a purchase without listening for transaction updates risks missing successful purchases.
            for await _ in Transaction.updates {}
        }
    }

    override class func tearDown() {
        Self.transactionsObservation?.cancel()
        Self.transactionsObservation = nil
    }

    override func setUp() async throws {
        // 1. Create `SKTestSession`
        try self.configureTestSession()

        // 2. Purchase product directly from StoreKit
        try await self.purchaseProductFromStoreKit()

        // 3. Configure SDK
        try await super.setUp()
    }

    func testDoesNotSyncExistingPurchase() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let info = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
        self.assertNoPurchases(info)
    }

}
