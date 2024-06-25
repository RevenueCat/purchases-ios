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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class ExternalPurchaseAndRestoreTests: TestCase {

    func testHandleExternalPurchaseWithPurchaaseHandlers() throws {
        var completed = false
        var customPurchaseCodeExecuted = false

        let purchasHandler = Self.externalPurchaseHandler { _ in
            customPurchaseCodeExecuted = true
            return (userCancelled: true, error: nil)
        } performRestore: {
            return (success: true, error: nil)
        }

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        try PaywallView(configuration: config).addToHierarchy()

        Task {
            _ = try await purchasHandler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(customPurchaseCodeExecuted) == true
    }

    func testHandleExternalRestoreWithPurchaaseHandlers() throws {
        var completed = false
        var customRestoreCodeExecuted = false

        let purchasHandler = Self.externalPurchaseHandler { package in
            return (userCancelled: true, error: nil)
        } performRestore: {
            customRestoreCodeExecuted = true
            return (success: true, error: nil)
        }

        let config = PaywallViewConfiguration(purchaseHandler: purchasHandler)

        try PaywallView(configuration: config).addToHierarchy()

        Task {
            _ = try await purchasHandler.restorePurchases()
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(customRestoreCodeExecuted) == true
    }

    private static let package = TestData.annualPackage
    private static func externalPurchaseHandler(performPurchase: PerformPurchase? = nil,
                                                performRestore:  PerformRestore? = nil)
    -> PurchaseHandler {
        .mock(purchasesAreCompletedBy: .myApp,
              performPurchase: performPurchase,
              performRestore: performRestore)
    }
}
