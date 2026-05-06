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
    func testMakeSelectedPackageContextUsesStepDefault() throws {
        let state = try Self.makePaywallState(defaultPackage: TestData.monthlyPackage)

        let context = PaywallsV2View.makeSelectedPackageContext(
            from: state,
            showZeroDecimalPlacePrices: true
        )

        expect(context.package?.identifier) == TestData.monthlyPackage.identifier
    }

    @MainActor
    func testMakeSelectedPackageContextReturnsNilWhenStepHasNoPackages() throws {
        let state = try Self.makePaywallState(defaultPackage: nil)

        let context = PaywallsV2View.makeSelectedPackageContext(
            from: state,
            showZeroDecimalPlacePrices: true
        )

        expect(context.package).to(beNil())
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
