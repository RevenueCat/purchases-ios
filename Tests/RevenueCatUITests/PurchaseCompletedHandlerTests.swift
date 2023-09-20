//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseCompletedHandlerTests.swift
//
//  Created by Nacho Soto on 7/31/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PurchaseCompletedHandlerTests: TestCase {

    func testOnPurchaseCompletedWithCancellation() throws {
        let handler: PurchaseHandler = .cancelling()

        var customerInfo: CustomerInfo?
        var purchased = false

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: handler
        )
            .onPurchaseCompleted {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
            purchased = true
        }

        expect(purchased).toEventually(beTrue())
        expect(customerInfo).to(beNil())
    }

    func testOnPurchaseCompleted() throws {
        var customerInfo: CustomerInfo?

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onPurchaseCompleted {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testOnRestoreCompleted() throws {
        var customerInfo: CustomerInfo?

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onRestoreCompleted {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.restorePurchases()
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage
}

#endif
