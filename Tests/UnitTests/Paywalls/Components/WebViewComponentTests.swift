//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentTests.swift

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class WebViewComponentTests: TestCase {

    func testCodable() throws {
        let jsonData = try JsonLoader.data(for: "WebViewComponent")

        let webView: PaywallComponent.WebViewComponent = try JSONDecoder.default
            .decode(PaywallComponent.WebViewComponent.self, from: jsonData)

        let webView2 = try webView.encodeAndDecode()

        XCTAssertEqual(webView.url.absoluteString, "https://example.com")
        XCTAssertEqual(webView, webView2)
    }

    func testDecodeAsPaywallComponent() throws {
        let jsonData = try JsonLoader.data(for: "WebViewComponent")

        let component = try JSONDecoder.default
            .decode(PaywallComponent.self, from: jsonData)

        guard case .webView(let webView) = component else {
            XCTFail("Expected .webView component, got \(component)")
            return
        }

        XCTAssertEqual(webView.url.absoluteString, "https://example.com")
    }

}
