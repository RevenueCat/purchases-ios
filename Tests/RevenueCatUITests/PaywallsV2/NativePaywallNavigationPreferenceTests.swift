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
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class NativePaywallNavigationPreferenceTests: TestCase {

    func testCoordinatorRefreshesActionWithoutChangingRegistrationMetadata() async throws {
        let coordinator = NativePaywallCloseCoordinator()
        let id = UUID()
        var performed = 0
        coordinator.register(id: id, label: "Close", action: { performed = 1 })
        let installed = try XCTUnwrap(coordinator.action(for: .close))
        coordinator.register(id: id, label: "Close", action: { performed = 2 })
        try await installed.perform()
        XCTAssertEqual(performed, 2, "Already installed UIKit and SwiftUI actions must use the current callback")
        XCTAssertEqual(coordinator.actions.count, 1)
        coordinator.unregister(id: id)
        performed = 0
        try await installed.perform()
        XCTAssertEqual(performed, 0, "Removed actions must not retain their callback")
    }

    func testCoordinatorRejectsDisabledAndInactiveActions() async throws {
        let coordinator = NativePaywallCloseCoordinator()
        let id = UUID()
        var count = 0
        coordinator.register(id: id, label: "Close", isEnabled: false, action: { count += 1 })
        let installed = try XCTUnwrap(coordinator.actions.first)
        try await coordinator.performAction(id: id)
        try await installed.perform()
        XCTAssertEqual(count, 0)
        XCTAssertEqual(coordinator.actions.count, 1, "Disabled controls remain registered and visible")
        coordinator.register(id: id, label: "Close", isEnabled: true, action: { count += 1 })
        try await coordinator.performAction(id: id)
        XCTAssertEqual(count, 1)
        coordinator.activatePage(UUID())
        try await coordinator.performAction(id: id)
        try await installed.perform()
        XCTAssertEqual(count, 1, "A queued tap must not invoke an outgoing page's action")
        coordinator.activatePage(nil)
        coordinator.register(id: id, label: "Close", isEnabled: false, action: { count += 1 })
        try await installed.perform()
        XCTAssertEqual(count, 1, "Held actions must use the current disabled state")
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

    func testOnlyCurrentPageCanSupplyActionsEvenAfterLateRegistration() {
        let coordinator = NativePaywallCloseCoordinator()
        let blankPage = UUID()
        let backOnlyPage = UUID()
        let closePage = UUID()
        let backID = UUID()
        let closeID = UUID()
        coordinator.activatePage(closePage)
        coordinator.register(id: closeID, label: "Close", isWorkflowClose: true, pageID: closePage, action: {})
        XCTAssertEqual(coordinator.action(for: .close)?.id, closeID)

        coordinator.activatePage(backOnlyPage)
        coordinator.register(id: backID, label: "Back", role: .back, pageID: backOnlyPage, action: {})
        XCTAssertEqual(coordinator.action(for: .back)?.id, backID)
        XCTAssertNil(coordinator.action(for: .close))
        // An outgoing subtree may finish registering after the incoming page becomes active.
        coordinator.register(id: UUID(), label: "Late Close", pageID: closePage, action: {})
        XCTAssertNil(coordinator.action(for: .close))

        coordinator.activatePage(blankPage)
        XCTAssertTrue(coordinator.actions.isEmpty)
        coordinator.activatePage(closePage)
        XCTAssertEqual(coordinator.action(for: .close)?.id, closeID)
        XCTAssertNil(coordinator.action(for: .back))
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

    func testDecodedNativePreferenceOverrideRequestsPreflightForBothActions() throws {
        for actionType in ["navigate_back", "close_workflow"] {
            let fixture = try self.nativeOverrideFixture(actionType: actionType, nativeOverride: true)
            XCTAssertTrue(self.requestsNativeNavigation(fixture))
        }
    }

    func testPreflightFindsNativeButtonsInNestedBadgesAndBadgeOverrides() throws {
        for action in ["navigate_back", "close_workflow"] {
            let fixture = try self.nativeOverrideFixture(actionType: action, nativeBase: true)
            let buttonStack = fixture.paywallComponents.data.componentsConfig.base.stack
            let badge = PaywallComponent.Badge(
                style: .overlaid, alignment: .top,
                stack: .init(components: [.stack(.init(components: [.stack(buttonStack)]))])
            )
            for conditional in [false, true] {
                let stack = PaywallComponent.StackComponent(
                    components: [], badge: conditional ? nil : badge,
                    overrides: conditional ? [.init(conditions: [.selected], properties: .init(badge: badge))] : nil
                )
                XCTAssertTrue(self.config(stack: stack).requestsNativeClose,
                              "Must discover \(action) in \(conditional ? "conditional" : "base") badge content")
            }
        }
    }

    func testPreflightSearchesButtonContentButExcludesItsSheetDestination() throws {
        for action in ["navigate_back", "close_workflow"] {
            let fixture = try self.nativeOverrideFixture(actionType: action, nativeBase: true)
            let buttonStack = fixture.paywallComponents.data.componentsConfig.base.stack
            let sheet = PaywallComponent.ButtonComponent.Sheet(
                id: "separate-sheet", name: "Separate sheet", stack: buttonStack,
                backgroundBlur: false, size: .init(width: .fill, height: .fit(nil))
            )
            for nativeInContent in [false, true] {
                let button = PaywallComponent.button(.init(
                    action: .navigateTo(destination: .sheet(sheet: sheet)),
                    stack: nativeInContent ? buttonStack : .init(components: [])
                ))
                let config = self.config(stack: .init(components: [.stack(.init(components: [button]))]))
                XCTAssertEqual(config.requestsNativeClose, nativeInContent,
                               "The sheet's \(action) must not request navigation for its parent")
            }
        }
    }

    func testPreflightFindsNativeButtonsThroughEveryContainerAtMultipleDepths() throws {
        for action in ["navigate_back", "close_workflow"] {
            let fixture = try self.nativeOverrideFixture(actionType: action, nativeBase: true)
            let buttonStack = fixture.paywallComponents.data.componentsConfig.base.stack
            var nested = PaywallComponent.stack(buttonStack)
            for wrap in Self.containerWrappers {
                let component = wrap(buttonStack)
                XCTAssertTrue(self.config(stack: .init(components: [component])).requestsNativeClose)
                nested = wrap(.init(components: [nested]))
            }
            XCTAssertTrue(self.config(stack: .init(components: [nested])).requestsNativeClose,
                          "Mixed nested containers must still discover \(action)")
        }
    }

    func testDecodedWindowRulesCanRevealNativeButtonAndItsAncestorForPreflight() throws {
        for actionType in ["navigate_back", "close_workflow"] {
            let fixture = try self.nativeOverrideFixture(
                actionType: actionType, nativeBase: true, hiddenAncestor: true, hiddenButton: true,
                revealAncestor: true, revealButton: true
            )
            XCTAssertTrue(self.requestsNativeNavigation(fixture))
            let permanentlyHiddenAncestor = try self.nativeOverrideFixture(
                actionType: actionType, nativeBase: true, hiddenAncestor: true
            )
            XCTAssertFalse(self.requestsNativeNavigation(permanentlyHiddenAncestor))
            for revealAncestor in [false, true] {
                let permanentlyHidden = try self.nativeOverrideFixture(
                    actionType: actionType, nativeBase: true, hiddenAncestor: true, hiddenButton: true,
                    revealAncestor: revealAncestor, revealButton: false
                )
                XCTAssertFalse(self.requestsNativeNavigation(permanentlyHidden))
            }
        }
    }

    func testPreflightDiscardsWindowNativeRulesWhenAnotherComponentHasUnsupportedCondition() throws {
        let fixture = try self.nativeOverrideFixture(
            actionType: "navigate_back", nativeOverride: true, unsupportedSibling: true
        )
        XCTAssertFalse(self.requestsNativeNavigation(fixture))
        let hidden = try self.nativeOverrideFixture(
            actionType: "close_workflow", nativeBase: true, hiddenAncestor: true, hiddenButton: true,
            revealAncestor: true, revealButton: true, unsupportedSibling: true
        )
        XCTAssertFalse(self.requestsNativeNavigation(hidden))
    }

    private func config(stack: PaywallComponent.StackComponent) -> PaywallComponentsData.PaywallComponentsConfig {
        .init(stack: stack, stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF"))))
    }

    private static var containerWrappers: [(PaywallComponent.StackComponent) -> PaywallComponent] {
        [
            { .stack($0) },
            { .button(.init(action: .restorePurchases, stack: $0)) },
            { .package(.init(packageID: "$rc_monthly", isSelectedByDefault: true,
                             applePromoOfferProductCode: nil, stack: $0)) },
            { .purchaseButton(.init(stack: $0, action: nil, method: nil, name: nil)) },
            { .stickyFooter(.init(stack: $0)) },
            { .tabs(.init(control: .init(type: .buttons, stack: $0), tabs: [])) },
            { .tabs(.init(control: .init(type: .buttons, stack: .init(components: [])),
                          tabs: [.init(id: "tab", stack: $0)])) },
            { .tabControlButton(.init(tabId: "tab", stack: $0)) },
            { .carousel(.init(pages: [.init(components: []), $0])) },
            { .countdown(.init(style: .date(.distantFuture), countFrom: .hours, countdownStack: $0)) },
            { .countdown(.init(style: .date(.distantFuture), countFrom: .hours,
                               countdownStack: .init(components: []), endStack: $0)) },
            { .countdown(.init(style: .date(.distantFuture), countFrom: .hours,
                               countdownStack: .init(components: []), fallback: $0)) }
        ]
    }

    private func requestsNativeNavigation(_ fixture: PaywallPreviewRenderer.Fixture) -> Bool {
        fixture.paywallComponents.data.componentsConfig.base.requestsNativeClose
    }

    private func nativeOverrideFixture(
        actionType: String,
        nativeBase: Bool = false,
        nativeOverride: Bool? = nil,
        hiddenAncestor: Bool = false,
        hiddenButton: Bool = false,
        revealAncestor: Bool = false,
        revealButton: Bool = false,
        unsupportedSibling: Bool = false
    ) throws -> PaywallPreviewRenderer.Fixture {
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(PaywallPreviewRenderer.sampleJSON.utf8)
        ) as? [String: Any])
        var configs = try XCTUnwrap(payload["components_config"] as? [String: Any])
        var base = try XCTUnwrap(configs["base"] as? [String: Any])
        var stack = try XCTUnwrap(base["stack"] as? [String: Any])
        let labelStack = stack
        let windowRule: [[String: Any]] = [["type": "window_width_condition", "operator": ">=", "value": 700]]
        var button: [String: Any] = [
            "type": "button", "visible": !hiddenButton,
            "action": ["type": actionType, "use_native_if_possible": nativeBase], "stack": labelStack
        ]
        var buttonProperties: [String: Any] = [:]
        if revealButton { buttonProperties["visible"] = true }
        if let nativeOverride { buttonProperties["action"] = ["use_native_if_possible": nativeOverride] }
        if !buttonProperties.isEmpty {
            button["overrides"] = [["conditions": windowRule, "properties": buttonProperties]]
        }
        stack["visible"] = !hiddenAncestor
        if revealAncestor { stack["overrides"] = [["conditions": windowRule, "properties": ["visible": true]]] }
        var components = [button]
        if unsupportedSibling {
            var text = try XCTUnwrap((labelStack["components"] as? [[String: Any]])?.first)
            text["overrides"] = [["conditions": [["type": "future_condition"]], "properties": ["text_lid": "title"]]]
            components.append(text)
        }
        stack["components"] = components
        base["stack"] = stack
        configs["base"] = base
        payload["components_config"] = configs
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try PaywallPreviewRenderer.load(json: XCTUnwrap(String(data: data, encoding: .utf8)))
    }

}

#endif
