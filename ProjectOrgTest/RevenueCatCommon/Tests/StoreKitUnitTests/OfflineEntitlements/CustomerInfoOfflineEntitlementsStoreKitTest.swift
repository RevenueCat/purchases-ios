//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoOfflineEntitlementsStoreKitTest.swift
//
//  Created by Nacho Soto on 3/21/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable type_name

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class CustomerInfoOfflineEntitlementsStoreKitTest: StoreKitConfigTestCase {

    private var sandboxDetector: SandboxEnvironmentDetector!

    private static let userID: String = IdentityManager.generateRandomID()

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: .random())
    }

    func testSimpleCustomerInfo() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let entitlementID = "pro_1"

        let mapping: ProductEntitlementMapping = .init(
            entitlementsByProduct: [
                transaction.productID: [entitlementID]
            ]
        )

        let info = self.create(with: [transaction], mapping: mapping)

        expect(info.activeSubscriptions) == [transaction.productID]
        expect(info.nonSubscriptions).to(beEmpty())
        expect(info.entitlements.all).to(haveCount(1))

        let entitlement = try XCTUnwrap(info.entitlements.all.values.onlyElement)

        self.verifyInfo(info)
        try self.verifyEntitlement(entitlement,
                                   productID: transaction.productID,
                                   entitlementID: entitlementID,
                                   periodType: .trial,
                                   expiration: transaction.expirationDate)
    }

    func testRawData() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let entitlementID = "pro_1"

        let mapping: ProductEntitlementMapping = .init(
            entitlementsByProduct: [
                transaction.productID: [entitlementID]
            ]
        )

        let info = self.create(with: [transaction], mapping: mapping)
        expect(info.rawData).toNot(beEmpty())
        expect(info.rawData["entitlements"] as? [String: Any]).to(haveCount(1))
        expect(info.rawData["subscriptions"] as? [String: Any]).to(haveCount(1))

        let entitlement = try XCTUnwrap(info.entitlements.all.values.onlyElement)
        expect(entitlement.rawData).toNot(beEmpty())
        expect(Data.encodeJSON(entitlement.rawData)).to(matchJSONData(transaction.jsonRepresentation))
    }

    func testProductWithMultipleEntitlements() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let entitlement1 = "pro_1"
        let entitlement2 = "pro_2"

        let mapping: ProductEntitlementMapping = .init(
            entitlementsByProduct: [
                transaction.productID: [entitlement1, entitlement2]
            ]
        )

        let info = self.create(with: [transaction], mapping: mapping)

        expect(info.activeSubscriptions) == [transaction.productID]
        expect(info.nonSubscriptions).to(beEmpty())
        expect(info.entitlements.all).to(haveCount(2))

        self.verifyInfo(info)
        try self.verifyEntitlement(info.entitlements[entitlement1],
                                   productID: transaction.productID,
                                   entitlementID: entitlement1,
                                   periodType: .trial,
                                   expiration: transaction.expirationDate)
        try self.verifyEntitlement(info.entitlements[entitlement2],
                                   productID: transaction.productID,
                                   entitlementID: entitlement2,
                                   periodType: .trial,
                                   expiration: transaction.expirationDate)
    }

    func testProductNotFoundInMapping() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let entitlementID = "pro_1"

        let mapping: ProductEntitlementMapping = .init(
            entitlementsByProduct: [
                "different_product": [entitlementID]
            ]
        )

        let info = self.create(with: [transaction], mapping: mapping)

        self.verifyInfo(info)
        expect(info.activeSubscriptions) == [transaction.productID]
        expect(info.nonSubscriptions).to(beEmpty())
        expect(info.entitlements.all).to(beEmpty())
    }

    func testEmptyMapping() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let mapping: ProductEntitlementMapping = .empty

        let info = self.create(with: [transaction], mapping: mapping)

        self.verifyInfo(info)
        expect(info.activeSubscriptions) == [transaction.productID]
        expect(info.nonSubscriptions).to(beEmpty())
        expect(info.entitlements.all).to(beEmpty())
    }

    func testMultiplePurchasedProducts() async throws {
        let product1 = try await self.fetchSk2Product(Self.productID)
        let product2 = try await self.fetchSk2Product("com.revenuecat.annual_39.99_no_trial")
        let entitlement1 = "pro_1"
        let entitlement2 = "pro_2"
        let entitlement3 = "pro_3"

        let transaction1 = try await self.createTransactionWithPurchase(product: product1)
        let transaction2 = try await self.createTransactionWithPurchase(product: product2)

        let mapping: ProductEntitlementMapping = .init(entitlementsByProduct: [
            product1.id: [entitlement1],
            product2.id: [entitlement2, entitlement3]
        ])

        let info = self.create(with: [transaction1, transaction2], mapping: mapping)

        self.verifyInfo(info)
        expect(info.activeSubscriptions) == [product1.id, product2.id]
        expect(info.nonSubscriptions).to(beEmpty())
        expect(info.entitlements.all).to(haveCount(3))

        try self.verifyEntitlement(info.entitlements[entitlement1],
                                   productID: product1.id,
                                   entitlementID: entitlement1,
                                   periodType: .trial,
                                   expiration: transaction1.expirationDate)
        try self.verifyEntitlement(info.entitlements[entitlement2],
                                   productID: product2.id,
                                   entitlementID: entitlement2,
                                   periodType: .normal,
                                   expiration: transaction2.expirationDate)
        try self.verifyEntitlement(info.entitlements[entitlement3],
                                   productID: product2.id,
                                   entitlementID: entitlement3,
                                   periodType: .normal,
                                   expiration: transaction2.expirationDate)
    }

    func testOverlappingEntitlementsPrioritizeLongestExpiration() async throws {
        let product1 = try await self.fetchSk2Product("com.revenuecat.monthly_4.99.1_week_intro")
        let product2 = try await self.fetchSk2Product("com.revenuecat.annual_39.99_no_trial")
        let entitlementID = "pro"

        let transaction1 = try await self.createTransactionWithPurchase(product: product1)
        let transaction2 = try await self.createTransactionWithPurchase(product: product2)
        // Shuffle to avoid false positives, order should not matter
        let transactions = [transaction1, transaction2].shuffled()

        let mapping: ProductEntitlementMapping = .init(entitlementsByProduct: [
            product1.id: [entitlementID],
            product2.id: [entitlementID]
        ])

        let info = self.create(with: transactions, mapping: mapping)

        self.verifyInfo(info)
        expect(info.activeSubscriptions) == [product1.id, product2.id]
        expect(info.nonSubscriptions).to(beEmpty())
        expect(info.entitlements.all).to(haveCount(1))

        try self.verifyEntitlement(info.entitlements[entitlementID],
                                   productID: product2.id,
                                   entitlementID: entitlementID,
                                   periodType: .normal,
                                   expiration: transaction2.expirationDate)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension CustomerInfoOfflineEntitlementsStoreKitTest {

    func create(
        with transactions: [SK2Transaction],
        mapping: ProductEntitlementMapping
    ) -> CustomerInfo {
        return CustomerInfo(
            from: transactions.map {
                PurchasedSK2Product(from: $0, sandboxEnvironmentDetector: self.sandboxDetector)
            },
            mapping: mapping,
            userID: Self.userID,
            sandboxEnvironmentDetector: self.sandboxDetector
        )
    }

    func verifyInfo(_ info: CustomerInfo) {
        expect(info.firstSeen).to(beCloseToNow())
        expect(info.managementURL) == SystemInfo.appleSubscriptionsURL
        expect(info.originalAppUserId).toNot(beEmpty())
        expect(info.originalAppUserId) == Self.userID
        expect(info.originalApplicationVersion) == SystemInfo.buildVersion
        expect(info.originalPurchaseDate).to(beCloseToNow())
    }

    func verifyEntitlement(
        _ entitlement: EntitlementInfo?,
        productID: String,
        entitlementID: String,
        periodType: PeriodType,
        expiration: Date?,
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let entitlement = try XCTUnwrap(entitlement, file: file, line: line)

        expect(entitlement.isActive) == true
        expect(entitlement.identifier) == entitlementID
        expect(entitlement.productIdentifier) == productID
        expect(entitlement.billingIssueDetectedAt).to(beNil())
        if let expiration = expiration {
            expect(entitlement.expirationDate).to(beCloseToDate(expiration))
        } else {
            expect(entitlement.expirationDate).to(beNil())
        }
        expect(entitlement.isSandbox) == self.sandboxDetector.isSandbox
        expect(entitlement.originalPurchaseDate).to(beCloseToNow())
        expect(entitlement.latestPurchaseDate).to(beCloseToNow())
        expect(entitlement.ownershipType) == .purchased
        expect(entitlement.periodType) == periodType
        expect(entitlement.store) == .appStore
        expect(entitlement.unsubscribeDetectedAt).to(beNil())
        expect(entitlement.verification) == .verifiedOnDevice
    }

}
