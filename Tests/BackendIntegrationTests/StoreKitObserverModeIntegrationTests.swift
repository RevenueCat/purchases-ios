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
import Nimble
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

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testObservingTransactionUnlocksEntitlement() async throws {
        await self.deleteAllTransactions(session: self.testSession)

        let result = try await self.manager.purchaseProductFromStoreKit2()
        let transaction = try XCTUnwrap(result.verificationResult?.underlyingTransaction)
        try self.testSession.disableAutoRenewForTransaction(identifier: UInt(transaction.id))

        try await simulateAppDidBecomeActive()

        try await self.verifyReceiptIsEventuallyPosted()
        let customerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testRenewalsPostReceipt() async throws {
        // forceRenewalOfSubscription doesn't work well, so we use this instead
        setShortestTestSessionTimeRate(self.testSession)

        let productID = Self.group3MonthlyNoTrialProductID

        try await self.manager.purchaseProductFromStoreKit2(productIdentifier: productID)

        // swiftlint:disable:next force_try
        try! await Task.sleep(nanoseconds: 3 * 1_000_000_000)

        try await self.verifyReceiptIsEventuallyPosted()
    }

    /// Simulates the app becoming active by broadcasting the SystemInfo.applicationDidBecomeActiveNotification.
    /// This is necessary because our backend integration test app initiates the purchase 
    /// flow without any user input and therefore the purchase dialogs never appear.
    /// Without the dialogs, the SDK's trigger to detect purchases in observer mode is never activated.
    private func simulateAppDidBecomeActive() async throws {
        NotificationCenter.default.post(name: SystemInfo.applicationDidBecomeActiveNotification!, object: nil)
    }
}

class StoreKit1ObserverModeIntegrationTests: BaseStoreKitObserverModeIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    func testPurchaseOutsideTheAppPostsReceipt() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.monthlyNoIntroProductID)

        // In JWS mode, transaction takes a bit longer to be processed after `buyProduct`
        // We need to wait so `restorePurchases` actually posts it.
        try await self.waitUntilUnfinishedTransactions { $0 == 1 }

        let info = try await self.purchases.restorePurchases()
        try await self.verifyEntitlementWentThrough(info)
    }

    func testPurchaseOutsideTheAppUpdatesCustomerInfoDelegate() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.monthlyNoIntroProductID)

        try await asyncWait(
            description: "Delegate should be notified",
            timeout: .seconds(4),
            pollInterval: .milliseconds(100)
        ) {
            await self.purchasesDelegate.customerInfo?.entitlements.active.isEmpty == false
        }

        let customerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit2ObserverModeWithExistingPurchasesTests: StoreKit1ObserverModeWithExistingPurchasesTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit2 }

}

/// Purchases a product before configuring `Purchases` to verify behavior upon initialization in observer mode.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit1ObserverModeWithExistingPurchasesTests: BaseStoreKitObserverModeIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

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

class StoreKit2NotEnabledObserverModeIntegrationTests: BaseStoreKitObserverModeIntegrationTests {

    override class var storeKitVersion: StoreKitVersion { .storeKit1 }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testObservingTransactionThrowsIfStoreKit2NotEnabled() async throws {
        let manager = ObserverModeManager()
        let result = try await manager.purchaseProductFromStoreKit2()

        do {
            _ = try await Purchases.shared.recordPurchase(result)
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.configurationError))
        }
    }

}
