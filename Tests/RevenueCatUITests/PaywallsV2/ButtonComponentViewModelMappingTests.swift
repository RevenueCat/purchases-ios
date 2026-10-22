//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentViewModelMappingTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ButtonComponentViewModelMappingTests: TestCase {

    // MARK: - visible

    func testDefaultVisibility_IsTrue() throws {
        let component = try self.decodeButton(actionType: "navigate_back")
        let viewModel = try self.makeViewModel(for: component)

        XCTAssertTrue(viewModel.visible(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:]
        ))
    }

    func testComponentVisible_False_ReturnsNotVisible() throws {
        let component = try self.decodeButton(actionType: "navigate_back", visible: false)
        let viewModel = try self.makeViewModel(for: component)

        XCTAssertFalse(viewModel.visible(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:]
        ))
    }

    func testSelectedOverrideVisible_False_HidesWhenSelected() throws {
        let component = try self.decodeButton(
            actionType: "navigate_back",
            overrideConditions: ["selected"],
            overrideVisible: false
        )
        let viewModel = try self.makeViewModel(for: component)

        XCTAssertFalse(viewModel.visible(
            state: .selected,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:]
        ))
    }

    func testSelectedOverrideVisible_False_StillVisibleWhenNotSelected() throws {
        let component = try self.decodeButton(
            actionType: "navigate_back",
            overrideConditions: ["selected"],
            overrideVisible: false
        )
        let viewModel = try self.makeViewModel(for: component)

        XCTAssertTrue(viewModel.visible(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:]
        ))
    }

    // MARK: - close_workflow → .closeWorkflow mapping

    func testCloseWorkflowDecodedComponentMapsToCloseWorkflowAction() throws {
        let component = try self.decodeButton(actionType: "close_workflow")

        let viewModel = try self.makeViewModel(for: component)

        XCTAssertEqual(viewModel.action.paywallComponentInteractionValue, "close_workflow")
    }

    func testNavigateBackDecodedComponentMapsToNavigateBackAction() throws {
        let component = try self.decodeButton(actionType: "navigate_back")

        let viewModel = try self.makeViewModel(for: component)

        // navigate_back without isCloseWorkflowAction must NOT map to closeWorkflow.
        XCTAssertEqual(viewModel.action.paywallComponentInteractionValue, "navigate_back")
    }

    func testDecodedNativePreferenceOverridesPreserveBothActionTypes() throws {
        let cases: [(Bool?, Bool)] = [(nil, true), (false, true), (true, false)]
        for actionType in ["navigate_back", "close_workflow"] {
            for (base, override) in cases {
                let component = try self.decodeButton(
                    actionType: actionType, overrideConditions: ["selected"],
                    nativePreference: base, overrideNativePreference: override
                )
                let viewModel = try self.makeViewModel(for: component)
                for selected in [false, true, false] {
                    let preference = viewModel.useNativeIfPossible(
                        state: selected ? .selected : .default, condition: .compact,
                        isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
                        selectedPackageId: nil, customVariables: [:]
                    )
                    let expected = selected ? override : (base ?? false)
                    XCTAssertEqual(preference, expected, "\(actionType), selected=\(selected)")
                    let expectedRole: NativePaywallCloseCoordinator.Role? = expected
                        ? (actionType == "navigate_back" ? .back : .close) : nil
                    XCTAssertEqual(viewModel.nativeNavigationRole(
                        dismissesPaywall: false, useNativeIfPossible: preference
                    ), expectedRole)
                    XCTAssertEqual(viewModel.action.paywallComponentInteractionValue, actionType)
                    XCTAssertEqual(component.isCloseWorkflowAction, actionType == "close_workflow")
                }
            }
        }
    }

    func testDecodedFalseNativeOverrideSurvivesPayloadRoundTrip() throws {
        for actionType in ["navigate_back", "close_workflow"] {
            let component = try self.decodeButton(
                actionType: actionType, overrideConditions: ["selected"],
                nativePreference: true, overrideNativePreference: false
            )
            let encoded = try JSONEncoder.default.encode(component)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            let overrides = try XCTUnwrap(json["overrides"] as? [[String: Any]])
            let properties = try XCTUnwrap(overrides.first?["properties"] as? [String: Any])
            let action = try XCTUnwrap(properties["action"] as? [String: Any])
            XCTAssertEqual(action["use_native_if_possible"] as? Bool, false)
            let roundTrip = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: encoded)
            XCTAssertEqual(roundTrip, component)
            let viewModel = try self.makeViewModel(for: roundTrip)
            XCTAssertFalse(viewModel.useNativeIfPossible(
                state: .selected, condition: .compact,
                isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
                selectedPackageId: nil, customVariables: [:]
            ))
            XCTAssertEqual(viewModel.action.paywallComponentInteractionValue, actionType)
        }
    }

    func testNativeNavigationRoleMatchesWorkflowAction() throws {
        let cases: [(PaywallComponent.ButtonComponent.Action, Bool, Bool, NativePaywallCloseCoordinator.Role?)] = [
            (.navigateBack, true, true, .close),
            (.navigateBack, false, true, nil),
            (.navigateBack, true, false, .back),
            (.restorePurchases, true, true, nil),
            (.workflowTrigger, true, true, nil),
            (.unknown, true, true, nil)
        ]
        for (action, enabled, dismisses, expected) in cases {
            let component = PaywallComponent.ButtonComponent(
                action: action, stack: .init(components: []), useNativeIfPossible: enabled
            )
            let viewModel = try self.makeViewModel(for: component)
            XCTAssertEqual(viewModel.nativeNavigationRole(dismissesPaywall: dismisses), expected)
        }
    }

    func testNativeCloseWorkflowStillClosesWhenBackIsAvailable() throws {
        let component = try self.decodeButton(actionType: "close_workflow")
        let encoded = try JSONEncoder.default.encode(component)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var action = try XCTUnwrap(json["action"] as? [String: Any])
        action["use_native_if_possible"] = true
        json["action"] = action
        let native = try JSONDecoder.default.decode(
            PaywallComponent.ButtonComponent.self, from: JSONSerialization.data(withJSONObject: json)
        )
        let viewModel = try self.makeViewModel(for: native)
        XCTAssertTrue(viewModel.nativeNavigationRole(dismissesPaywall: false) == .close)
    }

    // MARK: - Helpers

    private func decodeButton(
        actionType: String,
        visible: Bool? = nil,
        overrideConditions: [String]? = nil,
        overrideVisible: Bool? = nil,
        nativePreference: Bool? = nil,
        overrideNativePreference: Bool? = nil
    ) throws -> PaywallComponent.ButtonComponent {
        var visibleField = ""
        if let visible {
            visibleField = "\"visible\": \(visible),"
        }
        var overridesField = ""
        if let overrideConditions {
            let conditions = overrideConditions.map { "{\"type\": \"\($0)\"}" }.joined(separator: ",")
            var properties: [String] = []
            if let overrideVisible { properties.append("\"visible\": \(overrideVisible)") }
            if let overrideNativePreference {
                properties.append("\"action\": {\"type\": \"\(actionType)\", "
                                  + "\"use_native_if_possible\": \(overrideNativePreference)}")
            }
            overridesField = """
            ,"overrides": [{"conditions": [\(conditions)], "properties": {\(properties.joined(separator: ","))}}]
            """
        }
        let nativeField = nativePreference.map { ", \"use_native_if_possible\": \($0)" } ?? ""
        let json = """
        {
            "type": "button",
            \(visibleField)
            "action": { "type": "\(actionType)"\(nativeField) },
            "stack": {
                "type": "stack",
                "dimension": {"type": "vertical", "alignment": "center", "distribution": "start"},
                "size": {"width": {"type": "fill"}, "height": {"type": "fill"}},
                "padding": {"top": 0, "bottom": 0, "leading": 0, "trailing": 0},
                "margin": {"top": 0, "bottom": 0, "leading": 0, "trailing": 0},
                "components": []
            }
            \(overridesField)
        }
        """
        return try JSONDecoder.default.decode(
            PaywallComponent.ButtonComponent.self,
            from: json.data(using: .utf8)!
        )
    }

    private func makeViewModel(
        for component: PaywallComponent.ButtonComponent
    ) throws -> ButtonComponentViewModel {
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let stackViewModel = StackComponentViewModel(
            component: component.stack,
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: uiConfigProvider
        )
        return try ButtonComponentViewModel(
            component: component,
            localizationProvider: LocalizationProvider(locale: .current, localizedStrings: [:]),
            offering: .init(
                identifier: "test",
                serverDescription: "",
                metadata: [:],
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            stackViewModel: stackViewModel,
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif
