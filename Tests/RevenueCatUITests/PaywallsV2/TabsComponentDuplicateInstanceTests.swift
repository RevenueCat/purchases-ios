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

/// Regression test: `ViewThatFits` measures both of its candidate branches, which constructs a
/// second, non-displayed `LoadedTabsComponentView` sharing the same view model and parent
/// `PackageContext` as the real one. That duplicate used to clobber the user's real tab selection
/// on `onAppear`. Reproduces it directly (`ViewThatFits` itself isn't practical to drive from a
/// unit test) by hosting two view instances backed by the same view model and `PackageContext`.
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

        // Mutate the shared context directly instead of tapping, to isolate this from gesture plumbing.
        viewModel.tabControlContext.selectedTabId = tab2Id
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        realWindow.rootViewController?.view.setNeedsLayout()
        realWindow.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        expect(packageContext.package?.identifier) == tab2Package.identifier

        // Simulate ViewThatFits' non-displayed candidate: a second view backed by the same view model.
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

        // And the phantom shares the same tab-selection state, not a fresh default.
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
