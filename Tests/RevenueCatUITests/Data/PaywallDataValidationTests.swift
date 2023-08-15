//
//  PaywallDataValidationTests.swift
//  
//
//  Created by Nacho Soto on 8/15/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PaywallDataValidationTests: TestCase {

    func testValidateMissingPaywall() {
        let offering = TestData.offeringWithNoPaywall
        let result = TestData.offeringWithNoPaywall.validatedPaywall()

        Self.verifyPackages(in: result.displayablePaywall, match: offering.availablePackages)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .missingPaywall
    }

    func testValidateValidPaywall() {
        let offering = TestData.offeringWithSinglePackageFeaturesPaywall
        let result = offering.validatedPaywall()

        expect(result.displayablePaywall) == offering.paywall
        expect(result.error).to(beNil())
    }

    func testUnrecognizedVariableGeneratesDefaultPaywall() {
        let offering = TestData.offeringWithMultiPackagePaywall
        let paywall = offering
            .with(localization: .init(
                title: "Title with {{ unrecognized_variable }}",
                callToAction: "{{ future_variable }}",
                offerDetails: nil
            ))
        let result = paywall.validatedPaywall()

        Self.verifyPackages(in: result.displayablePaywall, match: offering.paywall)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .invalidVariables(["unrecognized_variable", "future_variable"])
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallDataValidationTests {

    static func verifyPackages(
        in paywall: PaywallData,
        match other: PaywallData?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            paywall.config.packages
        ) == other?.config.packages
    }

    static func verifyPackages(
        in paywall: PaywallData,
        match packages: [Package],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            paywall.config.packages
        ) == packages.map(\.identifier)
    }

    static func snapshot(
        _ paywall: PaywallData,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            matching: paywall.withTestAssetBaseURL,
            as: .formattedJson,
            file: file,
            testName: testName,
            line: line
        )
    }

    static func offering(with paywall: PaywallData?) -> Offering {
        return .init(
            identifier: "offering",
            serverDescription: "Offering",
            paywall: paywall,
            availablePackages: TestData.packages
        )
    }

}
