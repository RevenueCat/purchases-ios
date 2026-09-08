//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseLinkPreparationTests.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class ExternalPurchaseLinkPreparationTests: TestCase {

    func testRegisteredTokenIsHandedToTheCheckout() {
        let preparation = ExternalPurchaseLinkPreparation(preparationResult: .registered(tokenID: "token_id"))

        expect(preparation) == .proceed(externalPurchaseTokenID: "token_id")
    }

    func testUnregisteredTokenStillOpensTheCheckout() {
        expect(ExternalPurchaseLinkPreparation(preparationResult: .unregistered(.tokenRequestFailed)))
            == .proceed(externalPurchaseTokenID: nil)
        expect(ExternalPurchaseLinkPreparation(preparationResult: .unregistered(.registrationFailed)))
            == .proceed(externalPurchaseTokenID: nil)
    }

    func testACustomerWhoCannotMakeExternalPurchasesKeepsTheLink() {
        let preparation = ExternalPurchaseLinkPreparation(
            preparationResult: .stopped(.cannotMakeExternalPurchases)
        )

        expect(preparation) == .proceed(externalPurchaseTokenID: nil)
    }

    func testNothingOpensWhenTheCustomerDeclinesTheNotice() {
        let preparation = ExternalPurchaseLinkPreparation(preparationResult: .stopped(.customerCancelledNotice))

        expect(preparation) == .stopped
    }

    func testNothingOpensWhenTheNoticeCannotBeShown() {
        let preparation = ExternalPurchaseLinkPreparation(preparationResult: .stopped(.noticeFailed))

        expect(preparation) == .stopped
    }

}
