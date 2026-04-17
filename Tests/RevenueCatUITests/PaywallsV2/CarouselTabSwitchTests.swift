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

    /// Regression test for a bug in `TabsComponentView.swift` where `LoadedTabComponentView`
    /// was rendered without an `.id()` modifier keyed on the selected tab ID.
    ///
    /// Without `.id()`, SwiftUI preserved `CarouselView`'s `@State` (including `data` and `index`)
    /// when switching between tabs, so the carousel continued to display the previous tab's content.
    /// Only a manual swipe inside the carousel would update the stale `@State`.
    ///
    /// Fix: `.id(tabControlContext.selectedTabId)` was added to `LoadedTabComponentView` in
    /// `LoadedTabsComponentView.body` (`TabsComponentView.swift`). This forces SwiftUI to
    /// recreate `CarouselView` on each tab switch, triggering `onAppear` and `setupData()`.
    ///
    /// The test verifies the fix by counting how many times the Tab 2 carousel's `onAppear`
    /// fires. With the fix the carousel is destroyed and recreated on tab switch → count = 1.
    /// Without the fix the carousel instance is reused → count = 0.
    func testCarouselAppearsAfterTabSwitch() throws {
        let (viewModel, tab2CarouselVM, tabControlContext) = try Self.makeViewModelAndContext()

        var tab2CarouselAppearCount = 0
        tab2CarouselVM.onViewAppear = { tab2CarouselAppearCount += 1 }

        let packageContext = PackageContext(package: nil, variableContext: .init(packages: []))
        let view = LoadedTabsComponentView(
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

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Tab 2 has not been shown yet — its carousel should not have appeared
        XCTAssertEqual(tab2CarouselAppearCount, 0, "Tab 2 carousel must not appear before switching to Tab 2")

        // Switch to Tab 2 programmatically
        tabControlContext.selectedTabId = "tab2"

        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        // After switching tabs the Tab 2 carousel must have appeared exactly once.
        //
        // BUG (now fixed): without `.id(tabControlContext.selectedTabId)` on
        // `LoadedTabComponentView`, SwiftUI reuses the existing view — `onAppear`
        // never fires for the Tab 2 carousel, `setupData()` is never called, and
        // the carousel keeps showing Tab 1's stale `@State`. Count stays at 0.
        //
        // FIX: `.id(tabControlContext.selectedTabId)` forces SwiftUI to destroy and
        // recreate `LoadedTabComponentView` on every tab switch. The new carousel's
        // `onAppear` fires and `setupData()` runs with Tab 2's pages. Count becomes 1.
        XCTAssertEqual(
            tab2CarouselAppearCount,
            1,
            "Tab 2 carousel must appear exactly once after switching to Tab 2"
        )
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
                .init(id: tab1Id, stack: makeStackWithCarousel()),
                .init(id: tab2Id, stack: makeStackWithCarousel())
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

        // Dig out the Tab 2 CarouselComponentViewModel so we can set the onViewAppear hook
        let tab2CarouselVM = try XCTUnwrap(
            tab2CarouselViewModel(from: tabsViewModel, tabId: tab2Id),
            "Expected to find a CarouselComponentViewModel in Tab 2"
        )

        let tabControlContext = TabControlContext(
            controlStackViewModel: tabsViewModel.controlStackViewModel,
            tabIds: tabsViewModel.tabIds,
            defaultTabId: tabsViewModel.defaultTabId,
            name: nil
        )

        return (tabsViewModel, tab2CarouselVM, tabControlContext)
    }

    /// Walks the view model tree under the given tab to find its `CarouselComponentViewModel`.
    static func tab2CarouselViewModel(
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

    static func makeStackWithCarousel() -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(
            components: [.carousel(PaywallComponent.CarouselComponent(
                pages: [makeTextStack(text: "page")]
            ))]
        )
    }

    static func makeTextStack(text: String) -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(
            components: [.text(PaywallComponent.TextComponent(
                text: text,
                color: .init(light: .hex("#000000"))
            ))]
        )
    }

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 400, height: 600)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        return (window, controller.view)
    }

}

#endif
