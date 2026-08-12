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

    func test_integration_clearsStoredWebsiteDataAndRotatesIdentifier() async throws {
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

        let websiteDataStore = await WKWebsiteDataStore(forIdentifier: storeIdentifier)
        await websiteDataStore.httpCookieStore.setCookie(cookie)

        let initialCookies = await websiteDataStore.httpCookieStore.allCookies()
        XCTAssertTrue(initialCookies.contains { $0.name == cookieName })

        let coordinator = WebBundleCacheCoordinator()

        // When
        await Task(priority: .userInitiated) {
            await WebBundleEventBus.shared.clearCache()
        }.value

        // Then

        var cookies = await websiteDataStore.httpCookieStore.allCookies()
        while !cookies.isEmpty {
            await yield()
            cookies = await websiteDataStore.httpCookieStore.allCookies()
        }

        let rotatedIdentifier = WebViewDataStoreIdentifierStore.identifier()

        XCTAssertFalse(cookies.contains { $0.name == cookieName })
        XCTAssertNotEqual(rotatedIdentifier, storeIdentifier)
        withExtendedLifetime(coordinator) {}
    }

    func testEveryCacheClearRequestIsHandled() {
        let subject = PassthroughSubject<WebBundleEvent, Never>()
        let cacheCleared = self.expectation(description: "Website data cleared")
        cacheCleared.expectedFulfillmentCount = 2
        let coordinator = WebBundleCacheCoordinator(
            events: subject.eraseToAnyPublisher(),
            clearWebsiteData: { cacheCleared.fulfill() }
        )

        subject.send(.cacheClearRequested)
        subject.send(.cacheClearRequested)

        self.wait(for: [cacheCleared], timeout: 1)
        withExtendedLifetime(coordinator) {}
    }

    func testReceivedAssetURLsDoesNotClearWebsiteData() {
        let subject = PassthroughSubject<WebBundleEvent, Never>()
        let cacheCleared = self.expectation(description: "Website data not cleared")
        cacheCleared.isInverted = true
        let coordinator = WebBundleCacheCoordinator(
            events: subject.eraseToAnyPublisher(),
            clearWebsiteData: { cacheCleared.fulfill() }
        )

        subject.send(
            .receivedAssetURLs([
                .init(url: URL(string: "https://example.com/index.html")!, checksum: nil)
            ])
        )

        self.wait(for: [cacheCleared], timeout: 0.1)
        withExtendedLifetime(coordinator) {}
    }

}

#endif
