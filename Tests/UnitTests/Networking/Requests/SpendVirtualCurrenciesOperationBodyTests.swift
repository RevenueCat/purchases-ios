//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SpendVirtualCurrenciesOperationBodyTests.swift
//
//  Created by RevenueCat on 8/25/26.

import Nimble
import XCTest

@testable import RevenueCat

// NOTE: These tests intentionally exercise `SpendVirtualCurrenciesOperation.Body`'s `Encodable`
// conformance directly rather than driving the operation through `MockHTTPClient`. As written,
// `HTTPRequestPath.pathComponent`'s `.spendVirtualCurrencies` case calls `assertionFailure(...)`,
// and `MockHTTPClient.perform` always resolves the mock lookup URL with `preferIAMPath: false`
// (see `HTTPRequestPath.url(preferIAMPath:)`), which means `pathComponent` (not `iamPathComponent`)
// is always evaluated. Any test that performs an actual `.spendVirtualCurrencies` HTTP request
// through `MockHTTPClient` would therefore always hit that `assertionFailure`, crashing the test
// process. Until the test double is updated to honor `tokenManager.enabled` (mirroring what
// `HTTPClient.perform` does in production), the network round-trip for this operation can't be
// safely exercised with the existing test infrastructure.
class SpendVirtualCurrenciesOperationBodyTests: TestCase {

    func testBodyEncodesAdjustmentsAndReference() throws {
        let body = SpendVirtualCurrenciesOperation.Body(
            adjustments: ["GLD": 50, "SLV": 10],
            reference: "order-123"
        )

        let data = try JSONEncoder().encode(body)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        let adjustments = try XCTUnwrap(json["adjustments"] as? [String: Int])
        expect(adjustments) == ["GLD": 50, "SLV": 10]
        expect(json["reference"] as? String) == "order-123"
    }

    func testBodyOmitsReferenceKeyWhenNil() throws {
        let body = SpendVirtualCurrenciesOperation.Body(
            adjustments: ["GLD": 50],
            reference: nil
        )

        let data = try JSONEncoder().encode(body)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(json["adjustments"] as? [String: Int]) == ["GLD": 50]
        expect(json.keys.contains("reference")).to(beFalse())
    }

    func testBodyEncodesEmptyAdjustments() throws {
        let body = SpendVirtualCurrenciesOperation.Body(adjustments: [:], reference: nil)

        let data = try JSONEncoder().encode(body)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(json["adjustments"] as? [String: Int]) == [:]
    }

}
