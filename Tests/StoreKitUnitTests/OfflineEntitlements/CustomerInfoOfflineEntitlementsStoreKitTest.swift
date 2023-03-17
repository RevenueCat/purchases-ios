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

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    // TODO: test:
    // - Not found in mapping
    // - Product with multiple entitlements
    // - Multiple purchased transactions

    func testSimpleCustomerInfo() async throws {
        let transaction = try await self.createTransactionWithPurchase()
        let entitlementID = "pro_1"

        let sandbox: Bool = .random()
        let sandboxDetector = MockSandboxEnvironmentDetector(isSandbox: sandbox)

        let mapping: ProductEntitlementMapping = .init(
            entitlementsByProduct: [
                transaction.productID: [entitlementID]
            ]
        )

        let info = CustomerInfo(
            from: [.init(from: transaction, sandboxEnvironmentDetector: sandboxDetector)],
            mapping: mapping,
            sandboxEnvironmentDetector: sandboxDetector
        )

        expect(info.firstSeen).to(beCloseToNow())
        expect(info.managementURL).to(beNil())
        expect(info.originalAppUserId).toNot(beEmpty())
        expect(IdentityManager.userIsAnonymous(info.originalAppUserId)) == true
        expect(info.originalApplicationVersion).to(beNil()) // TODO
        expect(info.originalPurchaseDate).to(beCloseToNow())
        expect(info.activeSubscriptions) == [transaction.productID]

        expect(info.nonSubscriptions).to(beEmpty()) // TODO: ?
        expect(info.entitlements.all).to(haveCount(1))
        expect(info.entitlements.verification) == .verified // TODO

        let entitlement = try XCTUnwrap(info.entitlements.all.values.onlyElement)

        expect(entitlement.isActive) == true
        expect(entitlement.identifier) == entitlementID
        expect(entitlement.productIdentifier) == transaction.productID
        expect(entitlement.billingIssueDetectedAt).to(beNil())
        expect(entitlement.expirationDate)
            .to(beCloseToDate(
                Date().addingTimeInterval(DispatchTimeInterval.days(1).seconds)
            ))
        expect(entitlement.isSandbox) == sandbox
        expect(entitlement.originalPurchaseDate).to(beCloseToNow())
        expect(entitlement.latestPurchaseDate).to(beCloseToNow())
        expect(entitlement.ownershipType) == .purchased
        expect(entitlement.periodType) == .trial
        expect(entitlement.store) == .appStore
        expect(entitlement.unsubscribeDetectedAt).to(beNil())
    }

}

// MARK: -

private func beCloseToNow() -> Predicate<Date> {
    return beCloseToDate(Date())
}

private func beCloseToDate(_ expectedValue: Date) -> Predicate<Date> {
    return beCloseTo(expectedValue, within: 1)
}
