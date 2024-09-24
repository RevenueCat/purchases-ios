//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseAndRestoreTests.swift
//
//  Created by James Borthwick on 2024-06-20.

import Foundation
import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

enum TestError: Error {
    case error
}

// swiftlint:disable type_body_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
// When this class is named ExternalPurchaseAndRestoreTests, the test testSamplePaywallWithLoadingEligibility in
// Template1ViewTests reliably fails on CI (although it passes when run locally).
class ZZExternalPurchaseAndRestoreTests: TestCase {

    func testExternalPurchasePaywallSuccessCallbackOrder() throws {
        var completed = false
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: false, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { _ in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { @MainActor _ in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { _ in
            callbackOrder.append("onPurchaseFailure")
        }
        .onRestoreStarted({
            callbackOrder.append("onRestoreStarted")
        })
        .onRestoreCompleted({ _ in
            callbackOrder.append("onRestoreCompleted")
        })
        .onRestoreFailure({ _ in
            callbackOrder.append("onRestoreFailure")
        })
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(callbackOrder).to(equal(["onPurchaseStarted", "performPurchase", "onPurchaseCompleted"]))
    }

    func testExternalPurchasePaywallCancelledCallbackOrder() throws {
        var completed = false
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: true, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { _ in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { _ in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { _ in
            callbackOrder.append("onPurchaseFailure")
        }
        .onRestoreStarted({
            callbackOrder.append("onRestoreStarted")
        })
        .onRestoreCompleted({ _ in
            callbackOrder.append("onRestoreCompleted")
        })
        .onRestoreFailure({ _ in
            callbackOrder.append("onRestoreFailure")
        })
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(callbackOrder).to(equal(["onPurchaseStarted", "performPurchase", "onPurchaseCancelled"]))
    }

    func testExternalPurchasePaywallFailureCallbackOrder() throws {
        var callbackOrder = [String]()
        var completed = false

        let purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: false, error: TestError.error)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { _ in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { _ in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { _ in
            callbackOrder.append("onPurchaseFailure")
        }
        .onRestoreStarted({
            callbackOrder.append("onRestoreStarted")
        })
        .onRestoreCompleted({ _ in
            callbackOrder.append("onRestoreCompleted")
        })
        .onRestoreFailure({ _ in
            callbackOrder.append("onRestoreFailure")
        })
        .addToHierarchy()

        Task {
            do {
                _ = try await purchasHandler.purchase(package: Self.package)
            } catch {
                completed = true
            }
        }

        expect(completed).toEventually(beTrue())
        expect(callbackOrder).to(equal(["onPurchaseStarted", "performPurchase", "onPurchaseFailure"]))
    }

    func testExternalPurchasePaywallFailureCorrectErrorIsPassed() throws {
        var passedError: Error?

        let purchasHandler = Self.externalPurchaseHandler { _ in
            return (userCancelled: false, error: TestError.error)
        } performRestore: {
            return (success: true, error: nil)
        }

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseFailure { error in
            passedError = error
        }
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
        }

        expect(passedError).toEventually(matchError(TestError.error))
    }

    func testExternalRestorePaywallSuccessCallbackOrder() throws {
        var completed = false
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: false, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { _ in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { @MainActor _ in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { _ in
            callbackOrder.append("onPurchaseFailure")
        }
        .onRestoreStarted({
            callbackOrder.append("onRestoreStarted")
        })
        .onRestoreCompleted({ _ in
            callbackOrder.append("onRestoreCompleted")
        })
        .onRestoreFailure({ _ in
            callbackOrder.append("onRestoreFailure")
        })
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.restorePurchases()
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(callbackOrder).to(equal(["onRestoreStarted", "performRestore", "onRestoreCompleted"]))
    }

    func testExternalRestoreReturnsCorrectCustomerInfo() throws {
        var customerInfo: CustomerInfo?
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
            return (userCancelled: true, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onRestoreCompleted({ info in
            callbackOrder.append("onRestoreCompleted")
            customerInfo = info
        })
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.restorePurchases()
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testExternalPurchasePaywallWithoutPurchaseHandlerThrowsErro() async throws {
        var errorThrown = false

        let purchasHandler = Self.externalPurchaseHandler()

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        _ = try PaywallView(configuration: config).addToHierarchy()

        do {
            _ = try await purchasHandler.purchase(package: Self.package)
        } catch {
            errorThrown = true
        }

        expect(errorThrown).to(beTrue())
    }

    func testExternalRestorePaywallWithoutPurchaseHandlerThrowsErro() async throws {
        var errorThrown = false

        let purchasHandler = Self.externalPurchaseHandler()

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        _ = try PaywallView(configuration: config).addToHierarchy()

        do {
            _ = try await purchasHandler.restorePurchases()
        } catch {
            errorThrown = true
        }

        expect(errorThrown).to(beTrue())
    }

    func testExternalRestorePaywallDoesNotExecuteWithInternalHandler() async throws {
        var customRestoreCodeExecuted = false

        let purchasHandler = Self.internalPurchaseHandler { _ in
            return (userCancelled: true, error: nil)
        } performRestore: {
            customRestoreCodeExecuted = true
            return (success: true, error: nil)
        }

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        _ = try PaywallView(configuration: config).addToHierarchy()

        // expect a warning logged to the console
        _ = try await purchasHandler.restorePurchases()

        expect(customRestoreCodeExecuted) == false
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
    private static func internalPurchaseHandler(performPurchase: PerformPurchase? = nil,
                                                performRestore: PerformRestore? = nil)
    -> PurchaseHandler {
        .mock(purchasesAreCompletedBy: .revenueCat,
              performPurchase: performPurchase,
              performRestore: performRestore)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallView {

    init(
        offering: Offering,
        customerInfo: CustomerInfo,
        introEligibility: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) {
        self.init(
            configuration: .init(
                offering: offering,
                customerInfo: customerInfo,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            )
        )
    }

}

#endif
