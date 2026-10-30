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
final class NativePaywallUIKitTests: NativePaywallNavigationTestCase {

    func testNativeControlsHideCallerBackAndRestoreItsOriginalVisibility() {
        for originallyHidden in [false, true] {
            let controller = UIViewController()
            let navigation = UINavigationController(rootViewController: UIViewController())
            navigation.pushViewController(controller, animated: false)
            controller.navigationItem.hidesBackButton = originallyHidden
            let caller = UIBarButtonItem(title: "Caller", primaryAction: UIAction { _ in })
            controller.navigationItem.leftBarButtonItems = [caller]
            let owner = NativePaywallUIKitOwner()
            owner.prepare(controller: controller)
            for role in [NativePaywallCloseCoordinator.Role.close, .back, .close] {
                owner.install([.init(id: UUID(), label: "Native", perform: {}, role: role)])
                XCTAssertTrue(controller.navigationItem.hidesBackButton)
                XCTAssertTrue(controller.navigationItem.leftBarButtonItems?.first === caller)
            }
            owner.install([])
            XCTAssertEqual(controller.navigationItem.hidesBackButton, originallyHidden)
            XCTAssertTrue(controller.navigationItem.leftBarButtonItem === caller)
            owner.install([.init(id: UUID(), label: "Close", perform: {})])
            owner.removeClose()
            XCTAssertEqual(controller.navigationItem.hidesBackButton, originallyHidden)
            XCTAssertTrue(controller.navigationController === navigation)
        }
    }

    func testReplacedHostCannotRemoveOrReinstallOverTheCurrentHostsControls() async throws {
        let controller = UIViewController()
        let navigation = UINavigationController(rootViewController: controller)
        let owner = NativePaywallUIKitOwner()
        owner.prepare(controller: controller)
        let previous = NativePaywallCloseCoordinator()
        let current = NativePaywallCloseCoordinator()
        var previousTaps = 0
        var currentTaps = 0
        previous.register(id: UUID(), label: "Previous", action: { previousTaps += 1 })
        current.register(id: UUID(), label: "Current", action: { currentTaps += 1 })
        owner.activate(previous)
        owner.activate(current)
        let currentItem = try XCTUnwrap(controller.navigationItem.rightBarButtonItem)
        owner.removeClose(from: previous)
        owner.install(previous.actions, from: previous)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === currentItem,
                      "A replaced host's late disappearance and publisher cannot alter the new controls")
        XCTAssertEqual(currentItem.accessibilityLabel, "Current")
        let target = try XCTUnwrap(currentItem.target as? NSObject)
        target.perform(try XCTUnwrap(currentItem.action), with: currentItem)
        await self.waitForPresentation()
        XCTAssertEqual(previousTaps, 0)
        XCTAssertEqual(currentTaps, 1)
        owner.removeClose(from: current)
        XCTAssertNil(controller.navigationItem.rightBarButtonItems)
        XCTAssertTrue(controller.navigationController === navigation)
    }

    func testUIKitContentAppearsWhenOwnerIsPreparedAfterMounting() async throws {
        let owner = NativePaywallUIKitOwner()
        let appeared = expectation(description: "Prepared UIKit paywall content appears")
        let host = UIHostingController(rootView: NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {}, content: { Text("Configured Close") }
        ).onAppear { appeared.fulfill() }
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .uiKit(owner)))
        let navigation = UINavigationController(rootViewController: host)
        let window = self.host(navigation)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertNil(host.navigationItem.rightBarButtonItem)
        owner.prepare(controller: host)
        await fulfillment(of: [appeared], timeout: 2)
        await self.waitForPresentation()
        XCTAssertEqual(host.navigationItem.rightBarButtonItem?.accessibilityIdentifier,
                       NativePaywallUIKitOwner.closeIdentifier)
    }

    func testWorkflowBackSuppressesAndRestoresCallerSupplementFlag() async throws {
        for supplementsBackButton in [false, true] {
            let controller = UIViewController()
            let navigation = UINavigationController(rootViewController: UIViewController())
            navigation.pushViewController(controller, animated: false)
            let caller = UIBarButtonItem(title: "Caller", primaryAction: UIAction { _ in })
            controller.navigationItem.leftBarButtonItems = [caller]
            controller.navigationItem.leftItemsSupplementBackButton = supplementsBackButton
            let owner = NativePaywallUIKitOwner()
            owner.prepare(controller: controller)
            var backs = 0
            let back = NativePaywallCloseCoordinator.CloseAction(
                id: UUID(), label: "Back", perform: { backs += 1 }, role: .back
            )
            for _ in 0..<2 {
                owner.install([back])
                XCTAssertFalse(controller.navigationItem.leftItemsSupplementBackButton)
                XCTAssertEqual(controller.navigationItem.leftBarButtonItems?.count, 2)
                XCTAssertTrue(controller.navigationItem.leftBarButtonItems?.first === caller)
            }
            let item = try XCTUnwrap(controller.navigationItem.leftBarButtonItems?.last)
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
            await self.waitForPresentation()
            XCTAssertEqual(backs, 1)
            owner.install(.init(id: UUID(), label: "Close", perform: {}))
            XCTAssertEqual(controller.navigationItem.leftItemsSupplementBackButton, supplementsBackButton)
            XCTAssertTrue(controller.navigationItem.leftBarButtonItem === caller)
            owner.removeClose()
            XCTAssertEqual(controller.navigationItem.leftItemsSupplementBackButton, supplementsBackButton)
            XCTAssertTrue(controller.navigationController === navigation)
        }
    }

    func testRemovingNativeBackRestoresSystemBackWithoutChangingCallerItems() {
        let controller = UIViewController()
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.pushViewController(controller, animated: false)
        let owner = NativePaywallUIKitOwner()
        owner.prepare(controller: controller)
        owner.install([.init(id: UUID(), label: "Back", perform: {}, role: .back)])
        XCTAssertNotNil(controller.navigationItem.leftBarButtonItem)
        owner.install([])
        XCTAssertNil(controller.navigationItem.leftBarButtonItems)
        XCTAssertFalse(controller.navigationItem.hidesBackButton)
        let caller = UIBarButtonItem(title: "Caller", primaryAction: UIAction { _ in })
        controller.navigationItem.leftBarButtonItems = [caller]
        owner.install([.init(id: UUID(), label: "Back", perform: {}, role: .back)])
        owner.removeClose()
        XCTAssertEqual(controller.navigationItem.leftBarButtonItems?.count, 1)
        XCTAssertTrue(controller.navigationItem.leftBarButtonItem === caller)
        controller.navigationItem.leftBarButtonItems = []
        owner.install(.init(id: UUID(), label: "Close", perform: {}))
        owner.removeClose()
        XCTAssertNotNil(controller.navigationItem.leftBarButtonItems, "Preserve the caller's explicit empty array")
    }

    func testEmbeddedControllerKeepsConfiguredCloseWithAndWithoutParentNavigation() async throws {
        for hasNavigation in [false, true] {
            let owner = NativePaywallUIKitOwner()
            let child = UIHostingController(rootView: AnyView(Color.clear))
            let parent = UIViewController()
            let help = UIBarButtonItem(title: "Help", primaryAction: UIAction { _ in })
            parent.navigationItem.rightBarButtonItem = help
            parent.addChild(child)
            parent.view.addSubview(child.view)
            child.view.frame = parent.view.bounds
            child.didMove(toParent: parent)
            let navigation = UINavigationController(rootViewController: UIViewController())
            if hasNavigation { navigation.pushViewController(parent, animated: false) }
            owner.prepare(controller: child)
            var fallbackAppearances = 0
            child.rootView = AnyView(
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Close", action: {},
                    content: { Button("Configured Close") {}.onAppear { fallbackAppearances += 1 } }
                )
                .modifier(NativePaywallNavigationModifier(requested: true))
                .environment(\.nativePaywallNavigationContext, try XCTUnwrap(owner.context))
            )
            let window = self.host(hasNavigation ? navigation : parent)
            defer { self.close(window) }
            await self.waitForPresentation()
            XCTAssertEqual(fallbackAppearances, 1, "Embedded controls need the configured fallback")
            XCTAssertEqual(self.navigationCount(in: child), 0, "Embedding must not add navigation")
            XCTAssertNil(child.navigationItem.rightBarButtonItem)
            XCTAssertTrue(parent.navigationItem.rightBarButtonItem === help)
        }
    }

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
        XCTAssertNil(controller.navigationItem.leftBarButtonItems)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === help)
        XCTAssertTrue(controller.navigationController === navigation)
    }

    func testUIKitNativeActionErrorsAreLogged() async throws {
        let controller = UIViewController()
        let owner = NativePaywallUIKitOwner()
        owner.prepare(controller: controller)
        let error = NSError(domain: "NativePaywallCloseButtonTests", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Navigation failed"])
        owner.install([
            .init(id: UUID(), label: "Back", perform: { throw error }, role: .back),
            .init(id: UUID(), label: "Close", perform: { throw error })
        ])
        let back = try XCTUnwrap(controller.navigationItem.leftBarButtonItem)
        let close = try XCTUnwrap(controller.navigationItem.rightBarButtonItem)
        for item in [back, close] {
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
        }
        await self.waitForPresentation()
        self.logger.verifyMessageWasLogged(
            "Native paywall navigation action failed: Navigation failed", level: .error, expectedCount: 2
        )
    }

    func testUIKitOwnerDisablesActionsAndRejectsQueuedTaps() async throws {
        let controller = UIViewController()
        let owner = NativePaywallUIKitOwner()
        owner.prepare(controller: controller)
        var backCount = 0
        var closeCount = 0
        let actions: [NativePaywallCloseCoordinator.CloseAction] = [
            .init(id: UUID(), label: "Back", perform: { backCount += 1 }, role: .back),
            .init(id: UUID(), label: "Close", perform: { closeCount += 1 })
        ]
        owner.install(actions)
        for item in [controller.navigationItem.leftBarButtonItem, controller.navigationItem.rightBarButtonItem] {
            let item = try XCTUnwrap(item)
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
        }
        owner.install(actions.map { action in
            var action = action
            action.isEnabled = false
            return action
        })
        XCTAssertFalse(try XCTUnwrap(controller.navigationItem.leftBarButtonItem).isEnabled)
        XCTAssertFalse(try XCTUnwrap(controller.navigationItem.rightBarButtonItem).isEnabled)
        await self.waitForPresentation()
        XCTAssertEqual(backCount, 0)
        XCTAssertEqual(closeCount, 0)
        owner.install(actions)
        for item in [controller.navigationItem.leftBarButtonItem, controller.navigationItem.rightBarButtonItem] {
            let item = try XCTUnwrap(item)
            XCTAssertTrue(item.isEnabled)
            let target = try XCTUnwrap(item.target as? NSObject)
            target.perform(try XCTUnwrap(item.action), with: item)
        }
        await self.waitForPresentation()
        XCTAssertEqual(backCount, 1)
        XCTAssertEqual(closeCount, 1)
    }

    func testSourceDisabledAndWorkflowStatesReachUIKitControls() async throws {
        for workflowState in [false, true] {
            let state = NativeInteractionTestState()
            let owner = NativePaywallUIKitOwner()
            let host = UIHostingController(rootView:
                NativeInteractionTestView(state: state, workflowState: workflowState)
                    .modifier(NativePaywallCloseHost(uiKitOwner: owner))
            )
            let navigation = UINavigationController(rootViewController: host)
            owner.prepare(controller: host)
            let window = self.host(navigation)
            defer { self.close(window) }
            await self.waitForPresentation()
            XCTAssertTrue(try XCTUnwrap(host.navigationItem.rightBarButtonItem).isEnabled)
            state.blocked = true
            await self.waitForPresentation()
            XCTAssertFalse(try XCTUnwrap(host.navigationItem.rightBarButtonItem).isEnabled)
            state.blocked = false
            await self.waitForPresentation()
            XCTAssertTrue(try XCTUnwrap(host.navigationItem.rightBarButtonItem).isEnabled)
        }
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

}

@available(iOS 15.0, *)
@MainActor
private final class NativeInteractionTestState: ObservableObject {
    @Published var blocked = false
}

@available(iOS 15.0, *)
private struct NativeInteractionTestView: View {
    @ObservedObject var state: NativeInteractionTestState
    let workflowState: Bool

    var body: some View {
        NativePaywallCloseButton(enabled: true, accessibilityLabel: "Close", action: {},
                                 content: { Text("Configured Close") })
            .disabled(!self.workflowState && self.state.blocked)
            .environment(\.nativePaywallInteractionEnabled, !self.workflowState || !self.state.blocked)
    }
}

#endif
