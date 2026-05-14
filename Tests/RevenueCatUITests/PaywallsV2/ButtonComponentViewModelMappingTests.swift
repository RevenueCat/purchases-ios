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

    // MARK: - Helpers

    private func decodeButton(actionType: String) throws -> PaywallComponent.ButtonComponent {
        let json = """
        {
            "type": "button",
            "id": "button_\(actionType)",
            "action": { "type": "\(actionType)" },
            "stack": {
                "type": "stack",
                "id": "button_stack_\(actionType)",
                "dimension": {"type": "vertical", "alignment": "center", "distribution": "start"},
                "size": {"width": {"type": "fill"}, "height": {"type": "fill"}},
                "padding": {"top": 0, "bottom": 0, "leading": 0, "trailing": 0},
                "margin": {"top": 0, "bottom": 0, "leading": 0, "trailing": 0},
                "components": []
            }
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
            stackViewModel: stackViewModel
        )
    }

}

#endif
