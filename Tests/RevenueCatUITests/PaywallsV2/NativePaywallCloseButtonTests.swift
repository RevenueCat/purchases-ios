//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

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

    func testSwiftUINavigationContainersInstallNativeClose() {
        if #available(iOS 16.0, *) {
            self.assertNativeClose { button in NavigationStack { button } }
            self.assertNativeClose { button in
                NavigationStack { NavigationView { button }.navigationViewStyle(.stack) }
            }
            self.assertNativeClose { button in
                NavigationView { NavigationStack { button } }.navigationViewStyle(.stack)
            }
        }
        self.assertNativeClose { button in NavigationView { button }.navigationViewStyle(.stack) }
    }

    func testMissingOrExplicitlyHiddenSwiftUINavigationKeepsFallback() {
        self.assertNativeClose(expected: false) { button in button }
        if #available(iOS 16.0, *) {
            self.assertNativeClose(expected: false) { button in
                NavigationStack { button.toolbar(.hidden, for: .navigationBar) }
            }
        }
    }

    private func assertNativeClose<Content: View>(
        expected: Bool = true,
        @ViewBuilder container: (NativePaywallCloseButton<Button<Text>>) -> Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var available = false
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: { available = $0 }
        )
        let host = UIHostingController(rootView: container(button))
        let window = self.host(host)
        defer { self.close(window) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
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
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return window
    }

    private func close(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
    }
}
#endif
