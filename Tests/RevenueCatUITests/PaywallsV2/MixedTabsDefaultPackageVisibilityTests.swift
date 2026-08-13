//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MixedTabsDefaultPackageVisibilityTests.swift
//
//  Created by RevenueCat on 8/13/26.

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// The mixed layout: package cards outside the tabs, plus a tabs component that also holds packages.
///
/// ```
/// Page
///  ├── Package A  (annual, "selected by default", hidden when can_trial = false)
///  ├── Package B  (monthly)
///  └── Tabs
///      ├── Tab 1: (no packages)
///      └── Tab 2: Package C  (weekly)
/// ```
///
/// The page-level selection has to move off A, which isn't rendering. Driven through the real
/// `PaywallsV2View` because the skip lived in the view, not in `PackageValidator`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class MixedTabsDefaultPackageVisibilityTests: TestCase {

    private static let tab1Id = "tab1"
    private static let tab2Id = "tab2"

    /// The break vegaro pointed at: a package inside any tab used to make the page skip reconciling
    /// entirely, so the hidden annual card stayed selected with nothing on screen to show it.
    func testPageSelectionMovesOffHiddenDefaultWhenAnotherTabHoldsPackages() throws {
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.paywallView(
            packageContext: packageContext,
            tabs: .packagesInSecondTab
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        XCTAssertEqual(
            packageContext.package?.identifier,
            TestData.monthlyPackage.identifier,
            "Page selection must fall back to the visible page package, not stay on the hidden default"
        )
    }

    /// When the tab that is showing has packages of its own, it still propagates its selection up for
    /// the purchase button. Pins that the page-level reconcile doesn't fight that.
    func testActiveTabWithPackagesStillOwnsThePageSelection() throws {
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.paywallView(
            packageContext: packageContext,
            tabs: .packagesInFirstTab
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        XCTAssertEqual(packageContext.package?.identifier, TestData.weeklyPackage.identifier)
    }

    /// The same paywall without the tabs component, which already worked: pins that the fix doesn't
    /// change the non-tabbed path.
    func testPageSelectionMovesOffHiddenDefaultWithoutTabs() throws {
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.paywallView(
            packageContext: packageContext,
            tabs: .none
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        XCTAssertEqual(packageContext.package?.identifier, TestData.monthlyPackage.identifier)
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension MixedTabsDefaultPackageVisibilityTests {

    /// Which tab holds `Package C`, or `none` for a paywall with no tabs component at all.
    enum TabsShape {
        case none
        case packagesInFirstTab
        case packagesInSecondTab
    }

    static func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
    }

    static let offering = Offering(
        identifier: "mixed_tabs",
        serverDescription: "",
        availablePackages: [
            TestData.annualPackage,
            TestData.monthlyPackage,
            TestData.weeklyPackage
        ],
        webCheckoutUrl: nil
    )

    /// What `PaywallsV2View.init` seeds: resolved provisionally, so the hidden annual card wins.
    static func provisionallySeededContext() -> PackageContext {
        return PackageContext(
            package: TestData.annualPackage,
            variableContext: .init(packages: Self.offering.availablePackages)
        )
    }

    static func paywallView(
        packageContext: PackageContext,
        tabs: TabsShape
    ) -> some View {
        return PaywallsV2View(
            paywallComponents: Self.paywallComponents(tabs: tabs),
            offering: Self.offering,
            purchaseHandler: .mock(),
            introEligibilityChecker: .producing(eligibility: .eligible),
            showZeroDecimalPlacePrices: false,
            onDismiss: {},
            failedToLoadFont: { _ in },
            colorScheme: .light,
            selectedPackageContextOverride: packageContext
        )
        .customPaywallVariables(["can_trial": .bool(false)])
    }

    static func paywallComponents(tabs: TabsShape) -> Offering.PaywallComponents {
        var components: [PaywallComponent] = [
            // Package A: the authored default, hidden when `can_trial = false`.
            Self.packageComponent(
                packageID: TestData.annualPackage.identifier,
                isSelectedByDefault: true,
                overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
            ),
            // Package B: the only page package on screen in that case.
            Self.packageComponent(
                packageID: TestData.monthlyPackage.identifier,
                isSelectedByDefault: false
            )
        ]

        if tabs != .none {
            // Package C, in whichever tab this shape puts it. The other tab holds no packages, so it
            // renders the page's own selection.
            let packageStack: PaywallComponent.StackComponent = .init(components: [
                Self.packageComponent(
                    packageID: TestData.weeklyPackage.identifier,
                    isSelectedByDefault: false
                )
            ])
            let emptyStack: PaywallComponent.StackComponent = .init(
                components: [Self.textComponent("No packages")]
            )
            let firstHoldsPackages = tabs == .packagesInFirstTab

            components.append(.tabs(.init(
                control: .init(
                    type: .buttons,
                    stack: .init(components: [
                        .tabControlButton(.init(tabId: Self.tab1Id, stack: Self.textStack("Tab 1"))),
                        .tabControlButton(.init(tabId: Self.tab2Id, stack: Self.textStack("Tab 2")))
                    ])
                ),
                tabs: [
                    .init(id: Self.tab1Id, stack: firstHoldsPackages ? packageStack : emptyStack),
                    .init(id: Self.tab2Id, stack: firstHoldsPackages ? emptyStack : packageStack)
                ],
                defaultTabId: Self.tab1Id
            )))
        }

        return .init(
            uiConfig: PreviewUIConfig.make(),
            data: .init(
                templateName: "components",
                // swiftlint:disable:next force_unwrapping
                assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
                componentsConfig: .init(base: .init(
                    stack: .init(components: components),
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )),
                componentsLocalizations: ["en_US": [:]],
                revision: 1,
                defaultLocaleIdentifier: "en_US"
            )
        )
    }

    static func packageComponent(
        packageID: String,
        isSelectedByDefault: Bool,
        overrides: [PaywallComponent.ComponentOverride<PaywallComponent.PartialPackageComponent>]? = nil
    ) -> PaywallComponent {
        return .package(.init(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            applePromoOfferProductCode: nil,
            stack: Self.textStack(packageID),
            overrides: overrides
        ))
    }

    static func visibilityOverride(
        whenCanTrial canTrial: Bool,
        visible: Bool
    ) -> PaywallComponent.ComponentOverride<PaywallComponent.PartialPackageComponent> {
        return .init(
            extendedConditions: [
                .variable(operator: .equals, variable: "can_trial", value: .bool(canTrial))
            ],
            properties: .init(visible: visible)
        )
    }

    static func textStack(_ text: String) -> PaywallComponent.StackComponent {
        return .init(components: [Self.textComponent(text)])
    }

    static func textComponent(_ text: String) -> PaywallComponent {
        return .text(.init(text: text, color: .init(light: .hex("#000000"))))
    }

}

#endif
