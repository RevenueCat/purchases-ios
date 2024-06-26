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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class ExternalPurchaseAndRestoreTests: TestCase {

    func testHandleExternalPurchasePaywall() throws {
        var completed = false
        var customPurchaseCodeExecuted = false
        var callbackOrder = [String]()

        var purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: false, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { package in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { customerInfo in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { error in
            callbackOrder.append("onPurchaseFailure")
        }
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(callbackOrder).toEventually(equal(["onPurchaseStarted", "performPurchase", "onPurchaseCompleted"]))
    }

    func testHandleExternalPurchaseCancelledPaywall() throws {
        var completed = false
        var customPurchaseCodeExecuted = false
        var callbackOrder = [String]()

        var purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: true, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { package in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { customerInfo in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { error in
            callbackOrder.append("onPurchaseFailure")
        }
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(callbackOrder).toEventually(equal(["onPurchaseStarted", "performPurchase", "onPurchaseCancelled"]))
    }


    func testHandleExternalPurchaseFailedPaywall() throws {
        var completed = false
        var customPurchaseCodeExecuted = false
        var callbackOrder = [String]()

        var purchasHandler = Self.externalPurchaseHandler { _ in
            callbackOrder.append("performPurchase")
            return (userCancelled: false, error: TestError.error)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
        .onPurchaseStarted { package in
            callbackOrder.append("onPurchaseStarted")
        }
        .onPurchaseCompleted { customerInfo in
            callbackOrder.append("onPurchaseCompleted")
        }
        .onPurchaseCancelled {
            callbackOrder.append("onPurchaseCancelled")
        }
        .onPurchaseFailure { error in
            callbackOrder.append("onPurchaseFailure")
        }
        .addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
        }

        expect(callbackOrder).toEventually(equal(["onPurchaseStarted", "performPurchase", "onPurchaseFailure"]))
    }

    func testHandleExternalRestore() throws {
        var completed = false
        var customerInfo: CustomerInfo?
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
            return (userCancelled: true, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: true, error: nil)
        }

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
            .onRestoreStarted({
                callbackOrder.append("onRestoreStarted")
            })
            .onRestoreCompleted({ info in
                callbackOrder.append("onRestoreCompleted")
                customerInfo = info
            })
            .onRestoreFailure({ error in
                callbackOrder.append("onRestoreFailure")
            })
            .addToHierarchy()

        Task {
            _ = try await purchasHandler.restorePurchases()
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(customerInfo).toEventually(be(TestData.customerInfo))
        expect(callbackOrder).toEventually(equal(["onRestoreStarted", "performRestore", "onRestoreCompleted"]))
    }

    func testHandleExternalRestoreWFailure() throws {
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
            return (userCancelled: true, error: nil)
        } performRestore: {
            callbackOrder.append("performRestore")
            return (success: false, error: TestError.error)
        }

        try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: purchasHandler
        )
            .onRestoreStarted({
                callbackOrder.append("onRestoreStarted")
            })
            .onRestoreCompleted({ info in
                callbackOrder.append("onRestoreCompleted")
            })
            .onRestoreFailure({ error in
                callbackOrder.append("onRestoreFailure")
            })
            .addToHierarchy()

        Task {
            _ = try await purchasHandler.restorePurchases()
        }

        expect(callbackOrder).toEventually(equal(["onRestoreStarted", "performRestore", "onRestoreFailure"]))
    }

    func testHandleExternalPurchaseWithoutPurchaseHandler() throws {
        var errorThrown = false

        let purchasHandler = Self.externalPurchaseHandler()

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        try PaywallView(configuration: config).addToHierarchy()

        Task {
            do {
                _ = try await purchasHandler.purchase(package: Self.package)
            } catch {
                errorThrown = true
            }
        }

        expect(errorThrown).toEventually(beTrue())
    }

    func testHandleExternalRestoreWithoutRestoreHandler() throws {
        var errorThrown = false

        let purchasHandler = Self.externalPurchaseHandler()

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        try PaywallView(configuration: config).addToHierarchy()

        Task {
            do {
                _ = try await purchasHandler.restorePurchases()
            } catch {
                errorThrown = true
            }
        }

        expect(errorThrown).toEventually(beTrue())
    }


    func testHandleInternalRestoreWithPurchaseHandlers() throws {
        var completed = false
        var customRestoreCodeExecuted = false

        let purchasHandler = Self.internalPurchaseHandler { _ in
            return (userCancelled: true, error: nil)
        } performRestore: {
            customRestoreCodeExecuted = true
            return (success: true, error: nil)
        }

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        try PaywallView(configuration: config).addToHierarchy()

        Task {
            // expect a warning logged to the console
            _ = try await purchasHandler.restorePurchases()
            completed = true
        }

        expect(completed).toEventually(beTrue())
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
