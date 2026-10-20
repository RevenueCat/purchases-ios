//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselTabSwitchTests.swift
//
//  Created by RevenueCat on 4/16/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CarouselTabSwitchTests: TestCase {

    /// Regression test for a bug where `CarouselView`'s `@State` (`data`, `index`) was not
    /// reset when switching tabs, so the carousel continued to display the previous tab's content.
    /// Only a manual swipe inside the carousel would update the stale `@State`.
    ///
    /// Root cause: `CarouselView` initialises its page data in `onAppear` via `setupData()`.
    /// Without a view-identity change, SwiftUI reuses the same `CarouselView` instance across
    /// tab switches and `onAppear` never re-fires.
    ///
    /// Fix: `.id(ObjectIdentifier(viewModel))` is applied to the `GeometryReader`/`CarouselView`
    /// block inside `CarouselComponentView`. When the tab switches, `CarouselComponentView`
    /// receives a new `CarouselComponentViewModel` instance, the ID changes, SwiftUI recreates
    /// only `CarouselView` (not the entire tab subtree), and `onAppear`/`setupData()` run with
    /// the new tab's pages.
    ///
    /// The test verifies the fix by counting how many times the Tab 2 carousel's `onAppear`
    /// fires. With the fix the carousel is destroyed and recreated on tab switch → count = 1.
    /// Without the fix the carousel instance is reused → count = 0.
    func testCarouselAppearsAfterTabSwitch() throws {
        let (viewModel, tab2CarouselVM, tabControlContext) = try Self.makeViewModelAndContext()

        var tab2CarouselAppearCount = 0
        tab2CarouselVM.onViewAppear = { tab2CarouselAppearCount += 1 }

        let window = Self.host(Self.makeTabsView(viewModel: viewModel, tabControlContext: tabControlContext))
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Tab 2 has not been shown yet — its carousel should not have appeared
        XCTAssertEqual(tab2CarouselAppearCount, 0, "Tab 2 carousel must not appear before switching to Tab 2")

        // Switch to Tab 2 programmatically
        Self.switchTab(to: "tab2", in: tabControlContext, window: window)

        // After switching tabs the Tab 2 carousel must have appeared exactly once.
        //
        // BUG (now fixed): SwiftUI reused `CarouselView` across tab switches — `onAppear`
        // never fired for Tab 2's carousel, `setupData()` was never called, and the carousel
        // kept showing Tab 1's stale `@State`. Count stayed at 0.
        //
        // FIX: `.id(ObjectIdentifier(viewModel))` in `CarouselComponentView` forces SwiftUI
        // to recreate only `CarouselView` when the ViewModel instance changes on tab switch.
        // `onAppear` fires and `setupData()` runs with Tab 2's pages. Count becomes 1.
        XCTAssertEqual(
            tab2CarouselAppearCount,
            1,
            "Tab 2 carousel must appear exactly once after switching to Tab 2"
        )
    }

    /// Each carousel remembers the page it was on: leaving a tab and coming back resumes its
    /// carousel on that page, while the other tab's carousel still starts on its own initial page.
    func testCarouselResumesOnLastPageWhenReturningToTab() throws {
        let tab1Carousel = PaywallComponent.CarouselComponent(
            pages: Self.makePages(count: 3),
            // Auto-advance stands in for the user swiping: it walks to the last page and stops.
            autoAdvance: .init(msTimePerPage: 50, msTransitionTime: 10, transitionType: .slide)
        )
        let tab2Carousel = PaywallComponent.CarouselComponent(
            pages: Self.makePages(count: 3),
            initialPageIndex: 1
        )
        let (viewModel, tab1CarouselVM, tab2CarouselVM, tabControlContext) = try Self.makeViewModelAndContext(
            tab1Carousel: tab1Carousel,
            tab2Carousel: tab2Carousel
        )

        let window = Self.host(Self.makeTabsView(viewModel: viewModel, tabControlContext: tabControlContext))
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        Self.waitUntil { tab1CarouselVM.lastPageIndex == 2 }
        XCTAssertEqual(tab1CarouselVM.lastPageIndex, 2, "Tab 1 carousel should have advanced to its last page")

        Self.switchTab(to: "tab2", in: tabControlContext, window: window)

        XCTAssertEqual(
            tab2CarouselVM.lastPageIndex,
            1,
            "Tab 2 carousel must start on its own initial page, not on Tab 1's page"
        )

        var tab1PagesAfterReturning: [Int] = []
        tab1CarouselVM.onPageIndexChange = { tab1PagesAfterReturning.append($0) }

        Self.switchTab(to: "tab1", in: tabControlContext, window: window)

        // Resuming jumps straight to page 2. Restarting from page 0 would only reach page 2 again
        // by auto-advancing through page 1 first.
        XCTAssertEqual(
            tab1PagesAfterReturning.first,
            2,
            "Tab 1 carousel must resume on the page it was on before switching tabs"
        )
        XCTAssertFalse(tab1PagesAfterReturning.contains(1))
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CarouselTabSwitchTests {

    /// Returns the tabs view model, the Tab 2 carousel view model (so the test can set its
    /// `onViewAppear` callback), and the injected `TabControlContext`.
    static func makeViewModelAndContext() throws -> (
        TabsComponentViewModel,
        CarouselComponentViewModel,
        TabControlContext
    ) {
        let carousel = PaywallComponent.CarouselComponent(pages: [makeTextStack(text: "page")])
        let (tabsViewModel, _, tab2CarouselVM, tabControlContext) = try makeViewModelAndContext(
            tab1Carousel: carousel,
            tab2Carousel: carousel
        )
        return (tabsViewModel, tab2CarouselVM, tabControlContext)
    }

    /// Returns the tabs view model, both tabs' carousel view models, and the injected `TabControlContext`.
    static func makeViewModelAndContext(
        tab1Carousel: PaywallComponent.CarouselComponent,
        tab2Carousel: PaywallComponent.CarouselComponent
    ) throws -> (
        TabsComponentViewModel,
        CarouselComponentViewModel,
        CarouselComponentViewModel,
        TabControlContext
    ) {
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let localization = LocalizationProvider(locale: Locale(identifier: "en_US"), localizedStrings: [:])
        let factory = ViewModelFactory()
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: [],
            webCheckoutUrl: nil
        )

        let tab1Id = "tab1"
        let tab2Id = "tab2"

        let tabsComponent = PaywallComponent.TabsComponent(
            control: .init(
                type: .buttons,
                stack: PaywallComponent.StackComponent(components: [
                    .tabControlButton(PaywallComponent.TabControlButtonComponent(
                        tabId: tab1Id,
                        stack: makeTextStack(text: "Monthly")
                    )),
                    .tabControlButton(PaywallComponent.TabControlButtonComponent(
                        tabId: tab2Id,
                        stack: makeTextStack(text: "Annual")
                    ))
                ])
            ),
            tabs: [
                .init(id: tab1Id, stack: PaywallComponent.StackComponent(components: [.carousel(tab1Carousel)])),
                .init(id: tab2Id, stack: PaywallComponent.StackComponent(components: [.carousel(tab2Carousel)]))
            ],
            defaultTabId: tab1Id
        )

        guard case .tabs(let tabsViewModel) = try factory.toViewModel(
            component: .tabs(tabsComponent),
            packageValidator: factory.packageValidator,
            offering: offering,
            localizationProvider: localization,
            uiConfigProvider: uiConfigProvider,
            colorScheme: .light
        ) else {
            XCTFail("Expected a .tabs PaywallComponentViewModel")
            throw XCTSkip("Test setup failed")
        }

        // Dig out each tab's CarouselComponentViewModel so tests can observe them
        let tab1CarouselVM = try XCTUnwrap(
            carouselViewModel(from: tabsViewModel, tabId: tab1Id),
            "Expected to find a CarouselComponentViewModel in Tab 1"
        )
        let tab2CarouselVM = try XCTUnwrap(
            carouselViewModel(from: tabsViewModel, tabId: tab2Id),
            "Expected to find a CarouselComponentViewModel in Tab 2"
        )

        let tabControlContext = TabControlContext(
            controlStackViewModel: tabsViewModel.controlStackViewModel,
            tabIds: tabsViewModel.tabIds,
            defaultTabId: tabsViewModel.defaultTabId,
            name: nil
        )

        return (tabsViewModel, tab1CarouselVM, tab2CarouselVM, tabControlContext)
    }

    /// Walks the view model tree under the given tab to find its `CarouselComponentViewModel`.
    static func carouselViewModel(
        from tabsVM: TabsComponentViewModel,
        tabId: String
    ) -> CarouselComponentViewModel? {
        guard let tabViewModel = tabsVM.tabViewModels[tabId] else { return nil }
        return carouselViewModel(in: tabViewModel.stackViewModel)
    }

    static func carouselViewModel(in stackVM: StackComponentViewModel) -> CarouselComponentViewModel? {
        for childVM in stackVM.viewModels {
            switch childVM {
            case .carousel(let viewModel): return viewModel
            case .stack(let nested): if let found = carouselViewModel(in: nested) { return found }
            default: break
            }
        }
        return nil
    }

    static func makePages(count: Int) -> [PaywallComponent.StackComponent] {
        (0..<count).map { makeTextStack(text: "page \($0)") }
    }

    static func makeTextStack(text: String) -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(
            components: [.text(PaywallComponent.TextComponent(
                text: text,
                color: .init(light: .hex("#000000"))
            ))]
        )
    }

    static func makeTabsView(
        viewModel: TabsComponentViewModel,
        tabControlContext: TabControlContext
    ) -> some View {
        let packageContext = PackageContext(package: nil, variableContext: .init(packages: []))
        return LoadedTabsComponentView(
            viewModel: viewModel,
            parentPackageContext: packageContext,
            onDismiss: {},
            tabControlContext: tabControlContext
        )
        .environmentObject(packageContext)
        .environmentObject(IntroOfferEligibilityContext(
            introEligibilityChecker: BaseSnapshotTest.eligibleChecker
        ))
        .environmentObject(PaywallPromoOfferCache(
            subscriptionHistoryTracker: SubscriptionHistoryTracker()
        ))
        .environment(\.screenCondition, .compact)
        .environment(\.componentViewState, .default)
        .environment(\.safeAreaInsets, EdgeInsets())
        .environment(\.selectedPackageId, nil)
        .frame(width: 400, height: 600)
    }

    static func switchTab(to tabId: String, in tabControlContext: TabControlContext, window: UIWindow) {
        tabControlContext.selectedTabId = tabId

        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

    static func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    static func host<Content: View>(_ view: Content) -> UIWindow {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 400, height: 600)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        return window
    }

}

#endif
