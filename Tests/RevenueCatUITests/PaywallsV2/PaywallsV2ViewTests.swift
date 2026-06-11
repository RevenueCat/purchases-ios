//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsV2ViewTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class IntroEligibilityPackagesTests: TestCase {

    private let annual = TestData.annualPackage
    private let monthly = TestData.monthlyPackage
    private let weekly = TestData.weeklyPackage

    func testReturnsScreenPackagesWhenNoWorkflowPackages() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual, monthly],
            workflowPackages: nil
        )

        expect(result) == [annual, monthly]
    }

    func testReturnsScreenPackagesWhenWorkflowPackagesEmpty() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual, monthly],
            workflowPackages: []
        )

        expect(result) == [annual, monthly]
    }

    // The bug: a workflow step with no package components (empty `paywallPackages`) inherits a selected
    // package from another step via `workflowPackages`. Eligibility must be computed for it, otherwise
    // `intro_offer_condition` overrides on that step never resolve.
    func testUsesWorkflowPackagesWhenScreenHasNoPackageComponents() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [],
            workflowPackages: [annual, monthly]
        )

        expect(result) == [annual, monthly]
    }

    func testMergesAndDeduplicatesScreenAndWorkflowPackages() {
        let result = PaywallsV2View.introEligibilityPackages(
            paywallPackages: [annual],
            workflowPackages: [annual, monthly, weekly]
        )

        // Screen packages come first, the inherited extras are appended once each.
        expect(result) == [annual, monthly, weekly]
    }

}

#endif
