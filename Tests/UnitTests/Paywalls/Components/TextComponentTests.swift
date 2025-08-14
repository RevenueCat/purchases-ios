import Nimble
@testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class TextComponentTests: TestCase {

    func testFontSizeWithString() throws {
        let jsonStack = """
        {
            "type": "text",
            "text_lid": "123",
            "font_weight": "regular",
            "color": { "light": { "type": "hex", "value": "#ffffff" } },
            "font_size": "body_m",
            "horizontal_alignment": "center",
            "size": {
                "width": { "type": "fill" },
                "height": { "type": "fill" }
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
            }
        }
        """

        let textComponent = try JSONDecoder.default.decode(
            PaywallComponent.TextComponent.self,
            from: jsonStack.data(using: .utf8)!
        )

        expect(textComponent.fontSize).to(equal(15))
    }

    func testFontSizeWithNummber() throws {
        let jsonStack = """
        {
            "type": "text",
            "text_lid": "123",
            "font_weight": "regular",
            "color": { "light": { "type": "hex", "value": "#ffffff" } },
            "font_size": 123,
            "horizontal_alignment": "center",
            "size": {
                "width": { "type": "fill" },
                "height": { "type": "fill" }
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
            }
        }
        """

        let textComponent = try JSONDecoder.default.decode(
            PaywallComponent.TextComponent.self,
            from: jsonStack.data(using: .utf8)!
        )

        expect(textComponent.fontSize).to(equal(123))
    }

}

#endif
