import Nimble
@testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class StackComponentTests: TestCase {

    func testStack() throws {
        let jsonStack = """
        {
            "type": "stack",
            "dimension": {
                "type": "vertical",
                "alignment": "center",
                "distribution": "start"
            },
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
            },
            "components": []
        }
        """

        _ = try JSONDecoder.default.decode(
            PaywallComponent.StackComponent.self,
            from: jsonStack.data(using: .utf8)!
        )
    }

    func testStackWithBadge() throws {
        let jsonStack = """
        {
            "type": "stack",
            "dimension": {
                "type": "vertical",
                "alignment": "center",
                "distribution": "start"
            },
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
            },
            "components": [],
            "badge": {
                "alignment": "top",
                "stack": {
                    "background_color": {
                        "light": {
                            "type": "hex",
                            "value": "#11D483FF"
                        }
                    },
                    "background": {
                        "type": "color",
                        "value": {
                            "light": {
                                "type": "hex",
                                "value": "#11D483FF"
                            }
                        }
                    },
                    "badge": null,
                    "border": null,
                    "components": [
                        {
                            "background_color": null,
                            "color": {
                                "light": {
                                    "type": "hex",
                                    "value": "#000000"
                                }
                            },
                            "font_name": null,
                            "font_size": 14,
                            "font_weight": "regular",
                            "horizontal_alignment": "center",
                            "id": "7x9oXp0T5U",
                            "margin": {
                                "bottom": 0,
                                "leading": 0,
                                "top": 0,
                                "trailing": 0
                            },
                            "name": "",
                            "padding": {
                                "bottom": 0,
                                "leading": 0,
                                "top": 0,
                                "trailing": 0
                            },
                            "size": {
                                "height": {
                                    "type": "fit",
                                    "value": null
                                },
                                "width": {
                                    "type": "fit",
                                    "value": null
                                }
                            },
                            "text_lid": "tYSI61kmt9",
                            "type": "text"
                        }
                    ],
                    "dimension": {
                        "alignment": "center",
                        "distribution": "center",
                        "type": "vertical"
                    },
                    "id": "WMKBhff2YS",
                    "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                    },
                    "name": "",
                    "padding": {
                        "bottom": 4,
                        "leading": 8,
                        "top": 4,
                        "trailing": 8
                    },
                    "shadow": null,
                    "shape": {
                        "corners": {
                            "bottom_leading": 0,
                            "bottom_trailing": 0,
                            "top_leading": 0,
                            "top_trailing": 0
                        },
                        "type": "pill"
                    },
                    "size": {
                        "height": {
                            "type": "fit",
                            "value": null
                        },
                        "width": {
                            "type": "fill",
                            "value": null
                        }
                    },
                    "spacing": 0,
                    "type": "stack"
                },
                "style": "overlay"
            }
        }
        """

        let stack = try JSONDecoder.default.decode(
            PaywallComponent.StackComponent.self,
            from: jsonStack.data(using: .utf8)!
        )

        expect(stack).notTo(beNil())
        expect(stack.badge).notTo(beNil())
        expect(stack.badge?.stack.components.count).to(equal(1))
    }

}

#endif
