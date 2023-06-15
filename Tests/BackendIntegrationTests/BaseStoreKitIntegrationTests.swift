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
import StoreKit
import StoreKitTest
import UniformTypeIdentifiers
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

@MainActor
class BaseStoreKitIntegrationTests: BaseBackendIntegrationTests {

    private(set) var testSession: SKTestSession!

    override func setUp() async throws {
        if self.testSession == nil {
            try self.configureTestSession()
        }

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            // Despite calling `SKTestSession.clearTransactions` tests sometimes
            // begin with leftover transactions. This ensures that we remove them
            // to always start with a clean state.
            await self.deleteAllTransactions(session: self.testSession)
        }

        // Initialize `Purchases` *after* the fresh new session has been created
        // (and transactions has been cleared), to avoid the SDK posting receipts from
        // a previous test.
        try await super.setUp()
    }

    override func tearDown() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            await self.deleteAllTransactions(session: self.testSession)
        }

        self.testSession.clearTransactions()

        try await super.tearDown()
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
    static let group3YearlyTrialProductID = "com.revenuecat.annual.10.99.1_free_week"

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
        // This is used to throw an error when the test fails.
        // For some reason XCTest is continuing execution even after a test failure
        // despite having `self.continueAfterFailure = false`
        //
        // By doing this, instead of only calling `fail`, we ensure that
        // Swift stops executing code when an assertion has failed,
        // and therefore avoid code running after the test has already failed.
        // This prevents test crashes from code calling `Purchases.shared` after the test has ended.
        func failTest(_ message: String) async throws {
            struct ExpectationFailure: Swift.Error {}

            await self.printReceiptContent()

            fail(message, file: file, line: line)
            throw ExpectationFailure()
        }

        let entitlements = customerInfo.entitlements.all
        if entitlements.count != 1 {
            try await failTest("Expected 1 Entitlement. Got: \(entitlements)")
        }

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
            try await failTest("Entitlement is not active")
        }

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

        Logger.info(TestMessage.expiring_subscription(productID: entitlement.productIdentifier))

        // Try expiring using `SKTestSession`
        do {
            try self.testSession.expireSubscription(productIdentifier: entitlement.productIdentifier)
        } catch {
            Logger.warn(TestMessage.expire_subscription_failed(error))
        }

        let secondsUntilExpiration = expirationDate.timeIntervalSince(Date())
        guard secondsUntilExpiration > 0 else {
            Logger.info(TestMessage.finished_waiting_for_expiration)
            return
        }

        let timeToSleep = Int(secondsUntilExpiration.rounded(.up) + 1)

        // `SKTestSession.expireSubscription` doesn't seem to work, so force expiration by waiting
        Logger.warn(TestMessage.sleeping_to_force_expiration(seconds: timeToSleep))
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

    @MainActor
    func printReceiptContent() async {
        guard Purchases.isConfigured else {
            Logger.error(TestMessage.unable_parse_receipt_without_sdk)
            return
        }

        do {
            let receipt = try await Purchases.shared.fetchReceipt(.always)
            let description = receipt.map { $0.debugDescription } ?? "<null>"

            Logger.appleWarning(TestMessage.receipt_content(description))

            if let receipt = receipt {
                let attachment = XCTAttachment(data: try receipt.prettyPrintedData,
                                               uniformTypeIdentifier: UTType.json.identifier)
                attachment.lifetime = .keepAlways

                self.add(attachment)
            }
        } catch {
            Logger.error(TestMessage.error_parsing_receipt(error))
        }
    }

    /// Purchases a product directly with StoreKit.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    @discardableResult
    func purchaseProductFromStoreKit(
        productIdentifier: String = BaseStoreKitIntegrationTests.monthlyNoIntroProductID,
        finishTransaction: Bool = false
    ) async throws -> Product.PurchaseResult {
        let products = try await StoreKit.Product.products(for: [productIdentifier])
        let product = try XCTUnwrap(products.onlyElement)

        let result = try await product.purchase()

        if finishTransaction {
            await result.verificationResult?.underlyingTransaction.finish()
        }

        return result
    }

}
