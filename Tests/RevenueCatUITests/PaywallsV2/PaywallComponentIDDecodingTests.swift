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
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallComponentIDDecodingTests: TestCase {

    func testTextComponentDecodesID() throws {
        let component = try Self.decodeComponent(
            """
            {
                "type": "text",
                "id": "text_1",
                "text_lid": "title",
                "font_weight": "regular",
                "color": { "light": { "type": "hex", "value": "#000000" } },
                "font_size": 16,
                "horizontal_alignment": "center",
                "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
                "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
            }
            """
        )

        guard case .text(let text) = component else {
            return XCTFail("Expected text component")
        }
        XCTAssertEqual(text.id, "text_1")
    }

    func testTabControlButtonComponentDecodesID() throws {
        let component = try Self.decodeComponent(
            """
            {
                "type": "tab_control_button",
                "id": "tab_control_button_1",
                "tab_id": "tab_1",
                "stack": \(Self.emptyStackJSON(id: "tab_control_button_stack"))
            }
            """
        )

        guard case .tabControlButton(let button) = component else {
            return XCTFail("Expected tab control button component")
        }
        XCTAssertEqual(button.id, "tab_control_button_1")
    }

    private static func decodeComponent(_ json: String) throws -> PaywallComponent {
        try JSONDecoder.default.decode(PaywallComponent.self, from: Data(json.utf8))
    }

    private static func emptyStackJSON(id: String) -> String {
        """
        {
            "type": "stack",
            "id": "\(id)",
            "dimension": {
                "type": "vertical",
                "alignment": "center",
                "distribution": "start"
            },
            "size": {
                "width": { "type": "fill" },
                "height": { "type": "fit" }
            },
            "padding": {
                "top": 0,
                "bottom": 0,
                "leading": 0,
                "trailing": 0
            },
            "margin": {
                "top": 0,
                "bottom": 0,
                "leading": 0,
                "trailing": 0
            },
            "components": []
        }
        """
    }

}

#endif
