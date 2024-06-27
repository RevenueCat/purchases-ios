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

    func testHandleExternalPurchasePaywall() async throws {
        var completed = false
        var callbackOrder = [String]()

        let purchasHandler = Self.externalPurchaseHandler { _ in
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

//        Task {
        _ = try await purchasHandler.purchase(package: Self.package)
        completed = true
//        }

        expect(completed).to(beTrue())
        expect(callbackOrder).to(equal(["onPurchaseStarted", "performPurchase", "onPurchaseCompleted"]))
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
