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

#if !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor
class PaywallFooterTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    func testPresentWithPurchaseHandler() throws {
        var customerInfo: CustomerInfo?

        try Text("")
            .paywallFooter(offering: Self.offering,
                           customerInfo: TestData.customerInfo,
                           introEligibility: .producing(eligibility: .eligible),
                           purchaseHandler: Self.purchaseHandler) {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package,
                                                        with: .fullScreen)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage

}

#endif
