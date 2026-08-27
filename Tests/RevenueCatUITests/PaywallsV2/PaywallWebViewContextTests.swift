//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallWebViewContextTests: TestCase {

    func testSnapshotJSONMatchesExpectedPayload() throws {
        let monthly = Self.package(from: TestData.monthlyPackage, displayName: "Monthly")
        let annual = Self.package(from: TestData.annualPackage, displayName: "Annual")
        let offering = Offering(
            identifier: "default",
            serverDescription: "Default",
            availablePackages: [monthly, annual],
            webCheckoutUrl: nil
        )
        let staticContext = PaywallWebViewStaticContext(
            offering: offering,
            packages: [monthly, annual, annual],
            workflow: .init(
                id: "wf_123",
                stepID: "step_paywall",
                stepType: "screen",
                screenType: ["paywall"]
            ),
            isPreview: false,
            storefrontCountryCode: "USA"
        )

        let context = staticContext.snapshot(
            package: annual,
            selectedPackageID: monthly.identifier,
            customVariables: [
                "first_name": .string("Alex"),
                "streak_days": .number(12),
                "is_premium": .bool(true)
            ],
            locale: Locale(identifier: "en_US"),
            isDarkMode: true
        )
        let payload = context.payload(updatedAt: Date(timeIntervalSince1970: 1_787_000_000))

        let actualData = try JSONEncoder().encode(payload)
        let actualJSON = try JSONDecoder().decode(PaywallWebViewValue.self, from: actualData)
        let expectedJSON = try JSONDecoder().decode(
            PaywallWebViewValue.self,
            from: Data(Self.expectedPayload.utf8)
        )

        XCTAssertEqual(actualJSON, expectedJSON)
    }

    private static let expectedPayload = """
    {
      "custom": {
        "first_name": "Alex",
        "streak_days": 12,
        "is_premium": true
      },
      "offering": {
        "identifier": "default",
        "display_name": "Default"
      },
      "packages": [
        {
          "identifier": "$rc_monthly",
          "display_name": "Monthly",
          "products": [
            {
              "identifier": "com.revenuecat.product_2",
              "store": {
                "store_type": "app_store",
                "country": "USA"
              },
              "display_name": "Monthly",
              "is_subscription": true,
              "period": "P1M",
              "is_family_shareable": false,
              "is_auto_renewing": true,
              "price": {
                "amount": 6.99,
                "currency": "USD"
              }
            }
          ]
        },
        {
          "identifier": "$rc_annual",
          "display_name": "Annual",
          "products": [
            {
              "identifier": "com.revenuecat.product_3",
              "store": {
                "store_type": "app_store",
                "country": "USA"
              },
              "display_name": "Annual",
              "is_subscription": true,
              "period": "P1Y",
              "is_family_shareable": false,
              "is_auto_renewing": true,
              "price": {
                "amount": 53.99,
                "currency": "USD"
              }
            }
          ]
        }
      ],
      "package": {
        "identifier": "$rc_annual",
        "display_name": "Annual",
        "products": [
          {
            "identifier": "com.revenuecat.product_3",
            "store": {
              "store_type": "app_store",
              "country": "USA"
            },
            "display_name": "Annual",
            "is_subscription": true,
            "period": "P1Y",
            "is_family_shareable": false,
            "is_auto_renewing": true,
            "price": {
              "amount": 53.99,
              "currency": "USD"
            }
          }
        ]
      },
      "selected_package": {
        "identifier": "$rc_monthly",
        "display_name": "Monthly",
        "products": [
          {
            "identifier": "com.revenuecat.product_2",
            "store": {
              "store_type": "app_store",
              "country": "USA"
            },
            "display_name": "Monthly",
            "is_subscription": true,
            "period": "P1M",
            "is_family_shareable": false,
            "is_auto_renewing": true,
            "price": {
              "amount": 6.99,
              "currency": "USD"
            }
          }
        ]
      },
      "workflow": {
        "workflow_id": "wf_123",
        "step_id": "step_paywall",
        "step_type": "screen",
        "screen_type": ["paywall"]
      },
      "device_meta": {
        "is_preview": false,
        "locale": "en_US",
        "dark_mode": true,
        "updated_at": 1787000000000
      }
    }
    """

    private static func package(from package: Package, displayName: String) -> Package {
        return .init(
            identifier: package.identifier,
            displayName: displayName,
            packageType: package.packageType,
            storeProduct: package.storeProduct,
            offeringIdentifier: package.offeringIdentifier,
            webCheckoutUrl: package.webCheckoutUrl
        )
    }

}

#endif
