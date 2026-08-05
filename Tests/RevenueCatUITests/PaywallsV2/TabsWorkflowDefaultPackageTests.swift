//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsWorkflowDefaultPackageTests.swift
//
//  Created by RevenueCat on 8/5/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Drives a real tab switch through `LoadedTabsComponentView` (hosted in a window) to cover the
/// wiring, not just the helper: a workflow-backed tabs paywall whose tabs hold disjoint packages
/// must select each tab's own default.
///
/// `WorkflowContext` derives its default by flattening every tab, so `workflowDefaultPackage` here
/// is tab 1's annual package, exactly what the SDK computes for this paywall shape. Before the fix
/// that package won everywhere, so tab 2 was handed a package it doesn't offer and nothing rendered
/// as selected.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class TabsWorkflowDefaultPackageTests: TestCase {

    private static let tab1Id = "subscriptions"
    private static let tab2Id = "onetime"

    func testSwitchingToSecondTabSelectsItsOwnDefaultPackage() throws {
        let (viewModel, tabControlContext, offering) = try Self.makeTabsViewModel()
        let annual = try XCTUnwrap(offering.package(identifier: "annual"))
        let onetimeFirst = try XCTUnwrap(offering.package(identifier: "onetime1"))

        let packageContext = PackageContext(package: nil, variableContext: .init(packages: []))
        let (window, _) = Self.host(
            Self.tabsView(
                viewModel: viewModel,
                packageContext: packageContext,
                // What WorkflowContext computes: the first default across all flattened tabs.
                workflowDefaultPackage: annual,
                tabControlContext: tabControlContext
            )
        )
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Tab 1 seeds its own default, which happens to match the workflow default.
        XCTAssertEqual(packageContext.package?.identifier, annual.identifier)

        tabControlContext.selectedTabId = Self.tab2Id
        Self.settle(window)

        // Tab 2 offers neither monthly nor annual, so it must fall back to its own default.
        // Before the fix this stayed on `annual`, leaving every row in tab 2 unselected.
        XCTAssertEqual(
            packageContext.package?.identifier,
            onetimeFirst.identifier,
            "Second tab must select its own default package, not the flattened workflow default"
        )
    }

    func testReturningToFirstTabKeepsItsOwnDefaultPackage() throws {
        let (viewModel, tabControlContext, offering) = try Self.makeTabsViewModel()
        let annual = try XCTUnwrap(offering.package(identifier: "annual"))

        let packageContext = PackageContext(package: nil, variableContext: .init(packages: []))
        let (window, _) = Self.host(
            Self.tabsView(
                viewModel: viewModel,
                packageContext: packageContext,
                workflowDefaultPackage: annual,
                tabControlContext: tabControlContext
            )
        )
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        tabControlContext.selectedTabId = Self.tab2Id
        Self.settle(window)
        tabControlContext.selectedTabId = Self.tab1Id
        Self.settle(window)

        // The round trip must not leave tab 1 holding tab 2's package.
        XCTAssertEqual(packageContext.package?.identifier, annual.identifier)
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TabsWorkflowDefaultPackageTests {

    /// Tab 1: monthly + annual (annual is the default). Tab 2: onetime1 (default) + onetime2.
    static func makeTabsViewModel() throws -> (TabsComponentViewModel, TabControlContext, Offering) {
        let offering = Offering(
            identifier: "test_offering",
            serverDescription: "",
            availablePackages: [
                Self.package(identifier: "monthly", product: TestData.monthlyProduct),
                Self.package(identifier: "annual", product: TestData.annualProduct),
                Self.package(identifier: "onetime1", product: TestData.lifetimeProduct),
                Self.package(identifier: "onetime2", product: TestData.consumableProduct)
            ],
            webCheckoutUrl: nil
        )

        let tabsComponent = PaywallComponent.TabsComponent(
            control: .init(
                type: .buttons,
                stack: PaywallComponent.StackComponent(components: [
                    .tabControlButton(.init(tabId: Self.tab1Id, stack: Self.textStack("Subscribe"))),
                    .tabControlButton(.init(tabId: Self.tab2Id, stack: Self.textStack("One-off")))
                ])
            ),
            tabs: [
                .init(id: Self.tab1Id, stack: PaywallComponent.StackComponent(components: [
                    Self.packageComponent(packageID: "monthly", isSelectedByDefault: false),
                    Self.packageComponent(packageID: "annual", isSelectedByDefault: true)
                ])),
                .init(id: Self.tab2Id, stack: PaywallComponent.StackComponent(components: [
                    Self.packageComponent(packageID: "onetime1", isSelectedByDefault: true),
                    Self.packageComponent(packageID: "onetime2", isSelectedByDefault: false)
                ]))
            ],
            defaultTabId: Self.tab1Id
        )

        let factory = ViewModelFactory()
        guard case .tabs(let tabsViewModel) = try factory.toViewModel(
            component: .tabs(tabsComponent),
            packageValidator: factory.packageValidator,
            offering: offering,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        ) else {
            throw XCTSkip("Expected a .tabs PaywallComponentViewModel")
        }

        let tabControlContext = TabControlContext(
            controlStackViewModel: tabsViewModel.controlStackViewModel,
            tabIds: tabsViewModel.tabIds,
            defaultTabId: tabsViewModel.defaultTabId,
            name: nil
        )

        return (tabsViewModel, tabControlContext, offering)
    }

    static func tabsView(
        viewModel: TabsComponentViewModel,
        packageContext: PackageContext,
        workflowDefaultPackage: Package,
        tabControlContext: TabControlContext
    ) -> some View {
        LoadedTabsComponentView(
            viewModel: viewModel,
            parentPackageContext: packageContext,
            workflowDefaultPackage: workflowDefaultPackage,
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

    static func package(identifier: String, product: TestStoreProduct) -> Package {
        Package(
            identifier: identifier,
            packageType: .custom,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    static func packageComponent(packageID: String, isSelectedByDefault: Bool) -> PaywallComponent {
        .package(.init(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            applePromoOfferProductCode: nil,
            stack: Self.textStack(packageID)
        ))
    }

    static func textStack(_ text: String) -> PaywallComponent.StackComponent {
        PaywallComponent.StackComponent(components: [
            .text(.init(text: text, color: .init(light: .hex("#000000"))))
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

    static func settle(_ window: UIWindow) {
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

}

#endif
