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

        if #available(iOS 17.0, *) {
            try XCTSkipIf(true, "This test is currently not working on iOS 17")
        }
    }

    func testPresentWithPurchaseHandler() throws {
        var customerInfo: CustomerInfo?

        try Text("")
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

    func testPresentWithRestoreHandler() throws {
        var customerInfo: CustomerInfo?

        try Text("")
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
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage

}

#endif
