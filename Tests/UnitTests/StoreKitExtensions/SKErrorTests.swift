//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SKErrorTests.swift
//
//  Created by Nacho Soto on 4/8/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class SKErrorTests: BaseErrorTests {

    func testStoreProblemError() {
        let error: SKError = .init(.cloudServiceNetworkConnectionFailed)

        verifyPurchasesError(error,
                             expectedCode: .storeProblemError,
                             underlyingError: error)
    }

    func testPurchaseNotAllowedError() {
        let error: SKError = .init(.paymentNotAllowed)

        verifyPurchasesError(error,
                             expectedCode: .purchaseNotAllowedError,
                             underlyingError: error)
    }

    func testPaymentCancelled() {
        let error: SKError = .init(.paymentCancelled)

        verifyPurchasesError(error,
                             expectedCode: .purchaseCancelledError,
                             underlyingError: error)
    }

    func testPaymentInvalid() {
        let error: SKError = .init(.paymentInvalid)

        verifyPurchasesError(error,
                             expectedCode: .purchaseInvalidError,
                             underlyingError: error)
    }

    func testProductNotAvailableError() {
        let error: SKError = .init(.storeProductNotAvailable)

        verifyPurchasesError(error,
                             expectedCode: .productNotAvailableForPurchaseError,
                             underlyingError: error)
    }

    @available(iOS 14.0, macOS 11.0, watchOS 6.2, *)
    @available(tvOS, unavailable)
    func testUnsupportedPlatformError() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        let error: SKError = .init(.unsupportedPlatform)

        verifyPurchasesError(error,
                             expectedCode: .purchaseNotAllowedError,
                             underlyingError: error)
    }

    @available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
    func testIneligibleForOfferError() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        let error: SKError = .init(.ineligibleForOffer)

        verifyPurchasesError(error,
                             expectedCode: .ineligibleError,
                             underlyingError: error)
    }

    @available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
    func testInvalidOfferError() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        let error: SKError = .init(.invalidOfferIdentifier)

        verifyPurchasesError(error,
                             expectedCode: .invalidPromotionalOfferError,
                             underlyingError: error)
    }

    func testCurrentlySubscribedError() throws {
        let error = try XCTUnwrap(
            NSError(
                domain: SKErrorDomain,
                code: SKError.unknown.rawValue,
                userInfo: [
                    NSUnderlyingErrorKey: NSError(
                        domain: "ASDServerErrorDomain",
                        code: 3532,
                        userInfo: [:]
                    )
                ]
            ) as? SKError
        )

        verifyPurchasesError(error,
                             expectedCode: .productAlreadyPurchasedError,
                             underlyingError: error)
    }

    func testPaymentSheetCancelledError() throws {
        let error = try XCTUnwrap(
            NSError(
                domain: SKErrorDomain,
                code: 907,
                userInfo: [
                    NSUnderlyingErrorKey: NSError(
                        domain: "AMSErrorDomain",
                        code: 6,
                        userInfo: [:]
                    )
                ]
            ) as? SKError
        )

        verifyPurchasesError(error,
                             expectedCode: .purchaseCancelledError,
                             underlyingError: error)
    }

    func testUnknownError() throws {
        let error = try XCTUnwrap(
            NSError(
                domain: SKErrorDomain,
                code: 100000
            ) as? SKError
        )

        verifyPurchasesError(error,
                             expectedCode: .unknownError,
                             underlyingError: error)
    }

}
