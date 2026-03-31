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
@_spi(Internal) import RevenueCat
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

    // MARK: - selection + visibility interactions

    func testStaticHiddenDefaultSelectedPackageFallsBackToFirstVisiblePackage() {
        Self.createPaywall(
            offering: Self.offeringWithHiddenDefaultSelectedPackageFallback
        )
        .snapshot(size: Self.fullScreenSize)
    }

    // MARK: - global discardRules

    func testGlobalDiscardRulesKeepsIntroVisibilityRuleFromShowingHiddenPackage() {
        Self.createPaywall(
            offering: Self.offeringWithDiscardRulesHidingPackage,
            introEligibility: Self.eligibleChecker
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

    /// Offering where the default-selected monthly package is statically hidden,
    /// so the paywall should fall back to the first visible package and render it as selected.
    static var offeringWithHiddenDefaultSelectedPackageFallback: Offering {
        makeOffering(
            identifier: "hidden_default_selected_fallback",
            packages: [
                makePackageComponent(
                    packageID: PackageType.monthly.identifier,
                    label: "Monthly",
                    isSelectedByDefault: true,
                    visible: false,
                    showsSelectedStyle: true
                ),
                makePackageComponent(
                    packageID: PackageType.annual.identifier,
                    label: "Annual",
                    isSelectedByDefault: false,
                    visible: nil,
                    showsSelectedStyle: true
                ),
                makePackageComponent(
                    packageID: PackageType.weekly.identifier,
                    label: "Weekly",
                    isSelectedByDefault: false,
                    visible: nil,
                    showsSelectedStyle: true
                )
            ]
        )
    }

    /// Offering where a visibility rule would normally reveal the monthly package for an intro-eligible user,
    /// but another unsupported condition anywhere in the paywall forces global discardRules.
    static var offeringWithDiscardRulesHidingPackage: Offering {
        let unsupportedText = PaywallComponent.TextComponent(
            text: "Unsupported condition elsewhere",
            color: .init(light: .hex("#111111")),
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init(color: .init(light: .hex("#FF0000"))))
            ]
        )

        return makeOffering(
            identifier: "hidden_unless_intro_eligible_discard_rules",
            leadingComponents: [
                .text(unsupportedText)
            ],
            packages: [
                makePackageComponent(
                    packageID: PackageType.annual.identifier,
                    label: "Annual",
                    isSelectedByDefault: true,
                    visible: nil,
                    showsSelectedStyle: true
                ),
                makePackageComponent(
                    packageID: PackageType.monthly.identifier,
                    label: "Monthly (Trial)",
                    isSelectedByDefault: false,
                    visible: false,
                    overrides: [
                        .init(conditions: [.introOffer], properties: .init(visible: true))
                    ],
                    showsSelectedStyle: true
                ),
                makePackageComponent(
                    packageID: PackageType.weekly.identifier,
                    label: "Weekly",
                    isSelectedByDefault: false,
                    visible: nil,
                    showsSelectedStyle: true
                )
            ]
        )
    }

    // MARK: - Helpers

    static func makeOffering(
        identifier: String,
        leadingComponents: [PaywallComponent] = [],
        packages: [PaywallComponent.PackageComponent]
    ) -> Offering {
        let packageComponents: [PaywallComponent] = leadingComponents + packages.map { .package($0) }

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
        isSelectedByDefault: Bool = false,
        visible: Bool?,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialPackageComponent>? = nil,
        showsSelectedStyle: Bool = false
    ) -> PaywallComponent.PackageComponent {
        return PaywallComponent.PackageComponent(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            visible: visible,
            applePromoOfferProductCode: nil,
            stack: makePackageStack(label: label, showsSelectedStyle: showsSelectedStyle),
            overrides: overrides
        )
    }

    static func makePackageStack(label: String, showsSelectedStyle: Bool = false) -> PaywallComponent.StackComponent {
        let textOverrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialTextComponent>?
        let stackOverrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>?

        if showsSelectedStyle {
            textOverrides = [
                .init(conditions: [.selected], properties: .init(color: .init(light: .hex("#D83B01"))))
            ]
            stackOverrides = [
                .init(conditions: [.selected], properties: .init(
                    border: .init(color: .init(light: .hex("#D83B01")), width: 3)
                ))
            ]
        } else {
            textOverrides = nil
            stackOverrides = nil
        }

        return PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: label,
                    color: .init(light: .hex("#000000")),
                    padding: .init(top: 8, bottom: 8, leading: 12, trailing: 12),
                    overrides: textOverrides
                ))
            ],
            dimension: .vertical(.leading, .start),
            backgroundColor: .init(light: .hex("#F0F0F0")),
            padding: .init(top: 8, bottom: 8, leading: 12, trailing: 12),
            border: showsSelectedStyle ? .init(color: .init(light: .hex("#C8C2B8")), width: 2) : nil,
            overrides: stackOverrides
        )
    }

}

#endif
