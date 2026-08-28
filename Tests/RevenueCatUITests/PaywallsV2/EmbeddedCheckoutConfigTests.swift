//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

final class EmbeddedCheckoutConfigTests: TestCase {

    func testResolvedWebBillingAPIKeyIgnoresEmptyAndPlaceholder() {
        XCTAssertNil(EmbeddedCheckoutConfig.resolvedWebBillingAPIKey(from: nil))
        XCTAssertNil(EmbeddedCheckoutConfig.resolvedWebBillingAPIKey(from: ""))
        XCTAssertNil(EmbeddedCheckoutConfig.resolvedWebBillingAPIKey(from: "  "))
        XCTAssertNil(EmbeddedCheckoutConfig.resolvedWebBillingAPIKey(from: "$(WEB_BILLING_API_KEY)"))
        XCTAssertEqual(
            EmbeddedCheckoutConfig.resolvedWebBillingAPIKey(from: " rcb_sb_test "),
            "rcb_sb_test"
        )
    }

    func testJSONIncludesConfigFields() throws {
        let config = EmbeddedCheckoutConfig(
            apiKey: "rcb_sb_test",
            appUserID: "user_1",
            offeringId: "default",
            packageId: "$rc_monthly"
        )
        let json = try XCTUnwrap(config.jsonObjectString())
        XCTAssertTrue(json.contains("rcb_sb_test"))
        XCTAssertTrue(json.contains("user_1"))
        XCTAssertTrue(json.contains("default"))
        XCTAssertTrue(json.contains("$rc_monthly"))
    }

    func testBundledResourcesExist() {
        XCTAssertTrue(
            EmbeddedCheckoutConfig.resourcesAreBundled,
            "index.html and Purchases.umd.js should be in RevenueCatUI resources"
        )
    }

    func testAssembledHTMLInjectsConfigAndUMD() throws {
        let config = EmbeddedCheckoutConfig(
            apiKey: "rcb_sb_test",
            appUserID: "user_1",
            offeringId: "default",
            packageId: "$rc_monthly"
        )
        let html = try XCTUnwrap(config.assembledHTML())
        XCTAssertTrue(html.contains("rcb_sb_test"))
        XCTAssertTrue(html.contains("user_1"))
        XCTAssertTrue(html.contains("default"))
        XCTAssertFalse(html.contains("__RC_EMBEDDED_CHECKOUT_JSON__"))
        XCTAssertFalse(html.contains("__PURCHASES_JS_UMD__"))
        XCTAssertTrue(html.contains("Purchases"))
        XCTAssertTrue(html.contains("showDiscountCodeField: true"))
    }

}

#endif
