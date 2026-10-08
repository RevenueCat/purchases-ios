//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class NativePaywallCloseButtonTests: TestCase {

    func testKnownUIKitOwnerPreservesCallerButtonsAndRunsClose() async throws {
        let controller = UIViewController()
        let help = UIBarButtonItem(title: "Help", primaryAction: UIAction { _ in })
        controller.navigationItem.rightBarButtonItems = [help]
        let owner = NativePaywallUIKitOwner()
        let navigation = UINavigationController(rootViewController: controller)
        owner.prepare(controller: controller)
        XCTAssertNotNil(owner.context)
        var count = 0
        owner.install(.init(id: UUID(), label: "Close", perform: { count += 1 }))
        let items = try XCTUnwrap(controller.navigationItem.rightBarButtonItems)
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0] === help)
        let selector = try XCTUnwrap(items[1].action)
        let target = try XCTUnwrap(items[1].target as? NSObject)
        target.perform(selector, with: items[1])
        await self.waitForPresentation()
        XCTAssertEqual(count, 1)
        owner.removeClose()
        XCTAssertEqual(controller.navigationItem.rightBarButtonItems?.count, 1)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === help)
        XCTAssertTrue(controller.navigationController === navigation)
    }

    func testUIKitWorkflowBackAndCloseRunSeparateActions() async throws {
        let controller = UIViewController()
        let help = UIBarButtonItem(title: "Help", primaryAction: UIAction { _ in })
        controller.navigationItem.rightBarButtonItems = [help]
        let navigation = UINavigationController(rootViewController: controller)
        let owner = NativePaywallUIKitOwner()
        owner.prepare(controller: controller)
        var backs = 0
        var closes = 0
        owner.install([
            .init(id: UUID(), label: "Back", perform: { backs += 1 }, role: .back),
            .init(id: UUID(), label: "Close", perform: { closes += 1 })
        ])
        let back = try XCTUnwrap(controller.navigationItem.leftBarButtonItem)
        let close = try XCTUnwrap(controller.navigationItem.rightBarButtonItems?.last)
        XCTAssertEqual(back.accessibilityIdentifier, NativePaywallUIKitOwner.backIdentifier)
        XCTAssertEqual(close.accessibilityIdentifier, NativePaywallUIKitOwner.closeIdentifier)
        XCTAssertEqual(controller.navigationItem.rightBarButtonItems?.count, 2)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItems?.first === help)
        for item in [back, close] {
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
        }
        await self.waitForPresentation()
        XCTAssertEqual(backs, 1)
        XCTAssertEqual(closes, 1)
        owner.removeClose()
        XCTAssertTrue(controller.navigationItem.leftBarButtonItems?.isEmpty == true)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === help)
        XCTAssertTrue(controller.navigationController === navigation)
    }

    func testCoordinatorUpdatesBackToCloseWithoutDuplicateRegistration() {
        let coordinator = NativePaywallCloseCoordinator()
        let backID = UUID()
        let closeID = UUID()
        coordinator.register(id: backID, label: "Back", role: .back, action: {})
        coordinator.register(id: closeID, label: "Close", action: {})
        XCTAssertEqual(coordinator.action(for: .back)?.id, backID)
        XCTAssertEqual(coordinator.action(for: .close)?.id, closeID)
        coordinator.register(id: backID, label: "Close", role: .close, action: {})
        XCTAssertNil(coordinator.action(for: .back))
        XCTAssertEqual(coordinator.actions.count, 2)
        XCTAssertEqual(coordinator.action(for: .close)?.id, backID)
        coordinator.unregister(id: backID)
        XCTAssertEqual(coordinator.action(for: .close)?.id, closeID)
    }

    func testExplicitWorkflowCloseTakesDismissalSlotAtRoot() {
        let coordinator = NativePaywallCloseCoordinator()
        let backID = UUID()
        let closeID = UUID()
        coordinator.register(id: backID, label: "Back at root", action: {})
        coordinator.register(id: closeID, label: "Close workflow", isWorkflowClose: true, action: {})
        XCTAssertEqual(coordinator.action(for: .close)?.id, closeID)
        coordinator.unregister(id: closeID)
        XCTAssertEqual(coordinator.action(for: .close)?.id, backID)
    }

    func testOneNativeActionOwnerHandlesRegistrationAndRemoval() {
        let coordinator = NativePaywallCloseCoordinator()
        let first = UUID()
        let second = UUID()
        coordinator.register(id: first, label: "First", action: {})
        coordinator.register(id: first, label: "First", action: {})
        coordinator.register(id: second, label: "Second", action: {})
        XCTAssertEqual(coordinator.actions.count, 2)
        XCTAssertEqual(coordinator.actions.first?.id, first)
        coordinator.unregister(id: first)
        XCTAssertEqual(coordinator.actions.first?.id, second)
        coordinator.unregister(id: second)
        XCTAssertTrue(coordinator.actions.isEmpty)
    }

    func testSwiftUINavigationContainersInstallNativeClose() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose { button in
                NavigationStack { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
            }
            await self.assertNativeClose { button in
                NavigationStack {
                    NavigationView { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
                        .navigationViewStyle(.stack)
                }
            }
            await self.assertNativeClose { button in
                NavigationView {
                    NavigationStack { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
                }.navigationViewStyle(.stack)
            }
        }
        await self.assertNativeClose { button in
            NavigationView { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
                .navigationViewStyle(.stack)
        }
    }

    func testWithoutNativeCloseHostKeepsFallback() async {
        await self.assertNativeClose(expected: false) { button in button }
    }

    func testMissingNavigationWrapperInstallsNativeClose() async {
        await self.assertNativeClose { button in button.modifier(NativePaywallNavigationModifier(requested: true)) }
    }

    func testBlogDetectionReusesNavigationStack() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose(expectedNavigationCount: 1) { button in
                NavigationStack {
                    button.modifier(NativePaywallNavigationModifier(requested: true)).navigationTitle("Paywall")
                }
            }
        }
    }

    func testBlogFallbackInLegacyNavigationStillShowsOnlyOneClose() async {
        // The blog detector can miss NavigationView on iOS 26. Its fallback must still mount
        // the paywall once and render one Close, even when a nested stack is added.
        var appearances = 0
        var disappearances = 0
        let host = UIHostingController(rootView:
            NavigationView {
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Close", action: {},
                    content: { Button("Configured Close") {} }
                )
                .onAppear { appearances += 1 }
                .onDisappear { disappearances += 1 }
                .modifier(NativePaywallNavigationModifier(requested: true))
                .navigationTitle("Paywall")
            }.navigationViewStyle(.stack)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(appearances, 1)
        XCTAssertEqual(disappearances, 0)
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
    }

    func testKnownOwnerUpdatesWhenControllerMovesIntoNavigation() {
        let controller = UIViewController()
        let owner = NativePaywallUIKitOwner()
        owner.prepare(controller: controller)
        guard case .standalone? = owner.context else {
            return XCTFail("Standalone controller should request its own navigation")
        }
        let navigation = UINavigationController(rootViewController: controller)
        owner.prepare(controller: controller)
        guard case .uiKit? = owner.context else {
            return XCTFail("Existing UIKit navigation should be reused")
        }
        XCTAssertTrue(controller.navigationController === navigation)
    }

    func testFullScreenPresentationAddsMissingNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: true, existingNavigation: false, style: .fullScreen)
    }

    func testSheetPresentationAddsMissingNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: true, existingNavigation: false, style: .pageSheet)
    }

    func testFullScreenPresentationReusesExistingNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: true, existingNavigation: true, style: .fullScreen)
    }

    func testNativeCloseDisabledDoesNotAddNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: false, existingNavigation: false, style: .fullScreen)
    }

    func testSwiftUIFullScreenCoverAddsMissingNavigation() async throws {
        try self.requireAppHost()
        var available = false
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: { available = $0 }
        )
        let presenter = UIHostingController(rootView:
            Color.clear.fullScreenCover(isPresented: .constant(true)) {
                button.modifier(NativePaywallNavigationModifier(requested: true))
            }
        )
        let window = self.host(presenter)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertNotNil(presenter.presentedViewController)
        XCTAssertTrue(available)
        XCTAssertEqual(self.navigationCount(in: presenter.presentedViewController), 1)
    }

    func testPreflightMountsPaywallOnlyOnceInItsFinalContainer() async {
        var appearCount = 0
        var disappearCount = 0
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }
        )
        let host = UIHostingController(rootView:
            VStack {
                Text("Paywall content")
                button
            }
            .onAppear { appearCount += 1 }
            .onDisappear { disappearCount += 1 }
            .modifier(NativePaywallNavigationModifier(requested: true))
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(appearCount, 1)
        XCTAssertEqual(disappearCount, 0)
        XCTAssertEqual(self.navigationCount(in: host), 1)
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
    }

    func testNoEligibleCloseDoesNotCreateEmptyToolbarButton() async {
        let host = UIHostingController(rootView:
            Text("Paywall without a close button")
                .modifier(NativePaywallNavigationModifier(requested: true))
                .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 0)
    }

    func testMultipleEligibleCloseComponentsCreateOnlyOneNativeButton() async {
        var configuredAppearances = 0
        let host = UIHostingController(rootView:
            VStack {
                ForEach(0..<2) { index in
                    NativePaywallCloseButton(
                        enabled: true, accessibilityLabel: "Close \(index)", action: {},
                        content: { Button("Configured Close") {}.onAppear { configuredAppearances += 1 } }
                    )
                }
            }
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
        XCTAssertEqual(configuredAppearances, 1)
        XCTAssertEqual(self.navigationCount(in: host), 1)
    }

    func testReturningToRootDoesNotRestoreDesignedBackOrRegisterTransitionCopies() async {
        let state = NativeWorkflowHeaderTestState()
        let coordinator = NativePaywallCloseCoordinator()
        var configuredAppearances = 0
        let host = UIHostingController(rootView:
            NativeWorkflowHeaderTestView(state: state, configuredAppeared: { configuredAppearances += 1 })
                .environment(\.nativePaywallCloseCoordinator, coordinator)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(coordinator.actions.count, 2)
        XCTAssertNil(coordinator.action(for: .back))
        XCTAssertTrue(coordinator.action(for: .close)?.isWorkflowClose == true)
        XCTAssertEqual(configuredAppearances, 0)

        for canNavigateBack in [true, false, true, false] {
            state.canNavigateBack = canNavigateBack
            state.showsTransitionCopy = true
            await self.waitForPresentation()
            XCTAssertEqual(coordinator.actions.count, 2, "The animated header must not register copies")
            XCTAssertEqual(coordinator.action(for: .back) != nil, canNavigateBack)
            XCTAssertEqual(configuredAppearances, 0)
            state.showsTransitionCopy = false
            await self.waitForPresentation()
            XCTAssertEqual(coordinator.actions.count, 2)
            XCTAssertEqual(configuredAppearances, 0, "Returning to root must not restore the redundant Back")
        }
    }

    func testSwiftUIHeaderShowsSeparateNativeBackAndClose() async {
        var backRegistered = false
        var closeRegistered = false
        let host = UIHostingController(rootView:
            VStack {
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Back", role: .back, action: {},
                    content: { Button("Designed Back") {} },
                    availabilityChanged: { backRegistered = $0 }
                )
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                    content: { Button("Designed Close") {} },
                    availabilityChanged: { closeRegistered = $0 }
                )
            }
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        self.commitFrame(window)
        XCTAssertTrue(backRegistered)
        XCTAssertTrue(closeRegistered)
        // SwiftUI's Back is hosted content, not a UIButton. Close and any automatic host Back
        // are UIKit buttons. There should only be the single native Close here.
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
        XCTAssertEqual(self.navigationCount(in: host), 1)
    }

    func testPushedWorkflowBackDoesNotDuplicateHostBack() async throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("NavigationStack requires iOS 16") }
        var backRegistered = false
        var closeRegistered = false
        let host = UIHostingController(rootView:
            NavigationStack(path: .constant([1])) {
                Text("Account")
                    .navigationDestination(for: Int.self) { _ in
                        VStack {
                            NativePaywallCloseButton(
                                enabled: true, accessibilityLabel: "Back", role: .back, action: {},
                                content: { Button("Designed Back") {} },
                                availabilityChanged: { backRegistered = $0 }
                            )
                            NativePaywallCloseButton(
                                enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                                content: { Button("Designed Close") {} },
                                availabilityChanged: { closeRegistered = $0 }
                            )
                        }
                        .modifier(NativePaywallCloseHost())
                        .navigationTitle("Upgrade")
                    }
            }
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        self.commitFrame(window)
        XCTAssertTrue(backRegistered)
        XCTAssertTrue(closeRegistered)
        // SwiftUI's Back is hosted content, not a UIButton. Close and any automatic host Back
        // are UIKit buttons. There should only be the single native Close here.
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
    }

    func testConfigurationRequestsPreflightOnlyForNativeCloseActions() {
        func requested(native: Bool, visible: Bool? = nil, action: PaywallComponent.ButtonComponent.Action) -> Bool {
            let config = PaywallComponentsData.ComponentsConfig(base: .init(
                stack: .init(components: [.stack(.init(components: [.button(.init(
                    visible: visible, action: action, stack: .init(components: []), useNativeIfPossible: native
                ))]))]),
                stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
            ))
            let data = PaywallComponentsData(
                templateName: "components", assetBaseURL: URL(string: "https://example.com")!,
                componentsConfig: config, componentsLocalizations: ["en_US": [:]],
                revision: 0, defaultLocaleIdentifier: "en_US"
            )
            return NativePaywallNavigationModifier(
                paywallComponents: .init(uiConfig: PreviewUIConfig.make(), data: data),
                workflowContext: nil, preferredLocale: Locale(identifier: "en_US")
            ).requested
        }
        XCTAssertTrue(requested(native: true, action: .navigateBack))
        XCTAssertFalse(requested(native: false, action: .navigateBack))
        XCTAssertFalse(requested(native: true, visible: false, action: .navigateBack))
        XCTAssertFalse(requested(native: true, action: .restorePurchases))
    }

    private func toolbarButtons(in view: UIView) -> [UIButton] {
        NativePaywallTestSupport.toolbarViews(of: UIButton.self, in: view)
    }

    private func assertModalNativeClose(
        enabled: Bool,
        existingNavigation: Bool,
        style: UIModalPresentationStyle,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        var available = false
        var reportedInstalled = false
        let installed = enabled ? expectation(description: "Native close visible") : nil
        let button = NativePaywallCloseButton(
            enabled: enabled, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: {
                available = $0
                if $0 && !reportedInstalled {
                    reportedInstalled = true
                    installed?.fulfill()
                }
            }
        )
        let owner = NativePaywallUIKitOwner()
        let host = UIHostingController(rootView:
            VStack {
                Text("Sample paywall")
                button
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(NativePaywallNavigationModifier(requested: enabled))
            .environment(\.nativePaywallNavigationContext, existingNavigation ? .uiKit(owner) : .standalone)
        )
        let modal: UIViewController = existingNavigation ? UINavigationController(rootViewController: host) : host
        owner.prepare(controller: host)
        modal.modalPresentationStyle = style
        // Navigation in the presenter must not be mistaken for navigation in its modal.
        let presenter = UINavigationController(rootViewController: UIViewController())
        let window = self.host(presenter)
        defer { self.close(window) }
        await self.waitForPresentation()
        presenter.present(modal, animated: false)
        if let installed { await fulfillment(of: [installed], timeout: 3) }
        await self.waitForPresentation()
        XCTAssertTrue(presenter.presentedViewController === modal, file: file, line: line)
        XCTAssertEqual(available, enabled, file: file, line: line)
        XCTAssertEqual(self.navigationCount(in: modal), enabled ? 1 : 0, file: file, line: line)
        XCTAssertEqual(self.toolbarButtons(in: modal.view).count, enabled ? 1 : 0, file: file, line: line)
        modal.dismiss(animated: false)
        await self.waitForPresentation()
        XCTAssertNil(presenter.presentedViewController, file: file, line: line)
    }

    private func commitFrame(_ window: UIWindow) {
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Workflow native navigation"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    private func requireAppHost() throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty,
                      "Generate with TUIST_UI_TESTS_HOST_APP=true to test actual modal presentations.")
    }

    private func waitForPresentation() async {
        let settled = expectation(description: "Presentation settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
    }

    private func navigationCount(in controller: UIViewController?) -> Int {
        guard let controller else { return 0 }
        return (controller is UINavigationController ? 1 : 0)
            + controller.children.reduce(0) { $0 + self.navigationCount(in: $1) }
    }

    private func assertNativeClose<Content: View>(
        expected: Bool = true,
        expectedNavigationCount: Int? = nil,
        @ViewBuilder container: (NativePaywallCloseButton<Button<Text>>) -> Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        var available = false
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: { available = $0 }
        )
        let host = UIHostingController(rootView: container(button))
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(available, expected, file: file, line: line)
        if let expectedNavigationCount {
            XCTAssertEqual(self.navigationCount(in: host), expectedNavigationCount, file: file, line: line)
        }
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, expected ? 1 : 0, file: file, line: line)
    }

    private func host(_ controller: UIViewController) -> UIWindow {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        } else {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return window
    }

    private func close(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
        window.windowScene?.windows.first(where: { !$0.isHidden })?.makeKeyAndVisible()
    }
}
// SwiftUI navigation on iOS 26 owns toolbar controls separately from controller.navigationItem.
@available(iOS 15.0, *)
@MainActor
enum NativePaywallTestSupport {
    static func toolbarViews<T: UIView>(of type: T.Type, in view: UIView) -> [T] {
        func descendants(in view: UIView) -> [T] {
            if let result = view as? T { return [result] }
            return view.subviews.flatMap { descendants(in: $0) }
        }
        if view is UINavigationBar { return descendants(in: view) }
        return view.subviews.flatMap { self.toolbarViews(of: type, in: $0) }
    }
}
@available(iOS 15.0, *)
@MainActor
private final class NativeWorkflowHeaderTestState: ObservableObject {
    @Published var canNavigateBack = false
    @Published var showsTransitionCopy = false
}

@available(iOS 15.0, *)
private struct NativeWorkflowHeaderTestView: View {
    @ObservedObject var state: NativeWorkflowHeaderTestState
    let configuredAppeared: () -> Void

    var body: some View {
        VStack {
            self.header
            if self.state.showsTransitionCopy {
                self.header.environment(\.nativePaywallButtonRegistrationEnabled, false)
            }
        }
    }

    private var header: some View {
        HStack {
            NativePaywallCloseButton(
                enabled: true, accessibilityLabel: "Back",
                role: self.state.canNavigateBack ? .back : .close, action: {},
                content: { Text("Designed Back").onAppear(perform: self.configuredAppeared) }
            )
            NativePaywallCloseButton(
                enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                content: { Text("Designed Close").onAppear(perform: self.configuredAppeared) }
            )
        }
    }
}

#endif
