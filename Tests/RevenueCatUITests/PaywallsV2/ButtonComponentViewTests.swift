//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentViewTests.swift
//
//  Created by RevenueCat on 5/19/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class ButtonComponentViewTests: TestCase {

    func testRenderedCarouselsOnlyPublishTheInitialActiveSlidesAction() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        for loops in [false, true] {
            let pages: [PaywallComponent.StackComponent] = (0..<3).map { index in
                .init(components: [.button(.init(
                    id: "slide-\(index)", action: .navigateBack,
                    stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
                ))], size: .init(width: .fill, height: .fixed(100)))
            }
            let data = PaywallComponentsData(
                templateName: "native-carousel", assetBaseURL: URL(string: "https://example.com")!,
                componentsConfig: .init(base: .init(
                    stack: .init(components: [.carousel(.init(pages: pages, initialPageIndex: 1, loop: loops))]),
                    stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
                )),
                componentsLocalizations: ["en_US": ["Close": .string("Close")]],
                revision: 1, defaultLocaleIdentifier: "en_US"
            )
            let components = Offering.PaywallComponents(uiConfig: PreviewUIConfig.make(), data: data)
            let offering = Offering(identifier: "native-carousel", serverDescription: "", paywallComponents: components,
                                    availablePackages: [TestData.annualPackage], webCheckoutUrl: nil)
            let coordinator = NativePaywallCloseCoordinator()
            var triggered: [String] = []
            let view = PaywallsV2View(
                paywallComponents: components, offering: offering, purchaseHandler: .mock(),
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker, showZeroDecimalPlacePrices: false,
                onDismiss: {}, failedToLoadFont: { _ in }, colorScheme: .light
            )
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environment(\.workflowTriggerAction, { triggered.append($0); return true })
            let (window, _) = Self.host(view)
            defer { window.isHidden = true; window.rootViewController = nil }
            let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                coordinator.actions.count == 1
            }, object: nil)
            await fulfillment(of: [registered], timeout: 2)
            try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
            XCTAssertEqual(triggered, ["slide-1"], "Only the visible original or loop copy may supply the callback")
        }
    }

    func testOnlyActiveCarouselPageRegistersAcrossLoopCopiesAndNestedCarousels() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        let (window, _) = Self.host(NativeCarouselRegistrationTestView(state: state)
            .environment(\.nativePaywallCloseCoordinator, coordinator))
        defer { window.isHidden = true; window.rootViewController = nil }
        for activeIndex in [1, 2, 4] {
            state.value = activeIndex
            let active = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                coordinator.actions.count == 1 && coordinator.actions.first?.label == "Slide \(activeIndex)"
            }, object: nil)
            await fulfillment(of: [active], timeout: 2)
            try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
            XCTAssertEqual(state.performed, activeIndex)
        }
        state.showsButton = false
        let inactiveAncestor = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.isEmpty
        }, object: nil)
        await fulfillment(of: [inactiveAncestor], timeout: 2)
        state.showsButton = true
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1 && coordinator.actions.first?.label == "Slide 4"
        }, object: nil)
        await fulfillment(of: [restored], timeout: 2)
    }

    func testNativeRegistrationRefreshesCallbackAndUnregistersWhenRemoved() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        var height: CGFloat = 0
        let view = NativeRegistrationTestView(state: state)
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        state.value = 2
        let updated = expectation(description: "Callback view updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { updated.fulfill() }
        await fulfillment(of: [updated], timeout: 2)
        try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
        XCTAssertEqual(state.performed, 2, "Callback changes must reach an already registered action")
        XCTAssertEqual(height, 88, accuracy: 0.5, "The registration primitive has zero size")
        state.showsButton = false
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.isEmpty
        }, object: nil)
        await fulfillment(of: [removed], timeout: 2)
    }

    func testInactiveWorkflowPageKeepsNativeHeaderCollapsedWithoutRegisteringActions() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let button = PaywallComponent.ButtonComponent(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        )
        let data = PaywallComponentsData(
            templateName: "native-header", assetBaseURL: URL(string: "https://example.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: []),
                header: .init(stack: .init(
                    components: [.button(button)], size: .init(width: .fill, height: .fixed(100))
                )),
                stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
            )),
            componentsLocalizations: ["en_US": ["Close": .string("Close")]],
            revision: 1, defaultLocaleIdentifier: "en_US"
        )
        let components = Offering.PaywallComponents(uiConfig: PreviewUIConfig.make(), data: data)
        let offering = Offering(identifier: "native-header", serverDescription: "", paywallComponents: components,
                                availablePackages: [TestData.annualPackage], webCheckoutUrl: nil)
        let coordinator = NativePaywallCloseCoordinator()
        var hiddenButtons = 0
        let view = PaywallsV2View(
            paywallComponents: components, offering: offering, purchaseHandler: .mock(),
            introEligibilityChecker: BaseSnapshotTest.eligibleChecker, showZeroDecimalPlacePrices: false,
            onDismiss: {}, failedToLoadFont: { _ in }, colorScheme: .light, isActiveWorkflowPage: false
        )
        .environment(\.nativePaywallCloseCoordinator, coordinator)
        .onPreferenceChange(NativePaywallHiddenButtonsKey.self) { hiddenButtons = $0.count }
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let settled = expectation(description: "Inactive page layout settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
        XCTAssertEqual(hiddenButtons, 1, "Inactive native buttons must remain placeholders")
        XCTAssertTrue(coordinator.actions.isEmpty, "Inactive pages must not own native toolbar actions")
    }

    func testRegisteredNativeButtonRunsItsActionWithoutMountingFallback() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        var actions = 0
        var fallbackAppearances = 0
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: { actions += 1 },
            content: { Button("Configured Close") {}.onAppear { fallbackAppearances += 1 } }
        )
        .environment(\.nativePaywallCloseCoordinator, coordinator)
        let (window, _) = Self.host(button)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
        XCTAssertEqual(actions, 1)
        XCTAssertEqual(fallbackAppearances, 0)
    }

    func testNativeButtonsDoNotLeaveFlexStackSpacers() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let markers: [PaywallComponent] = ["#FF0000", "#0000FF"].map { color in
            .stack(.init(components: [], size: .init(width: .fixed(20), height: .fixed(20)),
                         backgroundColor: .init(light: .hex(color))))
        }
        let button = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        for distribution: PaywallComponent.FlexDistribution in [.spaceBetween, .spaceAround, .spaceEvenly] {
            for dimension: PaywallComponent.Dimension in [
                .vertical(.center, distribution), .horizontal(.center, distribution)
            ] {
                func stack(_ children: [PaywallComponent]) -> PaywallComponent.StackComponent {
                    .init(components: children, dimension: dimension,
                          size: .init(width: .fixed(200), height: .fixed(200)), spacing: 24)
                }
                let reference = try await self.renderNativeStack(stack(markers), actions: 0)
                let native = try await self.renderNativeStack(stack([markers[0], button, markers[1]]), actions: 1)
                let empty = try await self.renderNativeStack(stack([]), actions: 0)
                XCTAssertNotEqual(reference.pngData(), empty.pngData(), "Markers must actually render")
                XCTAssertEqual(native.pngData(), reference.pngData(), "Native children must not affect flex spacing")
            }
        }
    }

    private func renderNativeStack(_ stack: PaywallComponent.StackComponent, actions: Int) async throws -> UIImage {
        let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        let view = StackComponentView(viewModel: model, onDismiss: {})
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        let (window, hosted) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == actions
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        let settled = expectation(description: "Flex layout settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
        window.layoutIfNeeded()
        hosted.layoutIfNeeded()
        return UIGraphicsImageRenderer(bounds: hosted.bounds).image { _ in
            hosted.drawHierarchy(in: hosted.bounds, afterScreenUpdates: true)
        }
    }

    func testNativeButtonsDoNotConsumeMainOrFooterStackSpacing() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let marker = PaywallComponent.stack(.init(components: [], size: .init(width: .fill, height: .fixed(20))))
        let stack = PaywallComponent.StackComponent(components: [marker, .button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        )), marker], spacing: 24)
        let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        var height: CGFloat = -1
        let view = StackComponentView(viewModel: model, onDismiss: {})
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { geometry in
                Color.clear.preference(key: NativeRegistrationHeightKey.self, value: geometry.size.height)
            })
            .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1 && abs(height - 64) < 0.5
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        XCTAssertEqual(height, 64, accuracy: 0.5)
    }

    func testNativeHeaderTracksHiddenSiblingsAndPreservesBadgesAcrossOverrides() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        for (hidesStack, hasBadge) in [(false, false), (true, false), (false, true), (true, true)] {
            let title = PaywallComponent.TextComponent(
                visible: hidesStack, text: "Title", color: .init(light: .hex("#000000")),
                overrides: hidesStack ? nil : [.init(conditions: [.selected], properties: .init(visible: true))]
            )
            let sibling: PaywallComponent = hidesStack ? .stack(.init(
                visible: false, components: [.text(title)],
                overrides: [.init(conditions: [.selected], properties: .init(visible: true))]
            )) : .text(title)
            let stack = PaywallComponent.StackComponent(
                components: [.button(.init(action: .navigateBack, stack: Self.makeButtonStack(label: "Close"),
                                           useNativeIfPossible: true)), sibling],
                size: .init(width: .fill, height: .fixed(100)),
                badge: hasBadge ? .init(style: .overlaid, alignment: .top, stack: .init(
                    components: [], size: .init(width: .fixed(20), height: .fixed(20)),
                    backgroundColor: .init(light: .hex("#FF0000"))
                )) : nil
            )
            let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["Title": .string("Title"), "Close": .string("Close")]
            ), colorScheme: .light)
            let state = NativeRegistrationTestState()
            var height: CGFloat = -1
            let content = HeaderComponentView(viewModel: .init(
                component: .init(stack: stack), stackViewModel: model, firstItemIgnoresSafeArea: false
            ), onDismiss: {})
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
                })
                .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
                .environment(\.nativePaywallCloseCoordinator, NativePaywallCloseCoordinator())
                .environmentObject(PurchaseHandler.default())
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
                .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
                .environment(\.safeAreaInsets, EdgeInsets())
            let (window, _) = Self.host(NativeHeaderVisibilityTestView(state: state, content: content))
            defer { window.isHidden = true; window.rootViewController = nil }
            for (value, expected) in [(1, CGFloat(hasBadge ? 100 : 0)), (2, 100), (1, hasBadge ? 100 : 0)] {
                state.value = value
                let resized = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    abs(height - expected) < 0.5
                }, object: nil)
                await fulfillment(of: [resized], timeout: 2)
            }
        }
    }

    func testButtonWithVisibleFalse_IsNotRendered() throws {
        let viewModel = try Self.makeViewModel(
            component: PaywallComponent.ButtonComponent(
                visible: false,
                action: .navigateBack,
                stack: Self.makeButtonStack(label: "Close")
            )
        )

        let view = ButtonComponentView(viewModel: viewModel, onDismiss: {})
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(
                IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
            )
            .environmentObject(
                PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker())
            )
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())

        let (window, hostedView) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertFalse(
            hostedView.containsText("Close"),
            "A button with visible=false should not be rendered."
        )
    }

    func testSelectedOverrideVisible_False_HidesWhenSelected() throws {
        let viewModel = try Self.makeViewModel(
            component: PaywallComponent.ButtonComponent(
                action: .navigateBack,
                stack: Self.makeButtonStack(label: "Close"),
                overrides: [
                    .init(conditions: [.selected], properties: .init(visible: false))
                ]
            )
        )

        let view = ButtonComponentView(viewModel: viewModel, onDismiss: {})
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(
                IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
            )
            .environmentObject(
                PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker())
            )
            .environment(\.componentViewState, .selected)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())

        let (window, hostedView) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertFalse(
            hostedView.containsText("Close"),
            "A button with a .selected override that hides should not render when selected."
        )
    }

    func testNativeCloseRunsExistingDismissalAndAnalytics() async throws {
        try await self.assertNativeCloseRunsExistingDismissalAndAnalytics(fullScreen: false)
    }

    func testNativeCloseIsDisabledDuringPurchaseAndRestore() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty,
                      "Generate with TUIST_UI_TESTS_HOST_APP=true to test native navigation controls.")
        let handler = PurchaseHandler.default()
        let viewModel = try Self.makeViewModel(component: .init(
            name: "close", action: .navigateBack,
            stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        var dismissals = 0
        var interactions = 0
        let owner = NativePaywallUIKitOwner()
        let view = Self.configuredView(viewModel: viewModel, purchaseHandler: handler,
                                       onDismiss: { dismissals += 1 })
            .environment(\.componentInteractionLogger, ComponentInteractionLogger { _ in
                interactions += 1
                return true
            })
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .uiKit(owner))
        let controller = UIHostingController(rootView: view)
        let navigation = UINavigationController(rootViewController: controller)
        owner.prepare(controller: controller)
        let window = UIWindow(windowScene: try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        ))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        for action in [PurchaseHandler.ActionType.purchase, .restore] {
            handler.actionTypeInProgress = action
            let settled = expectation(description: "Native disabled state updated")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
            await fulfillment(of: [settled], timeout: 2)
            let item = try XCTUnwrap(controller.navigationItem.rightBarButtonItem)
            XCTAssertFalse(item.isEnabled)
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
            await Task.yield()
            XCTAssertEqual(dismissals, 0)
            XCTAssertEqual(interactions, 0)
        }
        handler.actionTypeInProgress = nil
        let settled = expectation(description: "Native close re-enabled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
        let item = try XCTUnwrap(controller.navigationItem.rightBarButtonItem)
        XCTAssertTrue(item.isEnabled)
        let target = try XCTUnwrap(item.target as? NSObject)
        target.perform(try XCTUnwrap(item.action), with: item)
        await Task.yield()
        XCTAssertEqual(dismissals, 1)
        XCTAssertEqual(interactions, 1)
    }

    func testFullScreenNativeCloseDismissesAndTracksAnalytics() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty,
                      "Generate with TUIST_UI_TESTS_HOST_APP=true to test actual modal presentations.")
        try await self.assertNativeCloseRunsExistingDismissalAndAnalytics(fullScreen: true)
    }

    func testWorkflowHeaderBackAndClosePreserveActionsAndAnalytics() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let back = PaywallComponent.ButtonComponent(
            name: "workflow-back", action: .navigateBack,
            stack: Self.makeButtonStack(label: "Back"), useNativeIfPossible: true
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoder.encode(back)) as? [String: Any]
        )
        json["name"] = "workflow-close"
        json["action"] = ["type": "close_workflow", "use_native_if_possible": true]
        let close = try decoder.decode(
            PaywallComponent.ButtonComponent.self, from: JSONSerialization.data(withJSONObject: json)
        )
        let backModel = try Self.makeViewModel(component: back)
        let closeModel = try Self.makeViewModel(component: close)
        let wentBack = expectation(description: "Workflow navigated back")
        let closed = expectation(description: "Entire workflow closed")
        var interactions: [PaywallEvent.ComponentInteractionData] = []
        let owner = NativePaywallUIKitOwner()
        let view = VStack {
            Self.configuredView(viewModel: backModel, onDismiss: { XCTFail("Back must use workflow handler") })
            Self.configuredView(viewModel: closeModel, onDismiss: { XCTFail("Close must use workflow handler") })
        }
        .environment(\.workflowRenderingContext, .init(isHeader: true, canNavigateBack: true))
        .environment(\.workflowNavigateBackHandler, { wentBack.fulfill() })
        .environment(\.closeWorkflowAction, { closed.fulfill() })
        .environment(\.componentInteractionLogger, ComponentInteractionLogger { event in
            interactions.append(event)
            return true
        })
        .modifier(NativePaywallNavigationModifier(requested: true))
        .environment(\.nativePaywallNavigationContext, .uiKit(owner))
        let controller = UIHostingController(rootView: view)
        let navigation = UINavigationController(rootViewController: controller)
        owner.prepare(controller: controller)
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        } else {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        }
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let installed = expectation(description: "Both native header actions installed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { installed.fulfill() }
        await fulfillment(of: [installed], timeout: 2)
        let items = self.closeItems(in: controller)
        XCTAssertEqual(items.count, 2)
        for identifier in [NativePaywallUIKitOwner.backIdentifier, NativePaywallUIKitOwner.closeIdentifier] {
            let item = try XCTUnwrap(items.first { $0.accessibilityIdentifier == identifier })
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
        }
        await fulfillment(of: [wentBack, closed], timeout: 2)
        XCTAssertEqual(interactions.map(\.componentValue), ["navigate_back", "close_workflow"])
        XCTAssertEqual(interactions.map(\.componentName), ["workflow-back", "workflow-close"])
    }

    func testNativeOnlyHeaderCollapsesButDesignedHeaderRemains() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let cases: [(Bool, Bool, CGFloat, CGFloat)] = [
            (true, false, 0, 0), (true, false, 88, 88), (false, false, 0, 100), (true, true, 0, 100)
        ]
        for (native, hasOtherContent, safeAreaTop, expectedHeight) in cases {
            let button = PaywallComponent.ButtonComponent(
                action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: native
            )
            let buttonModel = try Self.makeViewModel(component: button)
            let stack = PaywallComponent.StackComponent(
                components: [.button(button)], size: .init(width: .fill, height: .fixed(100))
            )
            let children: [PaywallComponentViewModel] = [.button(buttonModel)]
                + (hasOtherContent ? buttonModel.stackViewModel.viewModels : [])
            let stackModel = StackComponentViewModel(
                component: stack, viewModels: children, badgeViewModels: [],
                uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make())
            )
            let header = HeaderComponentViewModel(
                component: .init(stack: stack), stackViewModel: stackModel, firstItemIgnoresSafeArea: false
            )
            var height: CGFloat = -1
            let view = HeaderComponentView(viewModel: header, onDismiss: {})
                .fixedSize(horizontal: false, vertical: true)
                .overlay(GeometryReader { geometry in
                    Color.clear.preference(key: NativeHeaderHeightTestKey.self, value: geometry.size.height)
                })
                .onPreferenceChange(NativeHeaderHeightTestKey.self) { height = $0 }
                .environment(\.nativePaywallCloseCoordinator, NativePaywallCloseCoordinator())
                .environmentObject(PurchaseHandler.default())
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(
                    IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
                )
                .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
                .environment(\.screenCondition, .compact)
                .environment(\.safeAreaInsets, EdgeInsets(top: safeAreaTop, leading: 0, bottom: 0, trailing: 0))
            let (window, _) = Self.host(view)
            let settled = expectation(description: "Header layout settled")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
            await fulfillment(of: [settled], timeout: 2)
            XCTAssertEqual(height, expectedHeight, accuracy: 0.5)
            window.isHidden = true
            window.rootViewController = nil
        }
    }

    func testDecodedNativePreferenceOverridesUpdateBodyAndHeaderWithoutDuplicates() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires the existing UnitTestsHostApp")
        for action in ["navigate_back", "close_workflow"] {
            for header in [false, true] {
                for base in [nil, false, true] as [Bool?] {
                    let fixture = try self.nativeOverrideFixture(
                        action: action, header: header, baseNative: base,
                        overrideProperties: ["action": ["use_native_if_possible": base != true]]
                    )
                    try await self.assertDecodedNativeTransitions(
                        fixture: fixture, widths: [800, 390, 800],
                        expectedNative: [base != true, base == true, base != true],
                        expectedFallback: [base == true, base != true, base == true],
                        invokeDismissal: false
                    )
                }
            }
        }
    }

    func testConfigurationPreflightInstallsHostForWindowRevealedButtonAndAncestor() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires the existing UnitTestsHostApp")
        for hiddenAncestor in [false, true] {
            let fixture = try self.nativeOverrideFixture(
                action: "navigate_back", header: hiddenAncestor, baseNative: true,
                overrideProperties: ["visible": true], hiddenButton: !hiddenAncestor,
                hiddenAncestor: hiddenAncestor
            )
            try await self.assertDecodedNativeTransitions(
                fixture: fixture, widths: [390, 800, 390, 800],
                expectedNative: [false, true, false, true], expectedFallback: [false, false, false, false],
                invokeDismissal: true
            )
        }
    }

    // The host request comes from the decoded configuration. The real PaywallsV2View measures
    // its rendered width, so changing the constraint re-evaluates the authored window rule.
    private func assertDecodedNativeTransitions(
        fixture: PaywallPreviewRenderer.Fixture,
        widths: [CGFloat],
        expectedNative: [Bool],
        expectedFallback: [Bool],
        invokeDismissal: Bool
    ) async throws {
        var dismissals = 0
        let width = NativePaywallWidthTestState(width: widths[0])
        let owner = NativePaywallUIKitOwner()
        let paywall = PaywallsV2View(
            paywallComponents: fixture.paywallComponents, offering: fixture.offering,
            purchaseHandler: .default(), introEligibilityChecker: BaseSnapshotTest.ineligibleChecker,
            showZeroDecimalPlacePrices: true, onDismiss: { dismissals += 1 },
            closeWorkflowAction: { dismissals += 1 },
            failedToLoadFont: { _ in }, colorScheme: .light
        )
        .environment(\.workflowRenderingContext, .init(canNavigateBack: true))
        .environment(\.paywallLoadingOverride, false)
        .modifier(NativePaywallNavigationModifier(
            paywallComponents: fixture.paywallComponents, workflowContext: nil
        ))
        .environment(\.nativePaywallNavigationContext, .uiKit(owner))
        let controller = UIHostingController(rootView: NativePaywallWidthTestView(state: width, content: paywall))
        let navigation = UINavigationController(rootViewController: controller)
        owner.prepare(controller: controller)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            scene.windows.first(where: { !$0.isHidden })?.makeKeyAndVisible()
        }
        for (index, newWidth) in widths.enumerated() {
            width.width = newWidth
            controller.view.layoutIfNeeded()
            // Flush mounting, geometry updates and native-source lifecycle work before counting controls.
            let settled = expectation(description: "Decoded native state settled at \(newWidth)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
            await fulfillment(of: [settled], timeout: 2)
            let (image, markerPixels) = try self.renderedFallbackMarker(in: window)
            let fallbackMatches = expectedFallback[index] ? markerPixels > 100 : markerPixels == 0
            XCTAssertEqual(self.closeItems(in: controller).count, expectedNative[index] ? 1 : 0)
            if !fallbackMatches {
                let attachment = XCTAttachment(image: image)
                attachment.name = "Designed fallback at \(newWidth)"
                attachment.lifetime = .keepAlways
                self.add(attachment)
            }
            if expectedFallback[index] {
                XCTAssertGreaterThan(markerPixels, 100, "Configured button must render at width \(newWidth)")
            } else {
                XCTAssertEqual(markerPixels, 0, "Configured button must be absent at width \(newWidth)")
            }
            XCTAssertEqual(navigation.viewControllers.count, 1, "Caller navigation remains intact")
        }
        if invokeDismissal {
            let item = try XCTUnwrap(self.closeItems(in: controller).first)
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
            let invoked = expectation(description: "Dismissal invoked")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { invoked.fulfill() }
            await fulfillment(of: [invoked], timeout: 2)
            XCTAssertEqual(dismissals, 1)
        }
    }

    /// The authored marker exists only inside the configured button, so it proves that the
    /// fallback is rendered even when SwiftUI does not expose its text as a UIKit subview.
    private func renderedFallbackMarker(in window: UIWindow) throws -> (UIImage, Int) {
        window.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        // Flush SwiftUI's pending display update before inspecting Core Animation's backing pixels.
        _ = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        let cgImage = try XCTUnwrap(image.cgImage)
        var pixels = [UInt8](repeating: 0, count: cgImage.width * cgImage.height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: cgImage.width, height: cgImage.height,
            bitsPerComponent: 8, bytesPerRow: cgImage.width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        let markerPixels = stride(from: 0, to: pixels.count, by: 4).filter { offset in
            pixels[offset] > 200 && pixels[offset + 1] < 60 && pixels[offset + 2] > 200
        }.count
        return (image, markerPixels)
    }

    private func nativeOverrideFixture(
        action: String,
        header: Bool,
        baseNative: Bool?,
        overrideProperties: [String: Any],
        hiddenButton: Bool = false,
        hiddenAncestor: Bool = false
    ) throws -> PaywallPreviewRenderer.Fixture {
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(PaywallPreviewRenderer.sampleJSON.utf8)
        ) as? [String: Any])
        var configs = try XCTUnwrap(payload["components_config"] as? [String: Any])
        var base = try XCTUnwrap(configs["base"] as? [String: Any])
        let stack = try XCTUnwrap(base["stack"] as? [String: Any])
        var label = try XCTUnwrap((stack["components"] as? [[String: Any]])?.first)
        label["text_lid"] = "configured_navigation"
        var buttonStack = stack
        buttonStack["components"] = [label]
        buttonStack["background_color"] = ["light": ["type": "hex", "value": "#FF00FF"]]
        buttonStack["padding"] = ["top": 12, "bottom": 12, "leading": 12, "trailing": 12]
        var actionJSON: [String: Any] = ["type": action]
        if let baseNative { actionJSON["use_native_if_possible"] = baseNative }
        let rule: [String: Any] = ["type": "window_width_condition", "operator": ">=", "value": 700]
        var button: [String: Any] = ["type": "button", "action": actionJSON, "stack": buttonStack]
        if hiddenButton { button["visible"] = false }
        if !hiddenAncestor {
            button["overrides"] = [["conditions": [rule], "properties": overrideProperties]]
        }
        var container = stack
        container["components"] = [button]
        if hiddenAncestor {
            container["visible"] = false
            container["overrides"] = [["conditions": [rule], "properties": overrideProperties]]
        }
        if header {
            base["header"] = ["stack": container]
            var body = stack
            body["components"] = []
            base["stack"] = body
        } else {
            base["stack"] = container
        }
        configs["base"] = base
        payload["components_config"] = configs
        payload["components_localizations"] = ["en_US": ["configured_navigation": "Configured navigation"]]
        let json = try JSONSerialization.data(withJSONObject: payload)
        return try PaywallPreviewRenderer.load(json: XCTUnwrap(String(data: json, encoding: .utf8)))
    }

    private func assertNativeCloseRunsExistingDismissalAndAnalytics(fullScreen: Bool) async throws {
        let viewModel = try Self.makeViewModel(
            component: PaywallComponent.ButtonComponent(
                name: "close", action: .navigateBack,
                stack: Self.makeButtonStack(label: "Configured Close"), useNativeIfPossible: true
            )
        )
        let dismissed = expectation(description: "Existing close action")
        var interactions: [PaywallEvent.ComponentInteractionData] = []
        weak var presentedController: UIViewController?
        let owner = NativePaywallUIKitOwner()
        let view = Self.configuredView(viewModel: viewModel, onDismiss: {
            if fullScreen { presentedController?.dismiss(animated: false) }
            dismissed.fulfill()
        })
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, fullScreen ? .standalone : .uiKit(owner))
            .environment(\.componentInteractionLogger, ComponentInteractionLogger { event in
                interactions.append(event)
                return true
            })
        let controller = UIHostingController(rootView: view)
        let navigation = UINavigationController(rootViewController: fullScreen ? UIViewController() : controller)
        owner.prepare(controller: controller)
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        } else {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        }
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            window.windowScene?.windows.first(where: { !$0.isHidden })?.makeKeyAndVisible()
        }
        if fullScreen {
            let ready = expectation(description: "Presenter ready")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { ready.fulfill() }
            await fulfillment(of: [ready], timeout: 2)
            controller.modalPresentationStyle = .fullScreen
            presentedController = controller
            navigation.present(controller, animated: false)
        }
        let installed = expectation(description: "Native close installed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { installed.fulfill() }
        await fulfillment(of: [installed], timeout: 2)
        if fullScreen {
            // Commit the rendered frame before invoking UIKit's SwiftUI toolbar control.
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            let image = renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
            let attachment = XCTAttachment(image: image)
            attachment.name = "Full-screen native Close"
            attachment.lifetime = .keepAlways
            self.add(attachment)
            let buttons = self.toolbarActions(in: controller.view)
            XCTAssertEqual(buttons.count, 1)
            let button = try XCTUnwrap(buttons.first)
            button.sendActions(for: .primaryActionTriggered)
        } else {
            let items = self.closeItems(in: controller)
            XCTAssertEqual(items.count, 1)
            let item = try XCTUnwrap(items.first)
            let selector = try XCTUnwrap(item.action)
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(selector, with: item)
        }
        await fulfillment(of: [dismissed], timeout: 2)
        XCTAssertEqual(interactions.count, 1)
        XCTAssertEqual(interactions.first?.componentValue, "navigate_back")
        XCTAssertEqual(interactions.first?.componentName, "close")
        if fullScreen {
            let closed = expectation(description: "Modal dismissed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { closed.fulfill() }
            await fulfillment(of: [closed], timeout: 2)
            XCTAssertNil(navigation.presentedViewController)
        }
    }

    private func toolbarActions(in view: UIView) -> [UIControl] {
        NativePaywallTestSupport.controls(of: UIControl.self, in: view)
            .filter { $0.allControlEvents.contains(.primaryActionTriggered) }
    }

    private func closeItems(in controller: UIViewController) -> [UIBarButtonItem] {
        let navigationItems = [controller.navigationItem]
            + ((controller as? UINavigationController)?.navigationBar.items ?? [])
        let items = navigationItems.flatMap {
            ($0.leftBarButtonItems ?? []) + ($0.rightBarButtonItems ?? [])
        } + controller.children.flatMap { self.closeItems(in: $0) }
        var seen = Set<ObjectIdentifier>()
        return items.filter { seen.insert(ObjectIdentifier($0)).inserted }
    }

    func testNativeButtonInNestedStackBadgeKeepsItsActionRegistered() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let badge = PaywallComponent.Badge(
            style: .overlaid, alignment: .top,
            stack: .init(components: [.button(.init(
                action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
            ))])
        )
        let model = try StackComponentViewModel(component: .init(components: [.stack(.init(
            components: Self.makeButtonStack(label: "Close").components, badge: badge
        ))]), localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        var backActions = 0
        let view = StackComponentView(viewModel: model, onDismiss: {})
            .environment(\.workflowNavigateBackHandler, { backActions += 1 })
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environment(\.safeAreaInsets, EdgeInsets())
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        let id = try XCTUnwrap(coordinator.actions.first?.id)
        let settled = expectation(description: "Badge registration remains stable")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
        XCTAssertEqual(coordinator.actions.map(\.id), [id])
        try await coordinator.performAction(id: id)
        XCTAssertEqual(backActions, 1)
    }

    func testPromotingNativeButtonsDoesNotRemountSiblingCarousel() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let dimensions: [PaywallComponent.Dimension] = [
            .vertical(.leading, .start), .horizontal(.center, .start), .zlayer(.center),
            .vertical(.leading, .spaceBetween), .horizontal(.center, .spaceBetween),
            .vertical(.leading, .spaceAround), .horizontal(.center, .spaceAround),
            .vertical(.leading, .spaceEvenly), .horizontal(.center, .spaceEvenly)
        ]
        for dimension in dimensions {
            let close = PaywallComponent.button(.init(
                action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
            ))
            let model = try StackComponentViewModel(component: .init(
                components: [close, .carousel(.init(pages: [Self.makeButtonStack(label: "Close")])), close],
                dimension: dimension, size: .init(width: .fixed(280), height: .fixed(180)), spacing: 8
            ), localizationProvider: .init(
                locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
            ), colorScheme: .light)
            guard case .carousel(let carousel) = model.viewModels[1] else { return XCTFail("Missing carousel") }
            var appearances = 0
            carousel.onViewAppear = { appearances += 1 }
            let state = NativeRegistrationTestState()
            state.showsButton = false
            let content = StackComponentView(viewModel: model, onDismiss: {})
                .environment(\.nativePaywallCloseCoordinator, NativePaywallCloseCoordinator())
                .environmentObject(PurchaseHandler.default())
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
                .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
                .environment(\.safeAreaInsets, EdgeInsets())
            let (window, _) = Self.host(NativePromotionTestView(state: state, content: content))
            defer { window.isHidden = true; window.rootViewController = nil }
            for presented in [false, true, false] {
                state.showsButton = presented
                let settled = expectation(description: "Native promotion settled")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
                await fulfillment(of: [settled], timeout: 2)
                XCTAssertEqual(appearances, 1, "Promotion must preserve carousel state in \(dimension)")
            }
        }
    }

    func testNativeRegistrationPreservesDismissalAndAnalytics() async throws {
        let coordinator = NativePaywallCloseCoordinator()
        let viewModel = try Self.makeViewModel(component: .init(
            name: "close", action: .navigateBack,
            stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        var dismissals = 0
        var interactions: [PaywallEvent.ComponentInteractionData] = []
        let view = Self.nativeTestView(viewModel: viewModel, onDismiss: { dismissals += 1 })
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environment(\.componentInteractionLogger, ComponentInteractionLogger { event in
                interactions.append(event)
                return true
            })
        let (window, hostedView) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        XCTAssertFalse(hostedView.containsText("Close"))
        try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
        XCTAssertEqual(dismissals, 1)
        XCTAssertEqual(interactions.count, 1)
        XCTAssertEqual(interactions.first?.componentValue, "navigate_back")
        XCTAssertEqual(interactions.first?.componentName, "close")
    }

    func testNativePreferenceWithoutHostRetainsConfiguredButton() async {
        let fallback = expectation(description: "Configured button is rendered without a native host")
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Close") {}.onAppear { fallback.fulfill() } }
        )
        let (window, _) = Self.host(button)
        defer { window.isHidden = true; window.rootViewController = nil }
        await fulfillment(of: [fallback], timeout: 2)
    }

    private static func nativeTestView(
        viewModel: ButtonComponentViewModel, onDismiss: @escaping () -> Void
    ) -> some View {
        ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ButtonComponentViewTests {

    static func configuredView(
        viewModel: ButtonComponentViewModel,
        purchaseHandler: PurchaseHandler = .default(),
        onDismiss: @escaping () -> Void
    ) -> some View {
        ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
            .environmentObject(purchaseHandler)
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(
                IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
            )
            .environmentObject(
                PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker())
            )
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())
    }

    static func makeViewModel(
        component: PaywallComponent.ButtonComponent
    ) throws -> ButtonComponentViewModel {
        let offering = Offering(
            identifier: "default",
            serverDescription: "",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let localizationProvider = LocalizationProvider(locale: Locale(identifier: "en_US"), localizedStrings: [
            "Close": .string("Close")
        ])
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()

        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            colorScheme: .light
        )

        return try ButtonComponentViewModel(
            component: component,
            localizationProvider: localizationProvider,
            offering: offering,
            stackViewModel: stackViewModel,
            uiConfigProvider: uiConfigProvider
        )
    }

    static func makeButtonStack(label: String) -> PaywallComponent.StackComponent {
        return PaywallComponent.StackComponent(
            components: [
                .text(
                    PaywallComponent.TextComponent(
                        text: label,
                        color: .init(light: .hex("#000000"))
                    )
                )
            ]
        )
    }

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(
            rootView: view
                .frame(width: 300, height: 200)
        )
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 200))
        } else {
            window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 200)))
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        return (window, controller.view)
    }

}

private extension UIView {

    func containsText(_ text: String) -> Bool {
        if let label = self as? UILabel, label.text == text {
            return true
        }

        if self.accessibilityLabel == text {
            return true
        }

        return self.subviews.contains { $0.containsText(text) }
    }

}

@available(iOS 15.0, *)
private struct NativeHeaderVisibilityTestView<Content: View>: View {
    @ObservedObject var state: NativeRegistrationTestState
    let content: Content
    var body: some View {
        self.content.environment(\.componentViewState, self.state.value == 1 ? .default : .selected)
    }
}

@available(iOS 15.0, *)
private struct NativePromotionTestView<Content: View>: View {
    @ObservedObject var state: NativeRegistrationTestState
    let content: Content
    var body: some View {
        self.content.environment(\.nativePaywallControlsPresented, self.state.showsButton)
    }
}

@MainActor
private final class NativeRegistrationTestState: ObservableObject {
    @Published var value = 1
    @Published var showsButton = true
    var performed = 0
}

@available(iOS 15.0, *)
private struct NativeCarouselRegistrationTestView: View {
    @ObservedObject var state: NativeRegistrationTestState
    var body: some View {
        VStack {
            ForEach(0..<9) { index in
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Slide \(index)",
                    role: index.isMultiple(of: 2) ? .back : .close,
                    action: { self.state.performed = index }, content: { EmptyView() }
                )
                .environment(\.carouselState, CarouselState(
                    activeIndex: self.state.value, pageIndex: index,
                    ancestorDistanceFromActive: self.state.showsButton ? 0 : 1
                ))
            }
        }
    }
}

@available(iOS 15.0, *)
private struct NativeRegistrationTestView: View {
    @ObservedObject var state: NativeRegistrationTestState
    var body: some View {
        let value = self.state.value
        VStack(spacing: 24) {
            Color.red.frame(height: 20)
            if self.state.showsButton {
                NativePaywallCloseButton(enabled: true, accessibilityLabel: "Close",
                                         action: { self.state.performed = value },
                                         content: { Color.clear.frame(height: 40) })
            }
            Color.blue.frame(height: 20)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
        })
    }
}

private struct NativeRegistrationHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

@MainActor
private final class NativePaywallWidthTestState: ObservableObject {
    @Published var width: CGFloat
    init(width: CGFloat) { self.width = width }
}

private struct NativePaywallWidthTestView<Content: View>: View {
    @ObservedObject var state: NativePaywallWidthTestState
    let content: Content
    var body: some View { self.content.frame(width: self.state.width, height: 300) }
}

private struct NativeHeaderHeightTestKey: PreferenceKey {
    static let defaultValue: CGFloat = -1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#endif
