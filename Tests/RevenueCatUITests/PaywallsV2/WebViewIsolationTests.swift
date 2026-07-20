//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)
import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewIsolationTests: TestCase {

    func testContentRulesShape() throws {
        XCTAssertEqual(WebViewIsolation.contentRuleListIdentifier, "rc-webview-v2-isolation")
        let rules = WebViewIsolation.contentBlockingRules
        let data = try XCTUnwrap(rules.data(using: .utf8))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])

        XCTAssertEqual(object.count, 1)
        let trigger = try XCTUnwrap(object[0]["trigger"] as? [String: Any])
        XCTAssertEqual(
            trigger["resource-type"] as? [String],
            ["image", "script", "font", "raw", "style-sheet", "media", "document"]
        )
        XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
        let action = try XCTUnwrap(object[0]["action"] as? [String: Any])
        XCTAssertEqual(action["type"] as? String, "block")
        XCTAssertFalse(rules.contains(#""url-filter": "data:"#))
    }

    func testContentBlockingRulesCompileThroughWebKit() async throws {
        let identifier = "\(WebViewIsolation.contentRuleListIdentifier)-integration-test"

        let ruleList: WKContentRuleList? = await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: WebViewIsolation.contentBlockingRules
            ) { compiled, _ in
                continuation.resume(returning: compiled)
            }
        }

        XCTAssertNotNil(ruleList)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifier) { _ in
                continuation.resume()
            }
        }
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
