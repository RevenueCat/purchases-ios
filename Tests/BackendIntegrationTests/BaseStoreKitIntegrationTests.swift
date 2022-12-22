//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseStoreKitIntegrationTests.swift
//
//  Created by Nacho Soto on 12/15/22.

import Nimble
@testable import RevenueCat
@preconcurrency import StoreKit // `PurchaseResult` is not `Sendable`
import StoreKitTest
import UniformTypeIdentifiers
import XCTest

@MainActor
class BaseStoreKitIntegrationTests: BaseBackendIntegrationTests {

    private(set) var testSession: SKTestSession!

    override func setUp() async throws {
        if self.testSession == nil {
            try self.configureTestSession()
        }

        // Initialize `Purchases` *after* the fresh new session has been created
        // (and transactions has been cleared), to avoid the SDK posting receipts from
        // a previous test.
        try await super.setUp()

        // SDK initialization begins with an initial request to offerings
        // Which results in a get-create of the initial anonymous user.
        // To avoid race conditions with when this request finishes and make all tests deterministic
        // this waits for that request to finish.
        _ = try await Purchases.shared.offerings()
    }

    override func tearDown() {
        self.testSession = nil

        super.tearDown()
    }

    func configureTestSession() throws {
        assert(self.testSession == nil, "Attempted to configure session multiple times")

        self.testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true
        self.testSession.clearTransactions()
        if #available(iOS 15.2, *) {
            self.testSession.timeRate = .monthlyRenewalEveryThirtySeconds
        } else {
            self.testSession.timeRate = .oneSecondIsOneDay
        }
    }

}

// MARK: - Helpers

extension BaseStoreKitIntegrationTests {

    static let entitlementIdentifier = "premium"
    static let consumable10Coins = "consumable.10_coins"
    static let monthlyNoIntroProductID = "com.revenuecat.monthly_4.99.no_intro"
    static let group3MonthlyTrialProductID = "com.revenuecat.monthly.1.99.1_free_week"
    static let group3MonthlyNoTrialProductID = "com.revenuecat.monthly.1.99.no_intro"

    private var currentOffering: Offering {
        get async throws {
            return try await XCTAsyncUnwrap(try await Purchases.shared.offerings().current)
        }
    }

    var monthlyPackage: Package {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.currentOffering.monthly)
        }
    }

    var annualPackage: Package {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.currentOffering.annual)
        }
    }

    var monthlyNoIntroProduct: StoreProduct {
        get async throws {
            return try await self.product(Self.monthlyNoIntroProductID)
        }
    }

    func product(_ identifier: String) async throws -> StoreProduct {
        let products = await Purchases.shared.products([identifier])
        return try XCTUnwrap(products.onlyElement)
    }

    @discardableResult
    func purchaseMonthlyOffering(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let data = try await Purchases.shared.purchase(package: self.monthlyPackage)

        try await self.verifyEntitlementWentThrough(data.customerInfo,
                                                    file: file,
                                                    line: line)

        return data
    }

    @discardableResult
    func purchaseMonthlyProduct(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let data = try await Purchases.shared.purchase(product: self.monthlyPackage.storeProduct)

        try await self.verifyEntitlementWentThrough(data.customerInfo,
                                                    file: file,
                                                    line: line)

        return data
    }

    @discardableResult
    func purchaseConsumablePackage(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let offering = try await XCTAsyncUnwrap(
            try await Purchases.shared.offerings().offering(identifier: "coins"),
            file: file, line: line
        )
        let package = try XCTUnwrap(
            offering.package(identifier: "10.coins"),
            file: file, line: line
        )

        return try await Purchases.shared.purchase(package: package)
    }

    @discardableResult
    func verifyEntitlementWentThrough(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> EntitlementInfo {
        let entitlements = customerInfo.entitlements.all

        if entitlements.isEmpty {
            await self.printReceiptContent()
        }

        expect(
            file: file, line: line,
            entitlements
        ).to(
            haveCount(1),
            description: "Expected Entitlement. Got: \(entitlements)"
        )

        let entitlement: EntitlementInfo

        do {
            entitlement = try XCTUnwrap(
                entitlements[Self.entitlementIdentifier],
                file: file, line: line
            )
        } catch {
            await self.printReceiptContent()
            throw error
        }

        if !entitlement.isActive {
            await self.printReceiptContent()
        }

        expect(file: file, line: line, entitlement.isActive)
            .to(beTrue(), description: "Entitlement is not active")

        return entitlement
    }

    func assertNoActiveSubscription(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            customerInfo.entitlements.active
        ).to(
            beEmpty(),
            description: "Expected no active entitlements"
        )
    }

    func assertNoPurchases(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            customerInfo.entitlements.all
        )
        .to(
            beEmpty(),
            description: "Expected no entitlements. Got: \(customerInfo.entitlements.all)"
        )
    }

    func expireSubscription(_ entitlement: EntitlementInfo) async throws {
        guard let expirationDate = entitlement.expirationDate else { return }

        Logger.info("Expiring subscription for product '\(entitlement.productIdentifier)'")

        // Try expiring using `SKTestSession`
        do {
            try self.testSession.expireSubscription(productIdentifier: entitlement.productIdentifier)
        } catch {
            Logger.warn(
                """
                Failed testSession.expireSubscription, this is probably an Xcode bug.
                Test will now wait for expiration instead of triggering it.
                Error: \(error.localizedDescription)
                """
            )
        }

        let secondsUntilExpiration = expirationDate.timeIntervalSince(Date())
        guard secondsUntilExpiration > 0 else {
            Logger.info("Done waiting for subscription expiration, continuing test.")
            return
        }

        let timeToSleep = Int(secondsUntilExpiration.rounded(.up) + 1)

        // `SKTestSession.expireSubscription` doesn't seem to work, so force expiration by waiting
        Logger.warn("Sleeping for \(timeToSleep) seconds to force expiration")
        try await Task.sleep(nanoseconds: UInt64(timeToSleep * 1_000_000_000))
    }

    @available(iOS 15.2, tvOS 15.2, macOS 12.1, watchOS 8.3, *)
    static func findTransaction(for productIdentifier: String) async throws -> Transaction {
        let transactions: [Transaction] = await Transaction
            .currentEntitlements
            .compactMap {
                switch $0 {
                case let .verified(transaction): return transaction
                case .unverified: return nil
                }
            }
            .filter { $0.productID == productIdentifier }
            .extractValues()

        expect(transactions).to(haveCount(1))
        return try XCTUnwrap(transactions.first)
    }

}

// MARK: - Extensions

extension BaseStoreKitIntegrationTests {

    func printReceiptContent() async {
        do {
            let receipt = try await Purchases.shared.fetchReceipt(.always)
            let description = receipt.map { $0.debugDescription } ?? "<null>"

            Logger.appleWarning("Receipt content:\n\(description)")

            if let receipt = receipt {
                let attachment = XCTAttachment(data: try receipt.prettyPrintedData,
                                               uniformTypeIdentifier: UTType.json.identifier)
                attachment.lifetime = .keepAlways

                self.add(attachment)
            }
        } catch {
            Logger.error("Error parsing local receipt: \(error)")
        }
    }

    /// Purchases a product directly with StoreKit.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    @discardableResult
    func purchaseProductFromStoreKit() async throws -> Product.PurchaseResult {
        let products = try await StoreKit.Product.products(for: [Self.monthlyNoIntroProductID])
        let product = try XCTUnwrap(products.onlyElement)

        return try await product.purchase()
    }

}
