//
//  PurchaseCompletedHandlerTests.swift
//  
//
//  Created by Nacho Soto on 7/31/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
class PurchaseCompletedHandlerTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    func testOnPurchaseCompletedWithCancellation() throws {
        let handler: PurchaseHandler = .cancelling()

        var customerInfo: CustomerInfo?
        var purchased = false

        PaywallView(
            offering: Self.offering.withLocalImages,
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

        PaywallView(
            offering: Self.offering.withLocalImages,
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

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage
}

#endif
