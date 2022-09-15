//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferTests.swift
//
//  Created by Nacho Soto on 9/12/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class PromotionalOfferTests: TestCase {

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func testConversionFromAndToSKPaymentDiscount() throws {
        try AvailabilityChecks.iOS12_2APIAvailableOrSkipTest()

        let signedData: PromotionalOffer.SignedData = Self.randomOffer
        let reencoded: PromotionalOffer.SignedData = .init(sk1PaymentDiscount: signedData.sk1PromotionalOffer)

        expect(reencoded) == signedData
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSK2PurchaseOption() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let option = Self.randomOffer.sk2PurchaseOption
        let expected: Product.PurchaseOption = .promotionalOffer(
            offerID: Self.randomOffer.identifier,
            keyID: Self.randomOffer.keyIdentifier,
            nonce: Self.randomOffer.nonce,
            signature: Self.randomOffer.signature.asData,
            timestamp: Self.randomOffer.timestamp
        )

        expect(option) == expected
    }

}

// MARK: - Private

private extension PromotionalOfferTests {

    static let randomOffer: PromotionalOffer.SignedData = .init(
        identifier: "identifier \(Int.random(in: 0..<1000))",
        keyIdentifier: "key identifier \(Int.random(in: 0..<1000))",
        nonce: .init(),
        signature: "signature \(Int.random(in: 0..<1000))",
        timestamp: Int.random(in: 0..<1000)
    )

}
