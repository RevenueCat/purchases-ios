//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallDataValidationTests.swift
//
//  Created by Nacho Soto on 8/15/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PaywallDataValidationTests: TestCase {

    func testValidateMissingPaywall() {
        let offering = TestData.offeringWithNoPaywall
        let result = TestData.offeringWithNoPaywall.validatedPaywall(locale: TestData.locale)

        Self.verifyPackages(in: result.displayablePaywall, match: offering.availablePackages)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .missingPaywall
    }

    func testValidateMissingPaywallWithSpanishLocalization() {
        let offering = TestData.offeringWithNoPaywall
        let result = TestData.offeringWithNoPaywall.validatedPaywall(locale: .init(identifier: "es_ES"))

        Self.verifyPackages(in: result.displayablePaywall, match: offering.availablePackages)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .missingPaywall
    }

    func testValidateValidPaywall() {
        let offering = TestData.offeringWithSinglePackageFeaturesPaywall
        let result = offering.validatedPaywall(locale: TestData.locale)

        expect(result.displayablePaywall) == offering.paywall
        expect(result.error).to(beNil())
    }

    func testUnrecognizedTemplateNameGeneratesDefaultPaywall() {
        let templateName = "unrecognized_template"

        let originalOffering = TestData.offeringWithMultiPackagePaywall
        let offering = originalOffering.with(templateName: templateName)
        let result = offering.validatedPaywall(locale: TestData.locale)

        Self.verifyPackages(in: result.displayablePaywall, match: originalOffering.paywall)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .invalidTemplate(templateName)
    }

    func testUnrecognizedVariableGeneratesDefaultPaywall() {
        let originalOffering = TestData.offeringWithMultiPackagePaywall
        let offering = originalOffering
            .with(localization: .init(
                title: "Title with {{ unrecognized_variable }}",
                callToAction: "{{ future_variable }}",
                offerDetails: nil
            ))
        let result = offering.validatedPaywall(locale: TestData.locale)

        Self.verifyPackages(in: result.displayablePaywall, match: originalOffering.paywall)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .invalidVariables(["unrecognized_variable", "future_variable"])
    }

    func testUnrecognizedVariableInFeaturesGeneratesDefaultPaywall() throws {
        let originalOffering = TestData.offeringWithMultiPackagePaywall
        var localization = try XCTUnwrap(originalOffering.paywall?.localizedConfiguration)
        localization.features = [
            .init(title: "{{ future_variable }}", content: "{{ new_variable }}"),
            .init(title: "{{ another_one }}")
        ]

        let offering = originalOffering.with(localization: localization)
        let result = offering.validatedPaywall(locale: TestData.locale)

        Self.verifyPackages(in: result.displayablePaywall, match: originalOffering.paywall)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .invalidVariables(["future_variable", "new_variable", "another_one"])
    }

    func testUnrecognizedIconsGeneratesDefaultPaywall() throws {
        let originalOffering = TestData.offeringWithMultiPackagePaywall
        var localization = try XCTUnwrap(originalOffering.paywall?.localizedConfiguration)
        localization.features = [
            .init(title: "Title 1", content: "Content 1", iconID: "unrecognized_icon_1"),
            .init(title: "Title 2", content: "Content 2", iconID: "unrecognized_icon_2")
        ]

        let offering = originalOffering.with(localization: localization)
        let result = offering.validatedPaywall(locale: TestData.locale)

        Self.verifyPackages(in: result.displayablePaywall, match: originalOffering.paywall)
        Self.snapshot(result.displayablePaywall)

        expect(result.error) == .invalidIcons(["unrecognized_icon_1", "unrecognized_icon_2"])
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
        #if os(watchOS)
        let test = testName + "-watchOS"
        #else
        let test = testName
        #endif

        assertSnapshot(
            matching: paywall.withTestAssetBaseURL,
            as: .formattedJson,
            file: file,
            testName: test,
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
