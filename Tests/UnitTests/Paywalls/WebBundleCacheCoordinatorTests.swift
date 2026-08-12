//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleCacheCoordinatorTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/26.
//

@preconcurrency import Combine
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

import WebKit

final class WebBundleCacheCoordinatorTests: TestCase {

    func test_integration_clearsStoredWebsiteDataAndIdentifier() async throws {
        guard #available(iOS 17.0, macOS 14.0, *) else {
            throw XCTSkip("Persistent website data stores are unavailable.")
        }

        // Given
        let cookieName = "revenuecat-cache-clear-test"
        let cookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: "revenuecat.test", .path: "/", .name: cookieName, .value: UUID().uuidString
        ]))

        WebViewDataStoreIdentifierStore.clearIdentifier()
        let storeIdentifier = WebViewDataStoreIdentifierStore.identifier()

        // Keep the data store alive so cache clearing can be observed through its cookie store.
        // Successful store removal cannot be reliably exercised in this unit-test host because
        // WebKit may race and crash; this test therefore covers the data-removal fallback.
        let websiteDataStore = await WKWebsiteDataStore(forIdentifier: storeIdentifier)
        await websiteDataStore.httpCookieStore.setCookie(cookie)

        let initialCookies = await websiteDataStore.httpCookieStore.allCookies()
        XCTAssertTrue(initialCookies.contains { $0.name == cookieName })

        // When
        await WebBundleCacheCoordinator.clearWebsiteData()

        // Then

        let deadline = Date().addingTimeInterval(1)
        var cookies = await websiteDataStore.httpCookieStore.allCookies()
        while !cookies.isEmpty && Date() < deadline {
            await yield()
            cookies = await websiteDataStore.httpCookieStore.allCookies()
        }

        XCTAssertTrue(cookies.isEmpty)
        XCTAssertNil(WebViewDataStoreIdentifierStore.clearIdentifier())
    }
}

#endif
