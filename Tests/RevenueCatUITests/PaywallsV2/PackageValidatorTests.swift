//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageValidatorTests.swift
//
//  Created by RevenueCat on 3/26/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PackageValidatorTests: TestCase {

    func testDefaultSelectedPackageSkipsStaticallyHiddenSelectedPackage() {
        let validator = PackageValidator()

        validator.add((
            package: TestData.monthlyPackage,
            isSelectedByDefault: true,
            isStaticallyVisible: false,
            promotionalOfferProductCode: nil
        ))
        validator.add((
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            isStaticallyVisible: true,
            promotionalOfferProductCode: nil
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage?.identifier,
            TestData.annualPackage.identifier
        )
    }

    func testDefaultSelectedPackageFallsBackToFirstStaticallyVisiblePackage() {
        let validator = PackageValidator()

        validator.add((
            package: TestData.monthlyPackage,
            isSelectedByDefault: false,
            isStaticallyVisible: false,
            promotionalOfferProductCode: nil
        ))
        validator.add((
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            isStaticallyVisible: true,
            promotionalOfferProductCode: nil
        ))
        validator.add((
            package: TestData.weeklyPackage,
            isSelectedByDefault: false,
            isStaticallyVisible: true,
            promotionalOfferProductCode: nil
        ))

        XCTAssertEqual(
            validator.defaultSelectedPackage?.identifier,
            TestData.annualPackage.identifier
        )
    }

    func testDefaultSelectedPackageReturnsNilWhenAllPackagesAreStaticallyHidden() {
        let validator = PackageValidator()

        validator.add((
            package: TestData.monthlyPackage,
            isSelectedByDefault: true,
            isStaticallyVisible: false,
            promotionalOfferProductCode: nil
        ))
        validator.add((
            package: TestData.annualPackage,
            isSelectedByDefault: false,
            isStaticallyVisible: false,
            promotionalOfferProductCode: nil
        ))

        XCTAssertNil(validator.defaultSelectedPackage)
    }

    func testViewModelFactoryTracksStaticVisibilityForDefaultSelection() throws {
        let offering = Offering(
            identifier: "default",
            serverDescription: "",
            availablePackages: [TestData.monthlyPackage, TestData.annualPackage],
            webCheckoutUrl: nil
        )
        let localizationProvider = LocalizationProvider(
            locale: Locale(identifier: "en_US"),
            localizedStrings: ["package_label": .string("Package")]
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()
        let packageValidator = PackageValidator()

        _ = try factory.toViewModel(
            component: .package(
                Self.makePackageComponent(
                    packageID: TestData.monthlyPackage.identifier,
                    isSelectedByDefault: true,
                    visible: false
                )
            ),
            packageValidator: packageValidator,
            firstItemIgnoresSafeAreaInfo: nil,
            purchaseButtonCollector: nil,
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            colorScheme: .light
        )

        _ = try factory.toViewModel(
            component: .package(
                Self.makePackageComponent(
                    packageID: TestData.annualPackage.identifier,
                    isSelectedByDefault: false,
                    visible: nil
                )
            ),
            packageValidator: packageValidator,
            firstItemIgnoresSafeAreaInfo: nil,
            purchaseButtonCollector: nil,
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            colorScheme: .light
        )

        XCTAssertEqual(
            packageValidator.defaultSelectedPackage?.identifier,
            TestData.annualPackage.identifier
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageValidatorTests {

    static func makePackageComponent(
        packageID: String,
        isSelectedByDefault: Bool,
        visible: Bool?
    ) -> PaywallComponent.PackageComponent {
        return PaywallComponent.PackageComponent(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            visible: visible,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [
                    .text(
                        .init(
                            text: "package_label",
                            color: .init(light: .hex("#000000"))
                        )
                    )
                ]
            )
        )
    }

}

#endif
