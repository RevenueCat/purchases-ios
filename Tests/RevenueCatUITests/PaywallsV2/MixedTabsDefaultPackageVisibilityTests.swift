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
    /// Taking it back has to take the price basis with it: the tab propagated its own variable context,
    /// and relative prices for a package outside the tabs are computed against the page's packages.
    func testReconcilingOffAHiddenTabPackageRestoresThePagePriceBasis() throws {
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

    /// The showing tab repeats the page's hidden default, so a card carrying that identifier IS on
    /// screen and the selection has to stay put. Nothing here should clear the tab's highlight.
    func testSelectionStaysWhenTheShowingTabRepeatsTheHiddenPageDefault() throws {
        let (paywallState, _) = try Self.mixedLayoutState(tabs: .pageDefaultRepeatedInFirstTab)
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.loadedPaywallView(
            paywallState: paywallState,
            packageContext: packageContext
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        XCTAssertEqual(
            packageContext.package?.identifier,
            TestData.annualPackage.identifier,
            "The showing tab renders this package, so the page must not move the selection off it"
        )
    }

    /// The same layout driven through the real loading transition. `isPaywallLoading` going false once
    /// eligibility resolves fires a second page reconcile, and by then the showing tab has propagated its
    /// annual card up. Nothing may move: that card is on screen and the user never tapped anything.
    func testEligibilityResolvingDoesNotPullSelectionOffAVisibleTabCard() throws {
        let (paywallState, _) = try Self.mixedLayoutState(tabs: .pageDefaultRepeatedInFirstTab)
        let packageContext = Self.provisionallySeededContext()
        let flag = PaywallLoadingFlag(isLoading: true)

        let dispose = try PaywallLoadingHost(
            flag: flag,
            content: Self.loadedPaywallView(
                paywallState: paywallState,
                packageContext: packageContext
            )
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        flag.isLoading = false
        Self.settle()

        XCTAssertEqual(
            packageContext.package?.identifier,
            TestData.annualPackage.identifier,
            "Eligibility resolving must not move the selection off the card the showing tab renders"
        )
    }

    /// Known limitation, pinned so it is discoverable rather than surprising.
    ///
    /// The page's reconcile writes the shared parent context, and `TabsComponentView` classifies any
    /// parent change that isn't its own propagation as an explicit user selection. So a tab opened later
    /// that also offers the reconciled package keeps it instead of using its own declared default, even
    /// though the user never tapped anything.
    ///
    /// Marking the update as reconcile-originated does not hold: the tab seeding path writes the same
    /// context before the tabs view observes the change, and clearing the flag reliably means reworking
    /// how `didUserSelectPackage` is derived, which the tab inheritance tests cover in depth. The narrower
    /// alternative, not reconciling at all, is the bug this PR fixes.
    func testReconcileCountsAsAUserSelectionForALaterTabSwitch() throws {
        let (paywallState, tabControlContext) = try Self.mixedLayoutState(
            components: Self.overlappingTabDefaultComponents()
        )
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.loadedPaywallView(
            paywallState: paywallState,
            packageContext: packageContext
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        // The showing tab has no packages, so the page reconciles off the hidden annual card itself.
        XCTAssertEqual(packageContext.package?.identifier, TestData.monthlyPackage.identifier)

        tabControlContext.selectedTabId = Self.tab2Id
        Self.settle()

        XCTAssertEqual(
            packageContext.package?.identifier,
            TestData.monthlyPackage.identifier,
            "Documents today's behavior: the reconciled package outranks tab 2's own default"
        )
    }

    /// The residual case a reviewer raised: package C sits in both tabs, hidden in the one that's
    /// showing. The page can't tell those two copies apart, so it leaves the selection alone. The
    /// guarantee comes from one level down, where the showing tab reconciles against its own packages
    /// and falls back to another card of its own.
    func testShowingTabReconcilesWhenAnotherTabRepeatsItsHiddenPackage() throws {
        let (paywallState, _) = try Self.mixedLayoutState(
            components: Self.duplicatedAcrossTabsComponents()
        )
        let packageContext = Self.provisionallySeededContext()

        let dispose = try Self.loadedPaywallView(
            paywallState: paywallState,
            packageContext: packageContext
        ).addToHierarchy()
        defer { dispose() }

        Self.settle()

        XCTAssertEqual(
            packageContext.package?.identifier,
            Self.tabExtraPackage.identifier,
            "The showing tab must fall back to its own visible card, not keep a package only another tab renders"
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

/// Drives `\.isPaywallLoading` from `true` to `false`, the transition `PaywallsV2View` makes once intro
/// and promo eligibility resolve. That flip is what triggers the page's second reconcile in production.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class PaywallLoadingFlag: ObservableObject {

    @Published var isLoading: Bool

    init(isLoading: Bool) {
        self.isLoading = isLoading
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallLoadingHost<Content: View>: View {

    @ObservedObject var flag: PaywallLoadingFlag
    let content: Content

    var body: some View {
        self.content.environment(\.isPaywallLoading, self.flag.isLoading)
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension MixedTabsDefaultPackageVisibilityTests {

    /// The tabs half of the layout. `tab1` is the one showing, so `inFirstTab` decides whether the
    /// package-bearing tab is the active one.
    struct TabsShape {
        /// The package the tabs component holds, or `nil` for a paywall with no tabs at all.
        let package: Package?
        let inFirstTab: Bool
        /// Whether the same `can_trial` rule that hides the page default also hides the tab's card.
        let packageIsHidden: Bool
        /// The page's visible card. Kept distinct from `package` where a test compares price bases.
        let pageFallback: Package

        static let none = TabsShape(
            package: nil,
            inFirstTab: false,
            packageIsHidden: false,
            pageFallback: TestData.monthlyPackage
        )

        static let packagesInFirstTab = TabsShape(
            package: TestData.weeklyPackage,
            inFirstTab: true,
            packageIsHidden: false,
            pageFallback: TestData.monthlyPackage
        )

        static let packagesInSecondTab = TabsShape(
            package: TestData.weeklyPackage,
            inFirstTab: false,
            packageIsHidden: false,
            pageFallback: TestData.monthlyPackage
        )

        /// The showing tab's own card is hidden too, so the page has to take the selection back. Monthly
        /// in the tab and weekly on the page, so the two package sets disagree on the most expensive
        /// price per month and a kept tab basis is detectable.
        static let hiddenPackageInFirstTab = TabsShape(
            package: TestData.monthlyPackage,
            inFirstTab: true,
            packageIsHidden: true,
            pageFallback: TestData.weeklyPackage
        )

        /// The showing tab repeats the page's hidden default, so a card for it IS on screen.
        static let pageDefaultRepeatedInFirstTab = TabsShape(
            package: TestData.annualPackage,
            inFirstTab: true,
            packageIsHidden: false,
            pageFallback: TestData.monthlyPackage
        )
    }

    /// Pumps the run loop and forces a layout pass, matching `TabsWorkflowDefaultPackageTests.settle`.
    static func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        UIApplication.shared.windows.forEach { window in
            window.setNeedsLayout()
            window.layoutIfNeeded()
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

    /// A second card for the showing tab, so it has somewhere of its own to fall back to.
    static let tabExtraPackage = Package(
        identifier: "tab_extra",
        packageType: .custom,
        storeProduct: TestData.lifetimeProduct.toStoreProduct(),
        offeringIdentifier: "mixed_tabs",
        webCheckoutUrl: nil
    )

    static let offering = Offering(
        identifier: "mixed_tabs",
        serverDescription: "",
        availablePackages: [
            TestData.annualPackage,
            TestData.monthlyPackage,
            TestData.weeklyPackage,
            MixedTabsDefaultPackageVisibilityTests.tabExtraPackage
        ],
        webCheckoutUrl: nil
    )

    /// The showing tab holds no packages; the other tab offers the page's fallback package plus its own
    /// declared default. Used to check whether a page-level reconcile gets mistaken for a user tap.
    static func overlappingTabDefaultComponents() -> Offering.PaywallComponents {
        let components: [PaywallComponent] = [
            Self.packageComponent(
                packageID: TestData.annualPackage.identifier,
                isSelectedByDefault: true,
                overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
            ),
            Self.packageComponent(
                packageID: TestData.monthlyPackage.identifier,
                isSelectedByDefault: false
            ),
            .tabs(.init(
                control: .init(
                    type: .buttons,
                    stack: .init(components: [
                        .tabControlButton(.init(tabId: Self.tab1Id, stack: Self.textStack("Tab 1"))),
                        .tabControlButton(.init(tabId: Self.tab2Id, stack: Self.textStack("Tab 2")))
                    ])
                ),
                tabs: [
                    .init(id: Self.tab1Id, stack: .init(components: [Self.textComponent("No packages")])),
                    .init(id: Self.tab2Id, stack: .init(components: [
                        Self.packageComponent(
                            packageID: TestData.monthlyPackage.identifier,
                            isSelectedByDefault: false
                        ),
                        Self.packageComponent(
                            packageID: MixedTabsDefaultPackageVisibilityTests.tabExtraPackage.identifier,
                            isSelectedByDefault: true
                        )
                    ]))
                ],
                defaultTabId: Self.tab1Id
            ))
        ]

        return Self.paywallComponents(components: components)
    }

    /// Package C in both tabs, hidden in the one that's showing. The page cannot tell the two copies
    /// apart, so this exists to check the tab's own reconcile covers it.
    static func duplicatedAcrossTabsComponents() -> Offering.PaywallComponents {
        let components: [PaywallComponent] = [
            Self.packageComponent(
                packageID: TestData.annualPackage.identifier,
                isSelectedByDefault: true,
                overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
            ),
            Self.packageComponent(
                packageID: TestData.monthlyPackage.identifier,
                isSelectedByDefault: false
            ),
            .tabs(.init(
                control: .init(
                    type: .buttons,
                    stack: .init(components: [
                        .tabControlButton(.init(tabId: Self.tab1Id, stack: Self.textStack("Tab 1"))),
                        .tabControlButton(.init(tabId: Self.tab2Id, stack: Self.textStack("Tab 2")))
                    ])
                ),
                tabs: [
                    .init(id: Self.tab1Id, stack: .init(components: [
                        Self.packageComponent(
                            packageID: TestData.weeklyPackage.identifier,
                            isSelectedByDefault: true,
                            overrides: [Self.visibilityOverride(whenCanTrial: false, visible: false)]
                        ),
                        Self.packageComponent(
                            packageID: Self.tabExtraPackage.identifier,
                            isSelectedByDefault: false
                        )
                    ])),
                    .init(id: Self.tab2Id, stack: .init(components: [
                        Self.packageComponent(
                            packageID: TestData.weeklyPackage.identifier,
                            isSelectedByDefault: false
                        )
                    ]))
                ],
                defaultTabId: Self.tab1Id
            ))
        ]

        return Self.paywallComponents(components: components)
    }

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
        return try Self.mixedLayoutState(components: Self.paywallComponents(tabs: tabs))
    }

    static func mixedLayoutState(
        components: Offering.PaywallComponents
    ) throws -> (PaywallState, TabControlContext) {
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
        let introOfferEligibilityContext = IntroOfferEligibilityContext(
            introEligibilityChecker: .producing(eligibility: .eligible)
        )

        return LoadedPaywallsV2View(
            introOfferEligibilityContext: introOfferEligibilityContext,
            paywallState: paywallState,
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            selectedPackageContext: packageContext,
            workflowDefaultPackage: nil,
            onDismiss: {}
        )
        .environmentObject(PurchaseHandler.mock())
        .environmentObject(introOfferEligibilityContext)
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
                packageID: tabs.pageFallback.identifier,
                isSelectedByDefault: false
            )
        ]

        if let tabPackage = tabs.package {
            // Package C, in whichever tab this shape puts it. The other tab holds no packages, so it
            // renders the page's own selection.
            let packageStack: PaywallComponent.StackComponent = .init(components: [
                Self.packageComponent(
                    packageID: tabPackage.identifier,
                    isSelectedByDefault: false,
                    overrides: tabs.packageIsHidden
                        ? [Self.visibilityOverride(whenCanTrial: false, visible: false)]
                        : nil
                )
            ])
            let emptyStack: PaywallComponent.StackComponent = .init(
                components: [Self.textComponent("No packages")]
            )
            let firstHoldsPackages = tabs.inFirstTab

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

        return Self.paywallComponents(components: components)
    }

    static func paywallComponents(components: [PaywallComponent]) -> Offering.PaywallComponents {
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
