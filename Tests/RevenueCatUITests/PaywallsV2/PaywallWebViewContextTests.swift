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
        let monthly = Self.package(from: TestData.monthlyPackage)
        let annual = Self.package(from: TestData.annualPackage)
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
            store: .appStore,
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

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let actualPayload = try XCTUnwrap(
            context.payloadJSON(
                updatedAt: Date(timeIntervalSince1970: 1_787_000_000),
                encoder: encoder
            )
        )

        if #available(iOS 17, macOS 14, watchOS 10, *) {
            // compare actual JSON strings -> more stable floating point from these os versions
            // and onward. In practice this isn't truly necessary because of how we send the data
            // over the bridge and how it handles the javascript Number type. But, this assertion
            // is more explicit and easier for a human to reason about
            XCTAssertEqual(actualPayload, Self.expectedPayload)
        }

        let decoder = JSONDecoder()
        let actualResult = try decoder.decode(
            PaywallWebViewValue.self,
            from: Data(actualPayload.utf8)
        )
        let expectedResult = try decoder.decode(
            PaywallWebViewValue.self,
            from: Data(Self.expectedPayload.utf8)
        )

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testSubscriptionPeriodDeterminesAutoRenewalWhenProductTypeIsUnavailable() throws {
        let isAutoRenewing = try self.autoRenewingValue(
            productType: .nonConsumable,
            subscriptionPeriod: .init(value: 1, unit: .month)
        )

        XCTAssertTrue(isAutoRenewing)
    }

    func testNonRenewingSubscriptionIsNotAutoRenewing() throws {
        let isAutoRenewing = try self.autoRenewingValue(
            productType: .nonRenewableSubscription,
            subscriptionPeriod: nil
        )

        XCTAssertFalse(isAutoRenewing)
    }

    func testSnapshotUsesConfiguredTestStore() throws {
        let productValue = try self.productValue(
            productType: .nonConsumable,
            subscriptionPeriod: nil,
            store: .testStore
        )

        XCTAssertEqual(productValue["store"]?.objectValue?["store_type"]?.stringValue, "test_store")
    }

    private static let expectedPayload = """
    {
      "custom" : {
        "first_name" : "Alex",
        "is_premium" : true,
        "streak_days" : 12
      },
      "device_meta" : {
        "dark_mode" : true,
        "is_preview" : false,
        "locale" : "en_US",
        "updated_at" : 1787000000000
      },
      "inputs" : {

      },
      "offering" : {
        "display_name" : "Default",
        "identifier" : "default"
      },
      "package" : {
        "identifier" : "$rc_annual",
        "products" : [
          {
            "display_name" : "Annual",
            "identifier" : "com.revenuecat.product_3",
            "is_auto_renewing" : true,
            "is_family_shareable" : false,
            "is_subscription" : true,
            "period" : "P1Y",
            "price" : {
              "amount" : 53.99,
              "currency" : "USD"
            },
            "store" : {
              "country" : "USA",
              "store_type" : "app_store"
            }
          }
        ]
      },
      "packages" : [
        {
          "identifier" : "$rc_monthly",
          "products" : [
            {
              "display_name" : "Monthly",
              "identifier" : "com.revenuecat.product_2",
              "is_auto_renewing" : true,
              "is_family_shareable" : false,
              "is_subscription" : true,
              "period" : "P1M",
              "price" : {
                "amount" : 6.99,
                "currency" : "USD"
              },
              "store" : {
                "country" : "USA",
                "store_type" : "app_store"
              }
            }
          ]
        },
        {
          "identifier" : "$rc_annual",
          "products" : [
            {
              "display_name" : "Annual",
              "identifier" : "com.revenuecat.product_3",
              "is_auto_renewing" : true,
              "is_family_shareable" : false,
              "is_subscription" : true,
              "period" : "P1Y",
              "price" : {
                "amount" : 53.99,
                "currency" : "USD"
              },
              "store" : {
                "country" : "USA",
                "store_type" : "app_store"
              }
            }
          ]
        }
      ],
      "selected_package" : {
        "identifier" : "$rc_monthly",
        "products" : [
          {
            "display_name" : "Monthly",
            "identifier" : "com.revenuecat.product_2",
            "is_auto_renewing" : true,
            "is_family_shareable" : false,
            "is_subscription" : true,
            "period" : "P1M",
            "price" : {
              "amount" : 6.99,
              "currency" : "USD"
            },
            "store" : {
              "country" : "USA",
              "store_type" : "app_store"
            }
          }
        ]
      },
      "workflow" : {
        "screen_type" : [
          "paywall"
        ],
        "step_id" : "step_paywall",
        "step_type" : "screen",
        "workflow_id" : "wf_123"
      }
    }
    """

    private static func package(from package: Package) -> Package {
        return .init(
            identifier: package.identifier,
            packageType: package.packageType,
            storeProduct: package.storeProduct,
            offeringIdentifier: package.offeringIdentifier,
            webCheckoutUrl: package.webCheckoutUrl
        )
    }

    private func autoRenewingValue(
        productType: StoreProduct.ProductType,
        subscriptionPeriod: SubscriptionPeriod?
    ) throws -> Bool {
        let productValue = try self.productValue(
            productType: productType,
            subscriptionPeriod: subscriptionPeriod
        )

        return try XCTUnwrap(productValue["is_auto_renewing"]?.boolValue)
    }

    private func productValue(
        productType: StoreProduct.ProductType,
        subscriptionPeriod: SubscriptionPeriod?,
        store: Store = .appStore
    ) throws -> [String: PaywallWebViewValue] {
        let product = TestStoreProduct(
            localizedTitle: "Test",
            price: 1.99,
            currencyCode: "USD",
            localizedPriceString: "$1.99",
            productIdentifier: "com.revenuecat.test",
            productType: productType,
            localizedDescription: "Test product",
            subscriptionPeriod: subscriptionPeriod,
            locale: Locale(identifier: "en_US")
        )
        let package = Package(
            identifier: "$rc_custom",
            packageType: .custom,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "default",
            webCheckoutUrl: nil
        )
        let offering = Offering(
            identifier: "default",
            serverDescription: "Default",
            availablePackages: [package],
            webCheckoutUrl: nil
        )
        let context = PaywallWebViewStaticContext(
            offering: offering,
            packages: [package],
            workflow: nil,
            store: store,
            storefrontCountryCode: "USA"
        ).snapshot(
            package: package,
            selectedPackageID: nil,
            customVariables: [:],
            locale: Locale(identifier: "en_US"),
            isDarkMode: false
        )
        return try XCTUnwrap(
            context.packages.arrayValue?.first?
                .objectValue?["products"]?.arrayValue?.first?
                .objectValue
        )
    }

}

#endif
