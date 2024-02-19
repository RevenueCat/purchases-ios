//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFooterTests.swift
//
//  Created by Josh Holtz on 8/22/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
class PaywallFooterTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    func testPresentWithPurchaseStarted() throws {
        var started = false

        try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.purchaseHandler,
                purchaseStarted: { started = true }
            )
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(started).toEventually(beTrue())
    }

    func testPresentWithPurchaseHandler() throws {
        var customerInfo: CustomerInfo?

        try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.purchaseHandler,
                purchaseCompleted: { customerInfo = $0 }
            )
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testPresentWithPurchaseFailureHandler() throws {
        var error: NSError?

        try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.failingHandler,
                purchaseFailure: { error = $0 }
            )
            .addToHierarchy()

        Task {
            _ = try? await Self.failingHandler.purchase(package: Self.package)
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    func testPresentWithRestoreStarted() throws {
        var started = false

        try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.purchaseHandler,
                restoreStarted: { started = true }
            )
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.restorePurchases()
        }

        expect(started).toEventually(beTrue())
    }

    func testPresentWithRestoreHandler() throws {
        var customerInfo: CustomerInfo?

        try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.purchaseHandler,
                restoreCompleted: { customerInfo = $0 }
            )
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.restorePurchases()
            // Simulates what `RestorePurchasesButton` does after dismissing the alert.
            Self.purchaseHandler.setRestored(TestData.customerInfo)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testPresentWithRestoreFailureHandler() throws {
        var error: NSError?

        try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.failingHandler,
                restoreFailure: { error = $0 }
            )
            .addToHierarchy()

        Task {
            _ = try? await Self.failingHandler.restorePurchases()
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let failingHandler: PurchaseHandler = .failing(failureError)
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage
    private static let failureError: Error = ErrorCode.storeProblemError

}

#endif
