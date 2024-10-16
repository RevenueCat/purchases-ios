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
        var packageBeingPurchased: Package?

        _ = try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: Self.purchaseHandler,
                purchaseStarted: { package in packageBeingPurchased = package }
            )
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(packageBeingPurchased).toEventually(be(Self.package))
    }

    func testPresentWithPurchaseHandler() throws {
        var customerInfo: CustomerInfo?

        _ = try Text("")
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

        _ = try Text("")
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

        _ = try Text("")
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

        _ = try Text("")
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

        _ = try Text("")
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

    func testExternalRestoreHandler() async throws {
        var restoreCodeExecuted = false

        let handler = Self.externalPurchaseHandler(performPurchase: { _ in
            return (userCancelled: true, error: nil)
        }, performRestore: {
            restoreCodeExecuted = true
            return (success: true, error: nil)
        })

        _ = try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: handler
            )
            .addToHierarchy()

        _ = try await handler.restorePurchases()

        expect(restoreCodeExecuted).to(beTrue())
    }

    func testExternalPurchaseHandler() async throws {
        var purchaseCodeExecuted = false

        let handler = Self.externalPurchaseHandler(performPurchase: { _ in
            purchaseCodeExecuted = true
            return (userCancelled: true, error: nil)
        }, performRestore: {
            return (success: true, error: nil)
        })

        _ = try Text("")
            .paywallFooter(
                offering: Self.offering,
                customerInfo: TestData.customerInfo,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: handler
            )
            .addToHierarchy()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(purchaseCodeExecuted).to(beTrue())
    }

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let failingHandler: PurchaseHandler = .failing(failureError)
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage
    private static let failureError: Error = ErrorCode.storeProblemError
    private static func externalPurchaseHandler(performPurchase: PerformPurchase? = nil,
                                                performRestore: PerformRestore? = nil)
    -> PurchaseHandler {
        .mock(purchasesAreCompletedBy: .myApp,
              performPurchase: performPurchase,
              performRestore: performRestore)
    }

}

#endif
