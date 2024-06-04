//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseErrorTests.swift
//
//  Created by Nacho Soto on 4/8/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchaseErrorTests: BaseErrorTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testInvalidQuantityError() {
        let error: Product.PurchaseError = .invalidQuantity

        verifyPurchasesError(error,
                             expectedCode: .storeProblemError,
                             underlyingError: error)
    }

    func testProductUnavailableError() {
        let error: Product.PurchaseError = .productUnavailable

        verifyPurchasesError(error,
                             expectedCode: .productNotAvailableForPurchaseError,
                             underlyingError: error)
    }

    func testPurchaseNotAllowedError() {
        let error: Product.PurchaseError = .purchaseNotAllowed

        verifyPurchasesError(error,
                             expectedCode: .purchaseNotAllowedError,
                             underlyingError: error)
    }

    func testIneligibleForOfferError() {
        let error: Product.PurchaseError = .ineligibleForOffer

        verifyPurchasesError(error,
                             expectedCode: .ineligibleError,
                             underlyingError: error)
    }

    func testInvalidOfferError() {
        let error: Product.PurchaseError = .missingOfferParameters

        verifyPurchasesError(error,
                             expectedCode: .invalidPromotionalOfferError,
                             underlyingError: error)
    }

}
