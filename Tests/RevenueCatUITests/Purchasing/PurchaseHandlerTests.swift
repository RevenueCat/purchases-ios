//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHandlerTests.swift
//
//  Created by Nacho Soto on 7/31/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PurchaseHandlerTests: TestCase {

    func testInitialState() async throws {
        let handler: PurchaseHandler = .mock()

        expect(handler.purchasedCustomerInfo).to(beNil())
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchased) == false
        expect(handler.restored) == false
        expect(handler.actionInProgress) == false
    }

    func testPurchaseSetsCustomerInfo() async throws {
        let handler: PurchaseHandler = .mock()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(handler.purchasedCustomerInfo) === TestData.customerInfo
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchased) == true
        expect(handler.actionInProgress) == false
    }

    func testCancellingPurchase() async throws {
        let handler: PurchaseHandler = .cancelling()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
        expect(handler.purchasedCustomerInfo).to(beNil())
        expect(handler.purchased) == false
        expect(handler.actionInProgress) == false
    }

    func testRestorePurchases() async throws {
        let handler: PurchaseHandler = .mock()

        let result = try await handler.restorePurchases()

        expect(result.info) === TestData.customerInfo
        expect(result.success) == false
        expect(handler.restored) == true
        expect(handler.restoredCustomerInfo) === TestData.customerInfo
        expect(handler.purchasedCustomerInfo).to(beNil())
        expect(handler.actionInProgress) == false
    }

    func testRestorePurchasesWithNoTransactions() async throws {
        let handler: PurchaseHandler = .mock(customerInfo: TestData.customerInfoWithSubscriptions)

        let result = try await handler.restorePurchases()
        expect(result.info) === TestData.customerInfoWithSubscriptions
        expect(result.success) == true
    }

}

#endif
