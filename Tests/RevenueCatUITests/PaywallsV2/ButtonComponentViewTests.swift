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

    func testFullScreenNativeCloseDismissesAndTracksAnalytics() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty,
                      "Generate with TUIST_UI_TESTS_HOST_APP=true to test actual modal presentations.")
        try await self.assertNativeCloseRunsExistingDismissalAndAnalytics(fullScreen: true)
    }

    func testWorkflowHeaderBackAndClosePreserveActionsAndAnalytics() async throws {
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
        NativePaywallTestSupport.toolbarViews(of: UIControl.self, in: view)
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

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ButtonComponentViewTests {

    static func configuredView(
        viewModel: ButtonComponentViewModel, onDismiss: @escaping () -> Void
    ) -> some View {
        ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
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

#endif
