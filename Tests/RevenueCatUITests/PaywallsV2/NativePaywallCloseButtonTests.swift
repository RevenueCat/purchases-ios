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

    func testMissingNavigationKeepsFallback() {
        let observer = NativePaywallCloseBridge.NavigationObserver()
        let window = self.host(observer)
        defer { self.close(window) }
        let coordinator = NativePaywallCloseBridge.Coordinator()
        var available = false
        coordinator.availabilityChanged = { available = $0 }
        coordinator.update(from: observer)
        XCTAssertFalse(available)
        XCTAssertNil(observer.navigationItem.rightBarButtonItems)
        XCTAssertNil(observer.navigationController)
    }

    func testUIKitNavigationInstallsOneCloseAndPreservesCallerButtons() throws {
        let owner = UIViewController()
        let callerItem = UIBarButtonItem(title: "Help", primaryAction: UIAction { _ in })
        owner.navigationItem.rightBarButtonItems = [callerItem]
        let observer = self.attachObserver(to: owner)
        let navigation = UINavigationController(rootViewController: owner)
        let window = self.host(navigation)
        defer { self.close(window) }
        let coordinator = NativePaywallCloseBridge.Coordinator()
        var available = false
        coordinator.availabilityChanged = { available = $0 }
        coordinator.closeLabel = "Close"
        var closeCount = 0
        coordinator.action = { closeCount += 1 }
        coordinator.update(from: observer)
        coordinator.update(from: observer)
        XCTAssertTrue(available)
        let items = try XCTUnwrap(owner.navigationItem.rightBarButtonItems)
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0] === callerItem)
        XCTAssertEqual(items[1].accessibilityLabel, "Close")
        let selector = try XCTUnwrap(items[1].action)
        let target = try XCTUnwrap(items[1].target as? NSObject)
        target.perform(selector, with: items[1])
        XCTAssertEqual(closeCount, 1)
        coordinator.removeItem()
        XCTAssertEqual(owner.navigationItem.rightBarButtonItems?.count, 1)
        XCTAssertTrue(owner.navigationItem.rightBarButtonItem === callerItem)
    }

    func testMultipleCloseButtonsDoNotShareActionsOrInstallDuplicates() {
        let owner = UIViewController()
        let firstObserver = self.attachObserver(to: owner)
        let secondObserver = self.attachObserver(to: owner)
        let navigation = UINavigationController(rootViewController: owner)
        let window = self.host(navigation)
        defer { self.close(window) }
        let first = NativePaywallCloseBridge.Coordinator()
        let second = NativePaywallCloseBridge.Coordinator()
        var secondAvailable = false
        second.availabilityChanged = { secondAvailable = $0 }
        first.update(from: firstObserver)
        second.update(from: secondObserver)
        XCTAssertFalse(secondAvailable)
        XCTAssertEqual(owner.navigationItem.rightBarButtonItems?.count, 1)
        first.releaseOwnership()
        second.update(from: secondObserver)
        XCTAssertTrue(secondAvailable)
        XCTAssertEqual(owner.navigationItem.rightBarButtonItems?.count, 1)
        second.releaseOwnership()
    }

    func testHiddenNavigationBarKeepsFallback() {
        let owner = UIViewController()
        let observer = self.attachObserver(to: owner)
        let navigation = UINavigationController(rootViewController: owner)
        let window = self.host(navigation)
        defer { self.close(window) }
        let coordinator = NativePaywallCloseBridge.Coordinator()
        var availability: [Bool] = []
        coordinator.availabilityChanged = { availability.append($0) }
        coordinator.update(from: observer)
        navigation.setNavigationBarHidden(true, animated: false)
        coordinator.update(from: observer)
        XCTAssertEqual(availability, [true, false])
        XCTAssertTrue(owner.navigationItem.rightBarButtonItems?.isEmpty ?? true)
    }

    func testOffscreenControllerCannotInstallCloseOnAnotherScreen() {
        let account = UIViewController()
        let paywall = UIViewController()
        let observer = self.attachObserver(to: paywall)
        let navigation = UINavigationController(rootViewController: account)
        navigation.pushViewController(paywall, animated: false)
        let window = self.host(navigation)
        defer { self.close(window) }
        let coordinator = NativePaywallCloseBridge.Coordinator()
        coordinator.update(from: observer)
        navigation.popViewController(animated: false)
        coordinator.update(from: observer)
        XCTAssertNil(account.navigationItem.rightBarButtonItems)
        XCTAssertTrue(paywall.navigationItem.rightBarButtonItems?.isEmpty ?? true)
    }

    func testNestedNavigationUsesNearestOwner() {
        let innerOwner = UIViewController()
        let observer = self.attachObserver(to: innerOwner)
        let inner = UINavigationController(rootViewController: innerOwner)
        let outerOwner = UIViewController()
        outerOwner.addChild(inner)
        outerOwner.view.addSubview(inner.view)
        inner.didMove(toParent: outerOwner)
        let outer = UINavigationController(rootViewController: outerOwner)
        let window = self.host(outer)
        defer { self.close(window) }
        let coordinator = NativePaywallCloseBridge.Coordinator()
        coordinator.update(from: observer)
        XCTAssertEqual(innerOwner.navigationItem.rightBarButtonItems?.count, 1)
        XCTAssertNil(inner.navigationItem.rightBarButtonItems)
    }

    func testSwiftUINavigationContainersInstallNativeClose() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose { button in NavigationStack { button.navigationTitle("Paywall") } }
            await self.assertNativeClose { button in
                NavigationStack { NavigationView { button.navigationTitle("Paywall") }.navigationViewStyle(.stack) }
            }
            await self.assertNativeClose { button in
                NavigationView {
                    NavigationStack { button.navigationTitle("Paywall") }
                }.navigationViewStyle(.stack)
            }
        }
        await self.assertNativeClose { button in
            NavigationView { button.navigationTitle("Paywall") }.navigationViewStyle(.stack)
        }
    }

    func testMissingOrExplicitlyHiddenSwiftUINavigationKeepsFallback() async {
        await self.assertNativeClose(expected: false) { button in button }
        if #available(iOS 16.0, *) {
            await self.assertNativeClose(expected: false) { button in
                NavigationStack { button.toolbar(.hidden, for: .navigationBar) }
            }
        }
    }

    func testMissingNavigationWrapperInstallsNativeClose() async {
        await self.assertNativeClose { button in button.modifier(NativePaywallNavigationModifier(requested: true)) }
    }

    func testWrapperReusesSwiftUINavigation() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose { button in
                NavigationStack {
                    button.modifier(NativePaywallNavigationModifier(requested: true)).navigationTitle("Paywall")
                }
            }
        }
        await self.assertNativeClose { button in
            NavigationView {
                button.modifier(NativePaywallNavigationModifier(requested: true)).navigationTitle("Paywall")
            }.navigationViewStyle(.stack)
        }
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
        XCTAssertEqual(self.allBarItems(in: host).count, 1)
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

    private func allBarItems(in controller: UIViewController) -> [UIBarButtonItem] {
        (controller.navigationItem.leftBarButtonItems ?? [])
            + (controller.navigationItem.rightBarButtonItems ?? [])
            + controller.children.flatMap { self.allBarItems(in: $0) }
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
        let host = UIHostingController(rootView:
            VStack {
                Text("Sample paywall")
                button
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(NativePaywallNavigationModifier(requested: enabled))
        )
        let modal: UIViewController = existingNavigation ? UINavigationController(rootViewController: host) : host
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
        XCTAssertEqual(self.allBarItems(in: modal).count, enabled ? 1 : 0, file: file, line: line)
        modal.dismiss(animated: false)
        await self.waitForPresentation()
        XCTAssertNil(presenter.presentedViewController, file: file, line: line)
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
        XCTAssertLessThanOrEqual(self.nativeItems(in: host).count, 1, file: file, line: line)
    }

    private func nativeItems(in controller: UIViewController) -> [UIBarButtonItem] {
        let own = (controller.navigationItem.rightBarButtonItems ?? []).filter {
            $0.accessibilityIdentifier == NativePaywallCloseBridge.Coordinator.identifier
        }
        return own + controller.children.flatMap { self.nativeItems(in: $0) }
    }

    private func attachObserver(to owner: UIViewController) -> NativePaywallCloseBridge.NavigationObserver {
        let observer = NativePaywallCloseBridge.NavigationObserver()
        owner.addChild(observer)
        owner.view.addSubview(observer.view)
        observer.didMove(toParent: owner)
        return observer
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
#endif
