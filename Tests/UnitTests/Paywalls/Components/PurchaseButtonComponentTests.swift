import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class PurchaseButtonComponentCodableTests: TestCase {

    let jsonStringDefaultStack = """
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

    func testDefaultDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: nil,
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testDecodingWithName() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "name": "my_purchase_button",
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        XCTAssertEqual(decodedPurchaseButton.name, "my_purchase_button")
    }

    func testDecodingWithNameAbsentIsNil() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        XCTAssertNil(decodedPurchaseButton.name)
    }

    func testMethodInAppCheckoutDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "in_app_checkout"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .inAppCheckout,
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testMethodWebCheckoutDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "web_checkout"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .webCheckout(.init(autoDismiss: nil, openMethod: nil)),
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testMethodWebCheckoutWithOptionsDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "web_checkout",
                "auto_dismiss": false,
                "open_method": "in_app_browser"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .webCheckout(.init(autoDismiss: false, openMethod: .inAppBrowser)),
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testMethodWebProductSelectionDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "web_product_selection"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .webProductSelection(.init(autoDismiss: nil, openMethod: nil)),
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testMethodWebProductSelectionWithOptionsDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "web_product_selection",
                "auto_dismiss": false,
                "open_method": "in_app_browser"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .webProductSelection(.init(autoDismiss: false, openMethod: .inAppBrowser)),
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testMethodCustomWebCheckoutDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "custom_web_checkout",
                "custom_url": {
                    "url_lid": "123"
                }
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .customWebCheckout(
                .init(
                    customUrl: .init(url: "123", packageParam: nil),
                    autoDismiss: nil,
                    openMethod: nil
                )
            ),
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    func testMethodCustomWebCheckoutWithOptionsDecoding() throws {
        let jsonString = """
        {
            "type": "purchase_button",
            "method": {
                "type": "custom_web_checkout",
                "custom_url": {
                    "url_lid": "123",
                    "package_param": "rc_package"
                },
                "auto_dismiss": false,
                "open_method": "in_app_browser"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPurchaseButton = try JSONDecoder.default.decode(PaywallComponent.PurchaseButtonComponent.self,
                                                                   from: jsonData)

        let purchaseButtonComponent = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            action: nil,
            method: .customWebCheckout(
                .init(
                    customUrl: .init(url: "123", packageParam: "rc_package"),
                    autoDismiss: false,
                    openMethod: .inAppBrowser
                )
            ),
            name: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

    // MARK: - Method.description

    func testMethodDescriptionInAppCheckout() {
        XCTAssertEqual(PaywallComponent.PurchaseButtonComponent.Method.inAppCheckout.description, "in_app_checkout")
    }

    func testMethodDescriptionWebCheckout() {
        XCTAssertEqual(
            PaywallComponent.PurchaseButtonComponent.Method.webCheckout(.init()).description,
            "web_checkout"
        )
    }

    func testMethodDescriptionWebProductSelection() {
        XCTAssertEqual(
            PaywallComponent.PurchaseButtonComponent.Method.webProductSelection(.init()).description,
            "web_product_selection"
        )
    }

    func testMethodDescriptionCustomWebCheckout() {
        XCTAssertEqual(
            PaywallComponent.PurchaseButtonComponent.Method.customWebCheckout(
                .init(customUrl: .init(url: "url", packageParam: nil))
            ).description,
            "custom_web_checkout"
        )
    }

    func testMethodDescriptionUnknown() {
        XCTAssertEqual(PaywallComponent.PurchaseButtonComponent.Method.unknown.description, "unknown")
    }

    // MARK: - ComponentInteractionType raw value

    func testPurchaseButtonInteractionTypeRawValue() {
        XCTAssertEqual(ComponentInteractionType.purchaseButton.rawValue, "purchase_button")
    }

}

#endif
