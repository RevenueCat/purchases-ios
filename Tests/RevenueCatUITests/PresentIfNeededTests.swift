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
@_spi(Internal) @testable import RevenueCatUI
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

    func testInlinePresentWithPurchaseHandlerDismissesOnce() throws {
        let handler: PurchaseHandler = .mock()
        var customerInfo: CustomerInfo?
        var dismissCount = 0

        let dispose = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: handler,
                                    presentationMode: .inline()) { _ in
                return true
            } purchaseCompleted: {
                customerInfo = $0
            } onDismiss: {
                dismissCount += 1
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()

        defer { dispose() }

        Task {
            _ = try await handler.purchase(package: Self.package)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
        expect(dismissCount).toEventually(equal(1))
    }

    func testInlinePresentWithPurchaseHandlerDismissesAfterCustomerInfoRefresh() throws {
        let handler: PurchaseHandler = .mock()
        let scenePhaseController = ScenePhaseController()
        var dismissCount = 0

        let dispose = try InlinePaywall(
            scenePhaseController: scenePhaseController,
            purchaseHandler: handler,
            onDismiss: {
                dismissCount += 1
            }
        )
        .addToHierarchy()

        defer { dispose() }

        Task {
            _ = try await handler.purchase(package: Self.package)
        }

        expect(dismissCount).toEventually(equal(1))

        scenePhaseController.scenePhase = .inactive
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        scenePhaseController.scenePhase = .active
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        Task {
            _ = try await handler.purchase(package: Self.package)
        }

        expect(dismissCount).toEventually(equal(2))
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
            Self.purchaseHandler.setRestored(TestData.customerInfo, success: false)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testRestoreWithoutUnlockedEntitlementsDoesNotDismissPaywall() throws {
        let handler: PurchaseHandler = .mock()
        var dismissed = false

        let dispose = try Text("")
            .presentPaywallIfNeeded(offering: Self.offering,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: handler) { info in
                return info.entitlements.activeInCurrentEnvironment.isEmpty
            } onDismiss: {
                dismissed = true
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .addToHierarchy()

        let task = Task {
            _ = try await handler.restorePurchases()
            handler.setRestored(TestData.customerInfo, success: false)
        }

        expect(dismissed).toEventually(beFalse())

        task.cancel()
        dispose()
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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private final class ScenePhaseController: ObservableObject {

    @Published
    var scenePhase: ScenePhase = .active

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct InlinePaywall: View {

    @ObservedObject
    var scenePhaseController: ScenePhaseController

    let purchaseHandler: PurchaseHandler
    let onDismiss: () -> Void

    var body: some View {
        Text("")
            .presentPaywallIfNeeded(offering: TestData.offeringWithNoIntroOffer,
                                    introEligibility: .producing(eligibility: .eligible),
                                    purchaseHandler: self.purchaseHandler,
                                    presentationMode: .inline()) { _ in
                return true
            } onDismiss: {
                self.onDismiss()
            } customerInfoFetcher: {
                return TestData.customerInfo
            }
            .environment(\.scenePhase, self.scenePhaseController.scenePhase)
    }

}

#endif
