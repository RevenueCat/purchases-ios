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
@testable import RevenueCat
import XCTest

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

final class WebBundleCacheCoordinatorTests: TestCase {

    func testCacheClearTargetsConfiguredWebsiteDataStore() {
        let subject = PassthroughSubject<WebBundleEvent, Never>()
        let storeIdentifier = UUID()
        let cacheCleared = self.expectation(description: "Website data cleared")
        let coordinator = WebBundleCacheCoordinator(
            events: subject.eraseToAnyPublisher(),
            websiteDataStoreIdentifier: { storeIdentifier },
            clearWebsiteData: { receivedIdentifier in
                XCTAssertEqual(receivedIdentifier, storeIdentifier)
                cacheCleared.fulfill()
            }
        )

        subject.send(.cacheClearRequested)

        self.wait(for: [cacheCleared], timeout: 1)
        withExtendedLifetime(coordinator) {}
    }

    func testEveryCacheClearRequestIsHandled() {
        let subject = PassthroughSubject<WebBundleEvent, Never>()
        let cacheCleared = self.expectation(description: "Website data cleared")
        cacheCleared.expectedFulfillmentCount = 2
        let coordinator = WebBundleCacheCoordinator(
            events: subject.eraseToAnyPublisher(),
            clearWebsiteData: { _ in cacheCleared.fulfill() }
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
            clearWebsiteData: { _ in cacheCleared.fulfill() }
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
