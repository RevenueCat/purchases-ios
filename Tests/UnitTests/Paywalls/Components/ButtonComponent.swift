import Nimble
@testable import RevenueCat
import XCTest

#if PAYWALL_COMPONENTS

class ButtonComponentCodableTests: TestCase {

    let jsonStringDefaultStack = """
    {
        "type": "stack",
        "dimension": {
            "type": "vertical",
            "alignment": "center"
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

    func testRestorePurchasesDecoding() throws {
        let jsonString = """
        {
            "type": "button",
            "action": {
                "type": "restore_purchases"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedButton = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: jsonData)

        let buttonComponent = PaywallComponent.ButtonComponent(
            action: .restorePurchases,
            stack: .init(components: [])
        )

        XCTAssertEqual(decodedButton, buttonComponent)
    }

    func testNavigateBackDecoding() throws {
        let jsonString = """
        {
            "type": "button",
            "action": {
                "type": "navigate_back"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedButton = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: jsonData)

        let buttonComponent = PaywallComponent.ButtonComponent(
            action: .navigateBack,
            stack: .init(components: [])
        )

        XCTAssertEqual(decodedButton, buttonComponent)
    }

    func testNavigateToCustomerCenterDecoding() throws {
        let jsonString = """
        {
            "type": "button",
            "action": {
                "type": "navigate_to",
                "destination": "customer_center"
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedButton = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: jsonData)

        let buttonComponent = PaywallComponent.ButtonComponent(
            action: .navigateTo(destination: .customerCenter),
            stack: .init(components: [])
        )

        XCTAssertEqual(decodedButton, buttonComponent)
    }

    func testNavigateToTermsDecoding() throws {
        let jsonString = """
        {
            "type": "button",
            "action": {
                "type": "navigate_to",
                "destination": "terms",
                "url": {
                    "url_lid": "re45",
                    "method": "in_app_browser"
                }
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedButton = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: jsonData)

        let buttonComponent = PaywallComponent.ButtonComponent(
            action: .navigateTo(
                destination: .terms(urlLid: "re45",
                                    method: .inAppBrowser)
            ),
            stack: .init(components: [])
        )

        XCTAssertEqual(decodedButton, buttonComponent)
    }

    func testNavigateToPrivacyPolicyDecoding() throws {
        let jsonString = """
        {
            "type": "button",
            "action": {
                "type": "navigate_to",
                "destination": "privacy_policy",
                "url": {
                    "url_lid": "re45",
                    "method": "external_browser"
                }
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedButton = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: jsonData)

        let buttonComponent = PaywallComponent.ButtonComponent(
            action: .navigateTo(
                destination: .privacyPolicy(urlLid: "re45",
                                            method: .externalBrowser)
            ),
            stack: .init(components: [])
        )

        XCTAssertEqual(decodedButton, buttonComponent)
    }

    func testNavigateToURLDecoding() throws {
        let jsonString = """
        {
            "type": "button",
            "action": {
                "type": "navigate_to",
                "destination": "url",
                "url": {
                    "url_lid": "re45",
                    "method": "deep_link"
                }
            },
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedButton = try JSONDecoder.default.decode(PaywallComponent.ButtonComponent.self, from: jsonData)

        let buttonComponent = PaywallComponent.ButtonComponent(
            action: .navigateTo(
                destination: .url(urlLid: "re45",
                                  method: .deepLink)
            ),
            stack: .init(components: [])
        )

        XCTAssertEqual(decodedButton, buttonComponent)
    }

}

#endif
