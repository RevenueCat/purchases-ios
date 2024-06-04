//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendOfflineEntitlementsTests.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendOfflineEntitlementsTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetProductEntitlementMapping() {
        let isAppBackgrounded: Bool = .random()

        self.httpClient.mock(
            requestPath: .getProductEntitlementMapping,
            response: .init(statusCode: .success, response: Self.productsEntitlements as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.offlineEntitlements.getProductEntitlementMapping(isAppBackgrounded: isAppBackgrounded,
                                                                  completion: completed)
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == .default(
            forBackgroundedApp: isAppBackgrounded
        )

        expect(result).to(beSuccess())
        expect(result?.value?.products).to(haveCount(2))
    }

    func testGetProductEntitlementMappingCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getProductEntitlementMapping,
            response: .init(statusCode: .success,
                            response: Self.noProductsEntitlements as [String: Any],
                            delay: .milliseconds(10))
        )

        let responses: Atomic<Int> = .init(0)

        self.offlineEntitlements.getProductEntitlementMapping(isAppBackgrounded: false) { _ in responses.value += 1 }
        self.offlineEntitlements.getProductEntitlementMapping(isAppBackgrounded: false) { _ in responses.value += 1 }

        expect(responses.value).toEventually(equal(2))
        expect(self.httpClient.calls).to(haveCount(1))
    }
}

private extension BackendOfflineEntitlementsTests {

    static let noProductsEntitlements: [String: Any?] = [
        "product_entitlement_mapping": [:] as [String: Any]
    ]

    static let productsEntitlements: [String: Any?] = [
        "product_entitlement_mapping": [
            "com.revenuecat.foo_1": [
                "product_identifier": "com.revenuecat.foo_1",
                "entitlements": [
                    "pro_1"
                ]
            ] as [String: Any],
            "com.revenuecat.foo_2": [
                "product_identifier": "com.revenuecat.foo_2",
                "entitlements": [
                    "pro_1",
                    "pro_2"
                ]
            ] as [String: Any]
        ]
    ]

}
