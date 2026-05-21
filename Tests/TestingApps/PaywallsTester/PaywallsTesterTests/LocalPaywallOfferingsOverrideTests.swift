//
//  LocalPaywallOfferingsOverrideTests.swift
//  PaywallsTesterTests
//
//  Created by RevenueCat on 5/21/26.
//

@testable import PaywallsTester
import XCTest

final class LocalPaywallOfferingsOverrideTests: XCTestCase {

    func testBuildsOfferingsPayloadFromPaywallComponentsJSON() throws {
        let settings = LocalPaywallOfferingsOverrideSettings(
            paywallComponentsJSON: Self.paywallComponentsJSON,
            productIdentifiersByPackageIdentifier: [
                "$rc_monthly": "monthly_from_editor"
            ],
            uiConfigJSON: Self.uiConfigJSON
        )

        let payload = try LocalPaywallOfferingsResponseFactory.makeOfferingsResponseJSONObject(settings: settings)

        XCTAssertEqual(payload["current_offering_id"] as? String, "local_editor_offering")

        let offerings = try XCTUnwrap(payload["offerings"] as? [[String: Any]])
        let offering = try XCTUnwrap(offerings.first)
        XCTAssertEqual(offering["identifier"] as? String, "local_editor_offering")
        XCTAssertEqual(offering["description"] as? String, "Local Paywalls Tester override")

        let packages = try XCTUnwrap(offering["packages"] as? [[String: String]])
        XCTAssertEqual(packages, [
            [
                "identifier": "$rc_monthly",
                "platform_product_identifier": "monthly_from_editor"
            ]
        ])

        let paywallComponents = try XCTUnwrap(offering["paywall_components"] as? [String: Any])
        XCTAssertEqual(paywallComponents["template_name"] as? String, "componentsTEST")

        let uiConfig = try XCTUnwrap(payload["ui_config"] as? [String: Any])
        let customVariables = try XCTUnwrap(uiConfig["custom_variables"] as? [String: Any])
        XCTAssertNotNil(customVariables["user_name"])
    }

    func testUsesAllMappingsWhenPaywallComponentsDoNotReferencePackages() throws {
        let settings = LocalPaywallOfferingsOverrideSettings(
            paywallComponentsJSON: Self.paywallComponentsWithoutPackagesJSON,
            productIdentifiersByPackageIdentifier: [
                "$rc_annual": "annual_from_editor",
                "$rc_monthly": "monthly_from_editor"
            ],
            uiConfigJSON: ""
        )

        let payload = try LocalPaywallOfferingsResponseFactory.makeOfferingsResponseJSONObject(settings: settings)
        let offerings = try XCTUnwrap(payload["offerings"] as? [[String: Any]])
        let offering = try XCTUnwrap(offerings.first)
        let packages = try XCTUnwrap(offering["packages"] as? [[String: String]])

        XCTAssertEqual(packages, [
            [
                "identifier": "$rc_annual",
                "platform_product_identifier": "annual_from_editor"
            ],
            [
                "identifier": "$rc_monthly",
                "platform_product_identifier": "monthly_from_editor"
            ]
        ])
    }

    func testEmptyPaywallComponentsJSONDisablesOverride() {
        let settings = LocalPaywallOfferingsOverrideSettings(
            paywallComponentsJSON: "   \n",
            productIdentifiersByPackageIdentifier: [
                "$rc_monthly": "monthly_from_editor"
            ],
            uiConfigJSON: Self.uiConfigJSON
        )

        XCTAssertFalse(settings.isActive)
        XCTAssertThrowsError(
            try LocalPaywallOfferingsResponseFactory.makeOfferingsResponseData(settings: settings)
        )
    }

    private static let paywallComponentsJSON = """
    {
      "offering_id": "local_editor_offering",
      "default_locale": "en_US",
      "revision": 3,
      "template_name": "componentsTEST",
      "asset_base_url": "https://assets.pawwalls.com",
      "components_localizations": {},
      "components_config": {
        "base": {
          "background": {
            "type": "color",
            "value": {
              "light": {
                "type": "hex",
                "value": "#220000ff"
              }
            }
          },
          "stack": {
            "type": "stack",
            "components": [
              {
                "type": "package",
                "package_id": "$rc_monthly"
              }
            ],
            "margin": {},
            "padding": {},
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fill"
              }
            },
            "dimension": {
              "type": "vertical",
              "alignment": "center",
              "distribution": "center"
            },
            "spacing": 16
          }
        }
      }
    }
    """

    private static let paywallComponentsWithoutPackagesJSON = """
    {
      "default_locale": "en_US",
      "revision": 3,
      "template_name": "componentsTEST",
      "asset_base_url": "https://assets.pawwalls.com",
      "components_localizations": {},
      "components_config": {
        "base": {
          "background": {
            "type": "color",
            "value": {
              "light": {
                "type": "hex",
                "value": "#220000ff"
              }
            }
          },
          "stack": {
            "type": "stack",
            "components": [],
            "margin": {},
            "padding": {},
            "size": {
              "width": {
                "type": "fill"
              },
              "height": {
                "type": "fill"
              }
            },
            "dimension": {
              "type": "vertical",
              "alignment": "center",
              "distribution": "center"
            },
            "spacing": 16
          }
        }
      }
    }
    """

    private static let uiConfigJSON = """
    {
      "app": {
        "colors": {},
        "fonts": {}
      },
      "localizations": {
        "en_US": {}
      },
      "custom_variables": {
        "user_name": {
          "default_value": "anon",
          "type": "string"
        }
      },
      "variable_config": {
        "function_compatibility_map": {},
        "variable_compatibility_map": {}
      }
    }
    """

}
