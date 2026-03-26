//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentVisibilityTests.swift
//
//  Created by RevenueCat on 3/26/26.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageComponentVisibilityTests: BaseSnapshotTest {

    // MARK: - visible = false hides the package

    /// A package with `visible = false` should not appear in the rendered paywall.
    func testPackageWithVisibleFalseIsHidden() {
        Self.createPaywall(offering: Self.offeringWithHiddenPackage)
            .snapshot(size: Self.fullScreenSize)
    }

    /// A paywall where all packages are visible should show all of them.
    func testAllPackagesVisible() {
        Self.createPaywall(offering: Self.offeringWithAllPackagesVisible)
            .snapshot(size: Self.fullScreenSize)
    }

    // MARK: - visible via overrides (intro offer condition)

    /// When a package has `visible = false` in the base but `visible = true` in an intro_offer override,
    /// it should be hidden for ineligible users and visible for eligible users.
    func testPackageHiddenByDefaultShownForIntroEligible() {
        Self.createPaywall(
            offering: Self.offeringWithPackageHiddenUnlessIntroEligible,
            introEligibility: Self.eligibleChecker
        )
        .snapshot(size: Self.fullScreenSize)
    }

    func testPackageHiddenByDefaultRemainsHiddenForIntroIneligible() {
        Self.createPaywall(
            offering: Self.offeringWithPackageHiddenUnlessIntroEligible,
            introEligibility: Self.ineligibleChecker
        )
        .snapshot(size: Self.fullScreenSize)
    }

}

// MARK: - Offering factories

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageComponentVisibilityTests {

    /// Offering with 3 packages: weekly (visible), monthly (visible = false), annual (visible).
    /// Snapshot should show only 2 packages.
    static var offeringWithHiddenPackage: Offering {
        makeOffering(
            identifier: "hidden_package",
            packages: [
                makePackageComponent(
                    packageID: PackageType.weekly.identifier,
                    label: "Weekly",
                    visible: nil
                ),
                makePackageComponent(
                    packageID: PackageType.monthly.identifier,
                    label: "Monthly",
                    visible: false
                ),
                makePackageComponent(
                    packageID: PackageType.annual.identifier,
                    label: "Annual",
                    visible: nil
                )
            ]
        )
    }

    /// Offering with 3 packages all visible (no `visible` flag set).
    static var offeringWithAllPackagesVisible: Offering {
        makeOffering(
            identifier: "all_packages_visible",
            packages: [
                makePackageComponent(packageID: PackageType.weekly.identifier, label: "Weekly", visible: nil),
                makePackageComponent(packageID: PackageType.monthly.identifier, label: "Monthly", visible: nil),
                makePackageComponent(packageID: PackageType.annual.identifier, label: "Annual", visible: nil)
            ]
        )
    }

    /// Offering where the monthly package is hidden by default (`visible = false`)
    /// but shown when the user is eligible for an intro offer (`visible = true` override on intro_offer).
    static var offeringWithPackageHiddenUnlessIntroEligible: Offering {
        makeOffering(
            identifier: "hidden_unless_intro_eligible",
            packages: [
                makePackageComponent(packageID: PackageType.weekly.identifier, label: "Weekly", visible: nil),
                PaywallComponent.PackageComponent(
                    packageID: PackageType.monthly.identifier,
                    isSelectedByDefault: false,
                    visible: false,
                    applePromoOfferProductCode: nil,
                    stack: makePackageStack(label: "Monthly (Trial)"),
                    overrides: [
                        .init(conditions: [.introOffer], properties: .init(visible: true))
                    ]
                ),
                makePackageComponent(packageID: PackageType.annual.identifier, label: "Annual", visible: nil)
            ]
        )
    }

    // MARK: - Helpers

    static func makeOffering(
        identifier: String,
        packages: [PaywallComponent.PackageComponent]
    ) -> Offering {
        let packageComponents: [PaywallComponent] = packages.map { .package($0) }

        let rootStack = PaywallComponent.StackComponent(
            components: packageComponents,
            dimension: .vertical(.leading, .start),
            spacing: 8,
            backgroundColor: nil,
            padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16)
        )

        let data = PaywallComponentsData(
            templateName: "components",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(
                base: .init(
                    stack: rootStack,
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: ["en_US": [:]],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )

        return Offering(
            identifier: identifier,
            serverDescription: "",
            metadata: [:],
            paywallComponents: .init(
                uiConfig: PreviewUIConfig.make(),
                data: data
            ),
            availablePackages: [
                TestData.weeklyPackage,
                TestData.monthlyPackage,
                TestData.annualPackage
            ],
            webCheckoutUrl: nil
        )
    }

    static func makePackageComponent(
        packageID: String,
        label: String,
        visible: Bool?
    ) -> PaywallComponent.PackageComponent {
        return PaywallComponent.PackageComponent(
            packageID: packageID,
            isSelectedByDefault: false,
            visible: visible,
            applePromoOfferProductCode: nil,
            stack: makePackageStack(label: label)
        )
    }

    static func makePackageStack(label: String) -> PaywallComponent.StackComponent {
        return PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: label,
                    color: .init(light: .hex("#000000")),
                    padding: .init(top: 8, bottom: 8, leading: 12, trailing: 12)
                ))
            ],
            dimension: .vertical(.leading, .start),
            backgroundColor: .init(light: .hex("#F0F0F0")),
            padding: .init(top: 8, bottom: 8, leading: 12, trailing: 12)
        )
    }

}

#endif
