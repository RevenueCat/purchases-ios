import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class HeaderComponentTests: TestCase {

    private let defaultStackJSON = """
    {
        "type": "stack",
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

    func testDecodesHeaderComponentWithNonEmptyStack() throws {
        let json = """
        {
            "type": "header",
            "stack": {
                "type": "stack",
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
                "components": [
                    {
                        "type": "text",
                        "text_lid": "header_text",
                        "font_weight": "regular",
                        "color": {
                            "light": {
                                "type": "hex",
                                "value": "#000000"
                            }
                        },
                        "font_size": "body_m",
                        "horizontal_alignment": "center",
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
                        }
                    }
                ]
            }
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.HeaderComponent.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.stack.components).to(haveCount(1))
    }

    func testDecodesHeaderComponentWithEmptyStack() throws {
        let json = """
        {
            "type": "header",
            "stack": \(self.defaultStackJSON)
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.HeaderComponent.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.stack.components).to(beEmpty())
    }

    func testDecodesHeaderComponentIgnoringExtraFields() throws {
        let json = """
        {
            "type": "header",
            "id": "header_1",
            "name": "Header",
            "stack": \(self.defaultStackJSON)
        }
        """

        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.HeaderComponent.self,
            from: json.data(using: .utf8)!
        )

        expect(decoded.stack.components).to(beEmpty())
    }

    func testEncodesHeaderComponentType() throws {
        let component = PaywallComponent.HeaderComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fit)
            )
        )

        let data = try JSONEncoder.default.encode(component)
        let jsonObject = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(jsonObject["type"] as? String) == "header"
        expect(jsonObject["stack"]).toNot(beNil())
    }

}

#endif
