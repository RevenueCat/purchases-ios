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
            paywallComponents: fixture.paywallComponents, workflowContext: nil,
            preferredLocale: Locale(identifier: "en_US")
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
