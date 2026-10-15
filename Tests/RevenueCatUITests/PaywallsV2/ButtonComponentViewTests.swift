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
