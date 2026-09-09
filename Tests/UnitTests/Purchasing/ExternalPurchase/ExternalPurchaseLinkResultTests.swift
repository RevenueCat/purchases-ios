//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseLinkResultTests.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class ExternalPurchaseLinkResultTests: TestCase {

    func testRegisteredTokenIsHandedToTheCheckout() {
        let result = ExternalPurchaseLinkResult(preparationResult: .registered(tokenID: "token_id"))

        expect(result) == .proceed(externalPurchaseTokenID: "token_id")
    }

    func testUnregisteredTokenStillOpensTheCheckout() {
        expect(ExternalPurchaseLinkResult(preparationResult: .unregistered(.tokenRequestFailed)))
            == .proceed(externalPurchaseTokenID: nil)
        expect(ExternalPurchaseLinkResult(preparationResult: .unregistered(.registrationFailed)))
            == .proceed(externalPurchaseTokenID: nil)
    }

    func testAnIneligibleCustomerKeepsTheLink() {
        let result = ExternalPurchaseLinkResult(preparationResult: .stopped(.notEligible))

        expect(result) == .proceed(externalPurchaseTokenID: nil)
    }

    /// Unlike being ineligible, a device that cannot authorize payments is not offered the link either.
    func testNothingOpensWhenThePaymentsAreNotAuthorized() {
        let result = ExternalPurchaseLinkResult(preparationResult: .stopped(.paymentsNotAuthorized))

        expect(result) == .stopped
    }

    func testNothingOpensWhenTheCustomerDeclinesTheNotice() {
        let result = ExternalPurchaseLinkResult(preparationResult: .stopped(.customerCancelledNotice))

        expect(result) == .stopped
    }

    func testNothingOpensWhenTheNoticeCannotBeShown() {
        let result = ExternalPurchaseLinkResult(preparationResult: .stopped(.noticeFailed))

        expect(result) == .stopped
    }

}
