//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStoreProductsManagerTests.swift
//
//  Created by Antonio Pallares on 28/7/25.

import Nimble
@testable import RevenueCat
import XCTest

#if TEST_STORE

class TestStoreProductsManagerTests: TestCase {

    static var requestTimeout: TimeInterval = 60

    private var deviceCache: MockDeviceCache!
    var backend: MockBackend!
    var offerings: MockOfferingsAPI!

    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        self.deviceCache = .init()
        self.deviceCache.stubbedAppUserID = "appUserID"
        self.backend = MockBackend()
        self.offerings = try XCTUnwrap(self.backend.offerings as? MockOfferingsAPI)
    }

    func testFetchTestStoreProductsWithIdentifiersTriggersTheCorrectRequest() throws {
        self.offerings.stubbedGetWebProductsCompletionResult = .failure(BackendError.networkError(.offlineConnection()))

        let manager = self.createManager()
        let _ = waitUntilValue { completed in
            manager.products(withIdentifiers: ["product1", "product2"], completion: completed)
        }

        expect(self.offerings.invokedGetWebProducts).to(beTrue())
        expect(self.offerings.invokedGetWebProductsCount).to(equal(1))
        let params = try XCTUnwrap(self.offerings.invokedGetWebProductsParameters)
        expect(params.appUserID).to(equal("appUserID"))
        expect(params.productIds).to(equal(Set(["product1", "product2"])))
    }

    fileprivate func createManager() -> TestStoreProductsManager {
        return TestStoreProductsManager(backend: self.backend,
                                        deviceCache: self.deviceCache,
                                        requestTimeout: Self.requestTimeout)
    }
}

#endif // TEST_STORE
