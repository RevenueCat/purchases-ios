//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentDuplicateInstanceTests.swift
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Regression test for a bug where a paywall's "manage subscription" footer button (shown/hidden
/// via a `selected_package_condition` override) froze on the initially active tab's package no
/// matter which tab the user actually selected.
///
/// Root cause: SwiftUI's `ViewThatFits` (used by `scrollableIfNecessaryWhenAvailable` to decide
/// whether paywall content needs to scroll) evaluates both of its candidate branches to measure
/// their ideal size. That constructs a second, non-displayed `LoadedTabsComponentView` sharing the
/// same `TabsComponentViewModel` and parent `PackageContext` as the real, visible one. Before the
/// fix, that duplicate got its own fresh, per-view `TabControlContext` and `onAppear` guard, so it
/// defaulted back to the first tab and unconditionally re-seeded that tab's package into the
/// shared `PackageContext`, clobbering whatever the user actually selected via the real, visible
/// instance.
///
/// Fix: `TabControlContext` and the one-time seed guard now live on the shared
/// `TabsComponentViewModel`, so every instance — including duplicates — reads and writes the same
/// selected-tab state.
///
/// This test reproduces the duplicate instance directly (bypassing `ViewThatFits` itself, which
/// isn't practical to drive from a unit test) by hosting two `LoadedTabsComponentView`s backed by
/// the same `TabsComponentViewModel` and the same shared `PackageContext`, mirroring what SwiftUI
/// constructs internally when measuring the "fits without scrolling" candidate.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class TabsComponentDuplicateInstanceTests: TestCase {

    func testDuplicateTabsInstanceDoesNotClobberRealTabSwitch() throws {
        let (viewModel, tab1Package, tab2Package, tab2Id) = try Self.makeTabsViewModel()

        let packageContext = PackageContext(
            package: nil,
            variableContext: .init(packages: [tab1Package, tab2Package])
        )

        // Neither instance is given an explicit TabControlContext, matching production: both
        // resolve to the shared `viewModel.tabControlContext`.
        let realView = Self.makeHostableView(
            viewModel: viewModel,
            packageContext: packageContext,
            tabControlContext: nil
        )

        let (realWindow, _) = Self.host(realView)
        defer {
            realWindow.isHidden = true
            realWindow.rootViewController = nil
        }

        // The real, visible instance seeds tab 1's package on first appearance.
        expect(packageContext.package?.identifier) == tab1Package.identifier

        // The user switches to tab 2 via the real, interactive instance. Production code drives
        // this through TabControlButtonComponentView tapping the shared context; mutate it
        // directly to isolate the seeding/sharing behavior from tap-gesture plumbing.
        viewModel.tabControlContext.selectedTabId = tab2Id
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        realWindow.rootViewController?.view.setNeedsLayout()
        realWindow.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        expect(packageContext.package?.identifier) == tab2Package.identifier

        // Simulate ViewThatFits' non-displayed measurement candidate: a second
        // LoadedTabsComponentView backed by the SAME TabsComponentViewModel and the SAME shared
        // PackageContext.
        let phantomView = Self.makeHostableView(
            viewModel: viewModel,
            packageContext: packageContext,
            tabControlContext: nil
        )

        let (phantomWindow, _) = Self.host(phantomView)
        defer {
            phantomWindow.isHidden = true
            phantomWindow.rootViewController = nil
        }

        // The phantom's onAppear must not clobber the user's real selection.
        expect(packageContext.package?.identifier) == tab2Package.identifier

        // And the phantom shares the SAME tab-selection state as the real instance — so if it were
        // ever promoted to the displayed instance (e.g. ViewThatFits swapping which candidate is on
        // screen), the pills would still show tab 2 instead of silently reverting to tab 1.
        expect(viewModel.tabControlContext.selectedTabId) == tab2Id
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TabsComponentDuplicateInstanceTests {

    static func makeTabsViewModel() throws -> (
        viewModel: TabsComponentViewModel,
        tab1Package: Package,
        tab2Package: Package,
        tab2Id: String
    ) {
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let localization = LocalizationProvider(
            locale: Locale(identifier: "en_US"),
            localizedStrings: ["package_label": .string("Package")]
        )
        let factory = ViewModelFactory()
        let tab1Package = TestData.monthlyPackage
        let tab2Package = TestData.annualPackage
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: [tab1Package, tab2Package],
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
                        stack: makeTextStack()
                    )),
                    .tabControlButton(PaywallComponent.TabControlButtonComponent(
                        tabId: tab2Id,
                        stack: makeTextStack()
                    ))
                ])
            ),
            tabs: [
                .init(id: tab1Id, stack: makeStackWithPackage(packageID: tab1Package.identifier)),
                .init(id: tab2Id, stack: makeStackWithPackage(packageID: tab2Package.identifier))
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

        return (tabsViewModel, tab1Package, tab2Package, tab2Id)
    }

    static func makeHostableView(
        viewModel: TabsComponentViewModel,
        packageContext: PackageContext,
        tabControlContext: TabControlContext?
    ) -> some View {
        LoadedTabsComponentView(
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

    static func makeStackWithPackage(packageID: String) -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(components: [
            .package(PaywallComponent.PackageComponent(
                packageID: packageID,
                isSelectedByDefault: true,
                visible: nil,
                applePromoOfferProductCode: nil,
                stack: makeTextStack()
            ))
        ])
    }

    static func makeTextStack() -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(components: [
            .text(PaywallComponent.TextComponent(
                text: "package_label",
                color: .init(light: .hex("#000000"))
            ))
        ])
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
