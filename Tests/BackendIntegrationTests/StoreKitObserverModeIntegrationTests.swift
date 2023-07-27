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

    var manager: ObserverModeManager!

    final override func configureTestSession() async throws {
        try await super.configureTestSession()

        self.manager = .init()
    }

}

class StoreKit2ObserverModeIntegrationTests: StoreKit1ObserverModeIntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseInDevicePostsReceipt() async throws {
        let result = try await self.manager.purchaseProductFromStoreKit2()
        let transaction = try XCTUnwrap(result.verificationResult?.underlyingTransaction)

        try self.testSession.disableAutoRenewForTransaction(identifier: UInt(transaction.id))

        XCTExpectFailure("This test currently does not pass (see FB12231111)")

        try await asyncWait(
            until: {
                let entitlement = await self.purchasesDelegate
                    .customerInfo?
                    .entitlements[Self.entitlementIdentifier]

                return entitlement?.isActive == true
            },
            timeout: .seconds(5),
            pollInterval: .milliseconds(500),
            description: "Entitlement didn't become active"
        )
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testRenewalsPostReceipt() async throws {
        self.testSession.timeRate = .realTime

        let productID = Self.monthlyNoIntroProductID

        try await self.manager.purchaseProductFromStoreKit2(productIdentifier: productID)

        try self.testSession.forceRenewalOfSubscription(productIdentifier: productID)

        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.network.operation_state(PostReceiptDataOperation.self, state: "Finished").description,
            timeout: .seconds(3),
            pollInterval: .milliseconds(100)
        )
    }

}

class StoreKit1ObserverModeIntegrationTests: BaseStoreKitObserverModeIntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .disabled }

    func testPurchaseOutsideTheAppPostsReceipt() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.monthlyNoIntroProductID)

        let info = try await self.purchases.restorePurchases()
        try await self.verifyEntitlementWentThrough(info)
    }

    func testPurchaseOutsideTheAppUpdatesCustomerInfoDelegate() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.monthlyNoIntroProductID)

        try await asyncWait(
            until: {
                await self.purchasesDelegate.customerInfo?.entitlements.active.isEmpty == false
            },
            timeout: .seconds(4),
            pollInterval: .milliseconds(100),
            description: "Delegate should be notified"
        )

        let customerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSK2RenewalsPostReceiptOnlyOnceWhenSK1IsEnabled() async throws {
        try XCTSkipIf(Self.storeKit2Setting.isEnabledAndAvailable, "Test only for SK1")

        // `StoreKit2TransactionListener` is always enabled even in SK1 mode.
        // This test ensures that we don't end up posting receipts multiple times when renewals come through.

        self.testSession.timeRate = .realTime

        let productID = Self.monthlyNoIntroProductID

        try await self.manager.purchaseProductFromStoreKit2(productIdentifier: productID)

        try? self.testSession.forceRenewalOfSubscription(productIdentifier: productID)

        try await self.logger.verifyMessageIsEventuallyLogged(
            "Network operation 'PostReceiptDataOperation' found with the same cache key",
            timeout: .seconds(4),
            pollInterval: .milliseconds(100)
        )
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit2ObserverModeWithExistingPurchasesTests: StoreKit1ObserverModeWithExistingPurchasesTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

}

/// Purchases a product before configuring `Purchases` to verify behavior upon initialization in observer mode.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit1ObserverModeWithExistingPurchasesTests: BaseStoreKitObserverModeIntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .disabled }

    // MARK: - Transactions observation

    private static var transactionsObservation: Task<Void, Never>?

    override class func setUp() {
        super.setUp()

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

        super.tearDown()
    }

    override func setUp() async throws {
        // Not calling `super.setUp` so each test can
        // do something else before initializing SDK.
    }

    func testDoesNotSyncExistingSK1Purchases() async throws {
        // 1. Create `SKTestSession`
        try await self.configureTestSession()

        // 2. Purchase product directly from StoreKit
        try await self.manager.purchaseProductFromStoreKit1()

        // 3. Configure SDK
        try await super.setUp()

        // 4. Sync customer info
        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        self.assertNoPurchases(info)
    }

    func testDoesNotSyncExistingSK2Purchases() async throws {
        // 1. Create `SKTestSession`
        try await self.configureTestSession()

        // 2. Purchase product directly from StoreKit
        try await self.manager.purchaseProductFromStoreKit2()

        // 3. Configure SDK
        try await super.setUp()

        // 4. Sync customer info
        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        self.assertNoPurchases(info)
    }

}
