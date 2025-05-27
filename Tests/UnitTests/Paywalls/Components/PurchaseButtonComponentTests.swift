import Nimble
@testable import RevenueCat
import XCTest

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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
            method: nil
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
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
            method: .inAppCheckout
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
            method: .webCheckout(.init(autoDismiss: nil, openMethod: nil))
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
            method: .webCheckout(.init(autoDismiss: false, openMethod: .inAppBrowser))
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
            method: .webProductSelection(.init(autoDismiss: nil, openMethod: nil))
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
            method: .webProductSelection(.init(autoDismiss: false, openMethod: .inAppBrowser))
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
            )
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
            )
        )

        XCTAssertEqual(decodedPurchaseButton, purchaseButtonComponent)
    }

}

#endif
