//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PresentIfNeededTests.swift
//
//  Created by Nacho Soto on 7/31/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
class PresentIfNeededTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    func testPresentWithPurchaseStarted() throws {
        self.continueAfterFailure = false

        let handler = Self.purchaseHandler.with(delay: 3)
        var packageBeingPurchased: Package?

        let dispose = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: handler) { _ in
                return true
            } purchaseStarted: { aPackage in
                packageBeingPurchased = aPackage
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()
        let task = Task.detached {
            _ = try await handler.purchase(package: Self.package)
        }

        defer {
            task.cancel()
            dispose()
        }

        expect(packageBeingPurchased).toEventuallyNot(beNil())
        task.cancel()
    }

    func testPresentWithPurchaseHandler() throws {
        var customerInfo: CustomerInfo?

        _ = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: Self.purchaseHandler) { _ in
                return true
            } purchaseCompleted: {
                customerInfo = $0
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testPresentWithPurchaseFailureHandler() throws {
        var error: NSError?

        _ = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: Self.failingHandler) { _ in
                return true
            } purchaseFailure: {
                error = $0
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()

        Task {
            _ = try? await Self.failingHandler.purchase(package: Self.package)
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    func testPresentWithRestoreStarted() throws {
        self.continueAfterFailure = false

        let handler = Self.purchaseHandler.with(delay: 3)
        var started = false

        let dispose = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: handler) { _ in
                return true
            } restoreStarted: {
                started = true
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()
        let task = Task.detached {
            _ = try await handler.restorePurchases()
        }

        defer {
            task.cancel()
            dispose()
        }

        expect(started).toEventually(beTrue())
        task.cancel()
    }

    func testPresentWithRestoreHandler() throws {
        var customerInfo: CustomerInfo?

        _ = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: Self.purchaseHandler) { _ in
                return true
            } restoreCompleted: {
                customerInfo = $0
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
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
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: Self.failingHandler) { _ in
                return true
            } restoreFailure: {
                error = $0
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()

        Task {
            _ = try? await Self.failingHandler.restorePurchases()
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    func testPresentWithMyAppPurchasingLogic() throws {
        self.continueAfterFailure = false

        var packageBeingPurchased: Package?

        let handler = Self.externalPurchaseHandler(performPurchase: { packageToPurchase in
            packageBeingPurchased = packageToPurchase
            return (userCancelled: false, error: nil)
        }, performRestore: {
            return (success: true, error: nil)
        })

        let dispose = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: handler) { _ in
                return true
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()
        let task = Task.detached {
            _ = try await handler.purchase(package: Self.package)
        }

        defer {
            task.cancel()
            dispose()
        }

        expect(packageBeingPurchased).toEventuallyNot(beNil())
        task.cancel()
    }

    func testPresentWithMyAppRestoreLogic() throws {
        self.continueAfterFailure = false

        var restored = false

        let handler = Self.externalPurchaseHandler(performPurchase: { _ in
            return (userCancelled: false, error: nil)
        }, performRestore: {
            restored = true
            return (success: true, error: nil)
        })

        let dispose = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: handler) { _ in
                return true
            } restoreCompleted: { _ in
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()
        let task = Task.detached {
            _ = try await handler.restorePurchases()
        }

        defer {
            task.cancel()
            dispose()
        }

        expect(restored).toEventually(beTrue())
        task.cancel()
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
