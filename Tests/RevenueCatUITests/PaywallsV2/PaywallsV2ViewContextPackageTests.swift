//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsV2ViewContextPackageTests.swift

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallsV2ViewContextPackageTests: TestCase {

    // MARK: - makeSelectedPackageContext

    @MainActor
    func testMakeSelectedPackageContextUsesProvidedDefault() throws {
        let state = try Self.makePaywallState(defaultPackage: TestData.monthlyPackage)

        let context = PaywallsV2View.makeSelectedPackageContext(
            from: state,
            defaultPackage: TestData.monthlyPackage,
            workflowPackages: nil,
            showZeroDecimalPlacePrices: true
        )

        expect(context.package?.identifier) == TestData.monthlyPackage.identifier
    }

    @MainActor
    func testMakeSelectedPackageContextReturnsNilWhenNoDefault() throws {
        let state = try Self.makePaywallState(defaultPackage: nil)

        let context = PaywallsV2View.makeSelectedPackageContext(
            from: state,
            defaultPackage: nil,
            workflowPackages: nil,
            showZeroDecimalPlacePrices: true
        )

        expect(context.package).to(beNil())
    }

    // MARK: - effectiveDefaultPackage

    func testEffectiveDefaultPackagePrefersContextPackageWhenResolvableInStep() {
        // When a user selected a package on the previous step, it should carry forward
        // and take priority over the workflow default on the new step.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.monthlyPackage,
            contextPackage: TestData.annualPackage,
            stepPackages: [TestData.monthlyPackage, TestData.annualPackage]
        )
        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    func testEffectiveDefaultPackageReturnsWorkflowDefaultOnPackagelessStep() {
        // On a truly packageless step, contextPackage can't be resolved —
        // the workflow default applies so price/period variables still render.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: nil,
            workflowDefaultPackage: TestData.monthlyPackage,
            contextPackage: TestData.annualPackage,
            stepPackages: []
        )
        expect(result?.identifier) == TestData.monthlyPackage.identifier
    }

    func testEffectiveDefaultPackageReturnsWorkflowDefaultWhenNoContextCarried() {
        // On the first workflow step there's no prior selection (contextPackage is nil),
        // so the workflow default applies as the initial display/variable-resolution package.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.annualPackage,
            contextPackage: nil,
            stepPackages: [TestData.monthlyPackage, TestData.annualPackage]
        )
        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    func testEffectiveDefaultPackageReturnsNilWhenBothDefaultsAreNil() {
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: nil,
            workflowDefaultPackage: nil,
            contextPackage: nil,
            stepPackages: []
        )
        expect(result).to(beNil())
    }

    func testEffectiveDefaultPackageReturnsWorkflowDefaultWhenContextNotInStep() {
        // contextPackage exists but isn't in the step's offering (cross-offering).
        // The workflow default should apply for display on this step.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.monthlyPackage,
            contextPackage: TestData.annualPackage,
            stepPackages: [TestData.weeklyPackage]
        )
        expect(result?.identifier) == TestData.monthlyPackage.identifier
    }

    func testEffectiveDefaultPackageWorkflowOverridesPageDefault() {
        // Workflow default takes priority over the page's own default.
        let result = PaywallsV2View.effectiveDefaultPackage(
            pageDefaultPackage: TestData.monthlyPackage,
            workflowDefaultPackage: TestData.annualPackage
        )
        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    // MARK: - validatedContextPackage

    func testValidatedContextPackageReturnsPackageWhenFoundInOffering() {
        let packages = [TestData.monthlyPackage, TestData.annualPackage]

        let result = PaywallsV2View.validatedContextPackage(TestData.annualPackage, in: packages)

        expect(result?.identifier) == TestData.annualPackage.identifier
    }

    func testValidatedContextPackageReturnsNilWhenNotInOffering() {
        let packages = [TestData.monthlyPackage]

        let result = PaywallsV2View.validatedContextPackage(TestData.annualPackage, in: packages)

        expect(result).to(beNil())
    }

    func testValidatedContextPackageReturnsNilWhenContextPackageIsNil() {
        let packages = [TestData.monthlyPackage, TestData.annualPackage]

        let result = PaywallsV2View.validatedContextPackage(nil, in: packages)

        expect(result).to(beNil())
    }

    func testValidatedContextPackageReturnsNilWhenOfferingIsEmpty() {
        let result = PaywallsV2View.validatedContextPackage(TestData.annualPackage, in: [])

        expect(result).to(beNil())
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallsV2ViewContextPackageTests {

    @MainActor
    static func makePaywallState(defaultPackage: Package?) throws -> PaywallState {
        var factory = ViewModelFactory()

        if let pkg = defaultPackage {
            factory.packageValidator.add(PackageValidator.PackageInfo(
                package: pkg,
                isSelectedByDefault: true,
                isStaticallyVisible: true,
                promotionalOfferProductCode: nil
            ))
        }

        let componentsConfig = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: []),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )

        let rootViewModel = try factory.toRootViewModel(
            componentsConfig: componentsConfig,
            offering: mockOffering,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            uiConfigProvider: try makeUIConfigProvider(),
            colorScheme: .light
        )

        let packageInfos: [PaywallState.PackageInfo] = defaultPackage.map { [($0, nil)] } ?? []

        return PaywallState(
            componentsConfig: componentsConfig,
            viewModelFactory: factory,
            packageInfos: packageInfos,
            rootViewModel: rootViewModel,
            showZeroDecimalPlacePrices: true
        )
    }

    static func makeUIConfigProvider() throws -> UIConfigProvider {
        let json = """
        {
          "app": { "colors": {}, "fonts": {} },
          "localizations": {}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let uiConfig = try decoder.decode(UIConfig.self, from: data)
        return UIConfigProvider(uiConfig: uiConfig)
    }

    static var mockOffering: Offering {
        .init(
            identifier: "test_offering",
            serverDescription: "Test Offering",
            metadata: [:],
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

}

#endif
