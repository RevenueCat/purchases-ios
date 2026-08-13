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

    /// Leaving a tab that holds packages for one that doesn't restores the page's own selection
    /// (`TabsComponentView.parentOwnedPackage`), which is seeded from the provisional hidden default in
    /// `init`. The page must not end up holding that hidden package again.
    func testLeavingATabWithPackagesDoesNotRestoreTheHiddenDefault() throws {
        let (paywallState, tabControlContext) = try Self.mixedLayoutState(tabs: .packagesInFirstTab)
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.loadedPaywallView(
            paywallState: paywallState,
            packageContext: packageContext
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        tabControlContext.selectedTabId = Self.tab2Id
        Self.settle()

        XCTAssertEqual(
            packageContext.package?.identifier,
            TestData.monthlyPackage.identifier,
            "Switching to a package-less tab must not restore the hidden default"
        )
    }

    /// The showing tab's own package is hidden by the same rule, so the page takes the selection back.
    ///
    /// Also pins the price basis: a tab propagates its own variable context, and relative prices for a
    /// package outside the tabs would be wrong if the page kept it. It holds today because the page
    /// reconciles before the tab propagates, which is ordering this doesn't control, so this is a
    /// characterization test, not proof that reconciling repairs the basis.
    func testReconcilingOffAHiddenTabPackageKeepsThePagePriceBasis() throws {
        let (paywallState, _) = try Self.mixedLayoutState(tabs: .hiddenPackageInFirstTab)
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.loadedPaywallView(
            paywallState: paywallState,
            packageContext: packageContext
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        // The tab's monthly card is hidden too, so the page's weekly card takes the selection.
        XCTAssertEqual(packageContext.package?.identifier, TestData.weeklyPackage.identifier)

        let pageBasis = PackageContext.VariableContext(
            packages: paywallState.packages,
            showZeroDecimalPlacePrices: false
        )
        let tabOnlyBasis = PackageContext.VariableContext(
            packages: [TestData.monthlyPackage],
            showZeroDecimalPlacePrices: false
        )
        XCTAssertNotEqual(
            pageBasis.mostExpensivePricePerMonth,
            tabOnlyBasis.mostExpensivePricePerMonth,
            "Fixture must make the two package sets disagree, otherwise this test proves nothing"
        )
        XCTAssertEqual(
            packageContext.variableContext.mostExpensivePricePerMonth,
            pageBasis.mostExpensivePricePerMonth
        )
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
        /// The showing tab's package is hidden by the same rule, so the page has to take the selection
        /// back. Uses monthly in the tab and weekly on the page so the two package sets disagree on
        /// the most expensive price per month.
        case hiddenPackageInFirstTab

        var pageFallbackPackage: Package {
            return self == .hiddenPackageInFirstTab ? TestData.weeklyPackage : TestData.monthlyPackage
        }

        var tabPackage: Package {
            return self == .hiddenPackageInFirstTab ? TestData.monthlyPackage : TestData.weeklyPackage
        }
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

    /// Builds the real `PaywallState` and hands back the tabs component's own `TabControlContext`, the
    /// only way to drive a tab switch without simulating a tap.
    static func mixedLayoutState(tabs: TabsShape) throws -> (PaywallState, TabControlContext) {
        let components = Self.paywallComponents(tabs: tabs)
        let state = try PaywallsV2View.createPaywallState(
            componentsConfig: components.data.componentsConfig.base,
            componentsLocalizations: components.data.componentsLocalizations,
            preferredLocales: [Locale(identifier: "en_US")],
            defaultLocale: "en_US",
            uiConfigProvider: UIConfigProvider(uiConfig: components.uiConfig),
            offering: Self.offering,
            introEligibilityChecker: .producing(eligibility: .eligible),
            showZeroDecimalPlacePrices: false,
            colorScheme: .light
        ).get()

        let tabsViewModel = try XCTUnwrap(
            state.rootViewModel.stackViewModel.viewModels.compactMap { viewModel -> TabsComponentViewModel? in
                guard case .tabs(let tabsViewModel) = viewModel else { return nil }
                return tabsViewModel
            }.first
        )

        return (state, tabsViewModel.tabControlContext)
    }

    static func loadedPaywallView(
        paywallState: PaywallState,
        packageContext: PackageContext
    ) -> some View {
        return LoadedPaywallsV2View(
            introOfferEligibilityContext: IntroOfferEligibilityContext(
                introEligibilityChecker: .producing(eligibility: .eligible)
            ),
            paywallState: paywallState,
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            selectedPackageContext: packageContext,
            workflowDefaultPackage: nil,
            onDismiss: {}
        )
        .environmentObject(PurchaseHandler.mock())
        .environmentObject(IntroOfferEligibilityContext(
            introEligibilityChecker: .producing(eligibility: .eligible)
        ))
        .environmentObject(PaywallPromoOfferCache(
            subscriptionHistoryTracker: SubscriptionHistoryTracker()
        ))
        .environment(\.screenCondition, .compact)
        .customPaywallVariables(["can_trial": .bool(false)])
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
                packageID: tabs.pageFallbackPackage.identifier,
                isSelectedByDefault: false
            )
        ]

        if tabs != .none {
            // Package C, in whichever tab this shape puts it. The other tab holds no packages, so it
            // renders the page's own selection.
            let packageStack: PaywallComponent.StackComponent = .init(components: [
                Self.packageComponent(
                    packageID: tabs.tabPackage.identifier,
                    isSelectedByDefault: false,
                    overrides: tabs == .hiddenPackageInFirstTab
                        ? [Self.visibilityOverride(whenCanTrial: false, visible: false)]
                        : nil
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
