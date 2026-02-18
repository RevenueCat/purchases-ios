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
        // `super.setUp()` isn't called until the end of this method,
        // but some tests might need to introspect logs during initialization.
        super.initializeLogger()

        if self.testSession == nil {
            try await self.configureTestSession()
        }

        // Initialize `Purchases` *after* the fresh new session has been created
        // (and transactions has been cleared), to avoid the SDK posting receipts from
        // a previous test.
        try await super.setUp()
    }

    override func tearDown() async throws {
        if let testSession = self.testSession {
            if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
                await self.deleteAllTransactions(session: testSession)
            }

            testSession.clearTransactions()
        }

        try await super.tearDown()
    }

    func configureTestSession() async throws {
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

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            // Despite calling `SKTestSession.clearTransactions` tests sometimes
            // begin with leftover transactions. This ensures that we remove them
            // to always start with a clean state.
            await self.deleteAllTransactions(session: self.testSession)
        }
    }

}

// MARK: - Helpers

extension BaseStoreKitIntegrationTests {

    static let entitlementIdentifier = "premium"
    static let consumable10Coins = "consumable.10_coins"
    static let nonConsumableLifetime = "lifetime"
    static let nonRenewingPackage = "non_renewing"
    static let monthlyNoIntroProductID = "com.revenuecat.monthly_4.99.no_intro"
    static let group3MonthlyTrialProductID = "com.revenuecat.monthly.1.99.1_free_week"
    static let group3MonthlyNoTrialProductID = "com.revenuecat.monthly.1.99.no_intro"
    static let group3YearlyTrialProductID = "com.revenuecat.annual.10.99.1_free_week"
    static let weeklyWith3DayTrial = "shortest_duration"

    var currentOffering: Offering {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.purchases.offerings().current)
        }
    }

    var offeringWithV1Paywall: Offering {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.purchases.offerings().all["alternate_offering"])
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

    var shortestDurationProduct: StoreProduct {
        get async throws {
            return try await self.product(Self.weeklyWith3DayTrial)
        }
    }

    func product(_ identifier: String) async throws -> StoreProduct {
        let products = try await self.purchases.products([identifier])
        return try XCTUnwrap(products.onlyElement)
    }

    @discardableResult
    func purchaseMonthlyOffering(
        allowOfflineEntitlements: Bool = false,
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let logger = TestLogHandler(testIdentifier: self.name)

        let data = try await self.purchase(package: self.monthlyPackage, file: file, line: line)

        try await self.verifyEntitlementWentThrough(data.customerInfo,
                                                    file: file,
                                                    line: line)

        if !allowOfflineEntitlements {
            // Avoid false positives if the API returned a 500 and customer info was computed offline
            self.verifyCustomerInfoWasNotComputedOffline(customerInfo: data.customerInfo, file: file, line: line)
        }

        return data
    }

    @discardableResult
    func purchaseMonthlyProduct(
        allowOfflineEntitlements: Bool = false,
        metadata: [String: String]? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let logger = TestLogHandler(testIdentifier: self.name)

        let data: PurchaseResultData

        #if ENABLE_TRANSACTION_METADATA
        if let metadata = metadata {
            let product = try await self.monthlyPackage.storeProduct

            #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
            let params = PurchaseParams.Builder(product: product)
                .with(metadata: metadata)
                .build()
            data = try await self.purchase(params: params, file: file, line: line)
            #else
            data = try await self.purchase(product: product, file: file, line: line)
            #endif

        } else {
            let product = try await self.monthlyPackage.storeProduct
            data = try await self.purchase(product: product, file: file, line: line)
        }
        #else
        let product = try await self.monthlyPackage.storeProduct
        data = try await self.purchase(product: product, file: file, line: line)
        #endif

        try await self.verifyEntitlementWentThrough(data.customerInfo,
                                                    file: file,
                                                    line: line)

        if !allowOfflineEntitlements {
            // Avoid false positives if the API returned a 500 and customer info was computed offline
            self.verifyCustomerInfoWasNotComputedOffline(customerInfo: data.customerInfo, file: file, line: line)
        }

        return data
    }

    @discardableResult
    func purchaseShortestDuration(
        allowOfflineEntitlements: Bool = false,
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let logger = TestLogHandler(testIdentifier: self.name)
        let product = try await StoreKit.Product.products(for: [Self.weeklyWith3DayTrial]).first!

        let data = try await self.purchase(product: StoreProduct(sk2Product: product), file: file, line: line)

        try await self.verifyEntitlementWentThrough(data.customerInfo,
                                                    file: file,
                                                    line: line)

        if !allowOfflineEntitlements {
            // Avoid false positives if the API returned a 500 and customer info was computed offline
            self.verifyCustomerInfoWasNotComputedOffline(customerInfo: data.customerInfo, file: file, line: line)
        }

        return data
    }

    @discardableResult
    func purchaseConsumablePackage(
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let offering = try await XCTAsyncUnwrap(
            try await self.purchases.offerings().offering(identifier: "coins"),
            file: file, line: line
        )
        let package = try XCTUnwrap(
            offering.package(identifier: "10.coins"),
            file: file, line: line
        )

        return try await self.purchase(package: package, file: FileString(fromStaticString: file), line: line)
    }

    @discardableResult
    func purchaseNonConsumablePackage(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let package = try await XCTAsyncUnwrap(try await self.currentOffering.lifetime)
        return try await self.purchase(package: package, file: file, line: line)
    }

    @discardableResult
    func purchaseNonRenewingSubscriptionPackage(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let package = try await XCTAsyncUnwrap(try await self.currentOffering[Self.nonRenewingPackage])
        return try await self.purchase(package: package, file: file, line: line)
    }

    func purchase(package: Package, file: FileString, line: UInt) async throws -> PurchaseResultData {
        let data = try await self.purchases.purchase(package: package)
        if let transaction = data.transaction {
            Logger.info(TestMessage.made_purchase(transaction: transaction, file: file, line: line))
        }
        return data
    }

    func purchase(product: StoreProduct, file: FileString, line: UInt) async throws -> PurchaseResultData {
        let data = try await self.purchases.purchase(product: product)
        if let transaction = data.transaction {
            Logger.info(TestMessage.made_purchase(transaction: transaction, file: file, line: line))
        }
        return data
    }

    func purchase(params: PurchaseParams, file: FileString, line: UInt) async throws -> PurchaseResultData {
        let data = try await self.purchases.purchase(params)
        if let transaction = data.transaction {
            Logger.info(TestMessage.made_purchase(transaction: transaction, file: file, line: line))
        }
        return data
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

    static let finishingAnyTransactionLog = "Finishing transaction"
    static func finishingSpecificTransactionLog(transactionId: String, productId: String) -> String {
        return "Finishing transaction '\(transactionId)' for product '\(productId)'"
    }

    static func finishingTransactionLogRegexPattern(productIdentifier: String) -> String {
        // Regex pattern for any integer number
        return "Finishing transaction '\\d+' for product '\(productIdentifier)'"
    }

    static let finishedPostingCachedMetadataLog = "Finished syncing all cached transaction metadata"
}

// MARK: - Extensions

extension BaseStoreKitIntegrationTests {

    @MainActor
    func printReceiptContent() async {
        guard Purchases.isConfigured else {
            Logger.error(TestMessage.unable_parse_receipt_without_sdk)
            return
        }

        await self.printReceipt()
        await self.printStoreKit2Transactions()
    }

    private func printReceipt() async {
        do {
            let receipt = try await self.purchases.fetchReceipt(.always)
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

    private func printStoreKit2Transactions() async {
        do {
            let transactions = await StoreKit.Transaction.currentEntitlements.extractValues()
            Logger.appleWarning(TestMessage.current_entitlements(transactions))
        }

        do {
            let transactions = await StoreKit.Transaction.unfinished.extractValues()
            Logger.appleWarning(TestMessage.unfinished_transactions(transactions))
        }
    }

}

extension FileString {

    // See Nimble's FileString definition
    init(fromStaticString staticString: StaticString) {
    #if !canImport(Darwin)
    // Nimble's FileString == StaticString
    self = staticString
    #else
    // Nimble's FileString == String
    self = String(describing: staticString)
    #endif
    }
}
