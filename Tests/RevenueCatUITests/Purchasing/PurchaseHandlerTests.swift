//
//  PurchaseHandlerTests.swift
//  
//
//  Created by Nacho Soto on 7/31/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
class PurchaseHandlerTests: TestCase {

    func testInitialState() async throws {
        let handler: PurchaseHandler = .mock()

        expect(handler.purchasedCustomerInfo).to(beNil())
        expect(handler.purchased) == false
        expect(handler.restored) == false
        expect(handler.actionInProgress) == false
    }

    func testPurchaseSetsCustomerInfo() async throws {
        let handler: PurchaseHandler = .mock()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(handler.purchasedCustomerInfo) === TestData.customerInfo
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

        _ = try await handler.restorePurchases()
        expect(handler.restored) == true
        expect(handler.actionInProgress) == false
    }

}

#endif
