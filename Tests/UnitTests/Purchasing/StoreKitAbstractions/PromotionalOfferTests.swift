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

    func testConversionFromAndToSKPaymentDiscount() throws {
        let signedData: PromotionalOffer.SignedData = Self.randomOffer
        let reencoded: PromotionalOffer.SignedData = .init(sk1PaymentDiscount: signedData.sk1PromotionalOffer)

        expect(reencoded) == signedData
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSK2PurchaseOption() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let option = try Self.randomOffer.sk2PurchaseOption
        let expected: Product.PurchaseOption = .promotionalOffer(
            offerID: Self.randomOffer.identifier,
            keyID: Self.randomOffer.keyIdentifier,
            nonce: Self.randomOffer.nonce,
            // `Product.PurchaseOption` conforms to Equatable but it does not compare this
            // The only way to validate this is correct is integration tests.
            signature: Data(),
            timestamp: Self.randomOffer.timestamp
        )

        expect(option) == expected
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSK2PurchaseOptionWithInvalidSignatureThrows() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        do {
            _ = try Self.invalidOffer.sk2PurchaseOption
            fail("Expected error")
        } catch {
            expect(error).to(matchError(
                PromotionalOffer.SignedData.Error
                    .failedToDecodeSignature(Self.invalidOffer.signature)
            ))
        }
    }

}

// MARK: - Private

private extension PromotionalOfferTests {

    static let randomOffer: PromotionalOffer.SignedData = .init(
        identifier: "identifier \(Int.random(in: 0..<1000))",
        keyIdentifier: "key identifier \(Int.random(in: 0..<1000))",
        nonce: .init(),
        signature: "signature \(Int.random(in: 0..<1000))".asData.base64EncodedString(),
        timestamp: Int.random(in: 0..<1000)
    )

    static let invalidOffer: PromotionalOffer.SignedData = .init(
        identifier: "identifier \(Int.random(in: 0..<1000))",
        keyIdentifier: "key identifier \(Int.random(in: 0..<1000))",
        nonce: .init(),
        signature: "signature \(Int.random(in: 0..<1000))",
        timestamp: Int.random(in: 0..<1000)
    )

}
