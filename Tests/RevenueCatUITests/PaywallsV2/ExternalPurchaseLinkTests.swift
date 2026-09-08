//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseLinkTests.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ExternalPurchaseLinkTests: TestCase {

    func testAppendsTheTokenIDToALinkWithNoQuery() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1"))

        expect(url.appendingExternalPurchaseTokenID("token_id").absoluteString)
            == "https://pay.rev.cat/abc/user_1?rc_external_purchase_token_id=token_id"
    }

    func testKeepsTheExistingQueryAndFragment() throws {
        let url = try XCTUnwrap(URL(string: "https://pay.rev.cat/abc/user_1?rc_source=paywall#step"))

        expect(url.appendingExternalPurchaseTokenID("token_id").absoluteString)
            == "https://pay.rev.cat/abc/user_1?rc_source=paywall&rc_external_purchase_token_id=token_id#step"
    }

    func testReplacesATokenIDThatIsAlreadyThere() throws {
        let url = try XCTUnwrap(
            URL(string: "https://pay.rev.cat/abc/user_1?rc_external_purchase_token_id=stale")
        )

        expect(url.appendingExternalPurchaseTokenID("token_id").absoluteString)
            == "https://pay.rev.cat/abc/user_1?rc_external_purchase_token_id=token_id"
    }

}

#endif
