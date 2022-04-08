//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitErrorTests.swift
//
//  Created by Nacho Soto on 4/8/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKitErrorTests: BaseErrorTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testUserCancelledError() {
        let error: StoreKitError = .userCancelled

        verifyPurchasesError(error,
                             expectedCode: .purchaseCancelledError,
                             underlyingError: error)
    }

    func testNetworkError() {
        let underlyingError: URLError = .init(.badServerResponse)
        let error: StoreKitError = .networkError(underlyingError)

        verifyPurchasesError(error,
                             expectedCode: .networkError,
                             underlyingError: underlyingError)
    }

    func testSystemError() {
        let underlyingError: URLError = .init(.cannotCreateFile)
        let error: StoreKitError = .systemError(underlyingError)

        verifyPurchasesError(error,
                             expectedCode: .storeProblemError,
                             underlyingError: underlyingError)
    }

    func testNotAvailableInStorefrontError() {
        let error: StoreKitError = .notAvailableInStorefront

        verifyPurchasesError(error,
                             expectedCode: .productNotAvailableForPurchaseError,
                             underlyingError: error)
    }

    #if swift(>=5.6)
    func testNotEntitledError() throws {
        guard #available(iOS 15.4, tvOS 15.4, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let error: StoreKitError = .notEntitled

        verifyPurchasesError(error,
                             expectedCode: .storeProblemError,
                             underlyingError: error)
    }
    #endif

    func testUnknownError() {
        let error: StoreKitError = .unknown

        verifyPurchasesError(error,
                             expectedCode: .storeProblemError,
                             underlyingError: error)
    }

}
