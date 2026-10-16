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
        var dismissals = 0
        let view = StackComponentView(viewModel: model, onDismiss: { dismissals += 1 })
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
        XCTAssertEqual(dismissals, 1)
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
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 200)))
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

#endif
