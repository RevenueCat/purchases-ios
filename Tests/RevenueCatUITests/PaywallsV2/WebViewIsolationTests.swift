//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewIsolationTests: TestCase {

    func testContentRulesShape() throws {
        XCTAssertEqual(WebViewIsolation.contentRuleListIdentifier, "rc-webview-v2-isolation")
        let rules = try XCTUnwrap(WebViewIsolation.contentBlockingRules)
        let data = try XCTUnwrap(rules.data(using: .utf8))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])

        XCTAssertEqual(object.count, 2)
        let firstTrigger = try XCTUnwrap(object[0]["trigger"] as? [String: Any])
        let secondTrigger = try XCTUnwrap(object[1]["trigger"] as? [String: Any])
        XCTAssertEqual(firstTrigger["resource-type"] as? [String], ["image", "script", "font"])
        XCTAssertEqual(firstTrigger["load-type"] as? [String], ["third-party"])
        XCTAssertEqual(secondTrigger["resource-type"] as? [String], ["raw"])
        XCTAssertEqual(secondTrigger["load-type"] as? [String], ["third-party"])
        XCTAssertFalse(rules.contains(#""url-filter": "data:"#))
    }

    func testCompileFailureReturnsNilAndCaches() async {
        WebViewIsolation.resetRuleListCacheForTests()
        var calls = 0
        let original = WebViewIsolation.compileRuleList
        WebViewIsolation.compileRuleList = { _, _ in
            calls += 1
            return nil
        }
        defer {
            WebViewIsolation.compileRuleList = original
            WebViewIsolation.resetRuleListCacheForTests()
        }

        let first = await WebViewIsolation.ruleList()
        let second = await WebViewIsolation.ruleList()

        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(calls, 1)
    }

}

#endif
