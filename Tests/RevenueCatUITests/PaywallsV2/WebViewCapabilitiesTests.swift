//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewCapabilitiesTests.swift

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)

import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewCapabilitiesTests: TestCase {

    // MARK: - Content-blocking rules

    func testContentRuleListIdentifierIsStableConstant() {
        XCTAssertEqual(WebViewCapabilitiesConfiguration.contentRuleListIdentifier, "rc-webview-v2-isolation")
    }

    func testContentBlockingRulesAreValidJSON() throws {
        let rules = try XCTUnwrap(WebViewCapabilitiesConfiguration.contentBlockingRules)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(rules.utf8)))
    }

    func testContentBlockingRulesHaveTwoBlockRules() throws {
        let parsed = try Self.parseRules()
        XCTAssertEqual(parsed.count, 2)
        for rule in parsed {
            let action = try XCTUnwrap(rule["action"] as? [String: Any])
            XCTAssertEqual(action["type"] as? String, "block")
        }
    }

    func testRemoteImagesScriptsAndFontsAreBlockedButSameOriginAllowed() throws {
        let trigger = try Self.trigger(matchingResourceTypes: ["image", "script", "font"])

        XCTAssertEqual(trigger["url-filter"] as? String, ".*")
        XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
    }

    func testThirdPartyXHRIsBlocked() throws {
        let trigger = try Self.trigger(matchingResourceTypes: ["raw"])

        XCTAssertEqual(trigger["url-filter"] as? String, ".*")
        XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
    }

    func testLoadIsolatedDoesNotLoadWhenRuleListCompilationFails() {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let failingStore = WebViewContentRuleListStore { _, _, completion in
            completion(nil)
        }

        let url = URL(string: "https://example.com/bundle.html")!
        PaywallWebViewScripts.loadIsolated(url: url, on: webView, ruleListStore: failingStore)

        let expectation = self.expectation(description: "rule list callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)

        XCTAssertNil(webView.url)
    }

    // MARK: - Helpers

    private static func parseRules() throws -> [[String: Any]] {
        let json = try XCTUnwrap(WebViewCapabilitiesConfiguration.contentBlockingRules)
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try XCTUnwrap(object as? [[String: Any]])
    }

    private static func trigger(matchingResourceTypes resourceTypes: [String]) throws -> [String: Any] {
        let triggers = try Self.parseRules().compactMap { $0["trigger"] as? [String: Any] }
        let match = triggers.first { trigger in
            (trigger["resource-type"] as? [String]).map(Set.init) == Set(resourceTypes)
        }
        return try XCTUnwrap(match, "No rule blocking resource types \(resourceTypes)")
    }

}

#endif
