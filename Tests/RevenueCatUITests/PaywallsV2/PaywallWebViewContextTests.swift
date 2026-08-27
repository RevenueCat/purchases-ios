//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallWebViewContextTests: TestCase {

    func testSnapshotContainsCompletePaywallContext() throws {
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

        let custom = try XCTUnwrap(payload["custom"]?.objectValue)
        XCTAssertEqual(custom["first_name"]?.stringValue, "Alex")
        XCTAssertEqual(custom["streak_days"]?.numberValue, 12)
        XCTAssertEqual(custom["is_premium"]?.boolValue, true)

        let offeringValue = try XCTUnwrap(payload["offering"]?.objectValue)
        XCTAssertEqual(offeringValue["identifier"]?.stringValue, "default")
        XCTAssertEqual(offeringValue["display_name"]?.stringValue, "Default")

        let packages = try XCTUnwrap(payload["packages"]?.arrayValue)
        XCTAssertEqual(packages.count, 2)

        let package = try XCTUnwrap(payload["package"]?.objectValue)
        XCTAssertEqual(package["identifier"]?.stringValue, annual.identifier)
        XCTAssertEqual(package["display_name"]?.stringValue, "Annual")

        let selectedPackage = try XCTUnwrap(payload["selected_package"]?.objectValue)
        XCTAssertEqual(selectedPackage["identifier"]?.stringValue, monthly.identifier)

        let products = try XCTUnwrap(package["products"]?.arrayValue)
        let product = try XCTUnwrap(products.first?.objectValue)
        XCTAssertEqual(product["identifier"]?.stringValue, annual.storeProduct.productIdentifier)
        XCTAssertEqual(product["display_name"]?.stringValue, "Annual")
        XCTAssertEqual(product["is_subscription"]?.boolValue, true)
        XCTAssertEqual(product["period"]?.stringValue, "P1Y")
        XCTAssertEqual(product["is_auto_renewing"]?.boolValue, true)

        let store = try XCTUnwrap(product["store"]?.objectValue)
        XCTAssertEqual(store["store_type"]?.stringValue, "app_store")
        XCTAssertEqual(store["country"]?.stringValue, "USA")

        let price = try XCTUnwrap(product["price"]?.objectValue)
        XCTAssertEqual(try XCTUnwrap(price["amount"]?.numberValue), 53.99, accuracy: 0.001)
        XCTAssertEqual(price["currency"]?.stringValue, "USD")

        let workflow = try XCTUnwrap(payload["workflow"]?.objectValue)
        XCTAssertEqual(workflow["workflow_id"]?.stringValue, "wf_123")
        XCTAssertEqual(workflow["step_id"]?.stringValue, "step_paywall")
        XCTAssertEqual(workflow["step_type"]?.stringValue, "screen")
        XCTAssertEqual(workflow["screen_type"]?.arrayValue?.first?.stringValue, "paywall")

        let deviceMeta = try XCTUnwrap(payload["device_meta"]?.objectValue)
        XCTAssertEqual(deviceMeta["is_preview"]?.boolValue, false)
        XCTAssertEqual(deviceMeta["locale"]?.stringValue, "en_US")
        XCTAssertEqual(deviceMeta["dark_mode"]?.boolValue, true)
        XCTAssertEqual(deviceMeta["updated_at"]?.numberValue, 1_787_000_000_000)
    }

    private static func package(from package: Package, displayName: String) -> Package {
        return .init(
            identifier: package.identifier,
            displayName: displayName,
            packageType: package.packageType,
            storeProduct: package.storeProduct,
            presentedOfferingContext: package.presentedOfferingContext,
            webCheckoutUrl: package.webCheckoutUrl
        )
    }

}

#endif
