//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorCodeTests.swift
//
//  Created by Joshua Liebowitz on 9/16/21.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class ErrorCodeTests: TestCase {

    func testUnknownError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .unknownError, expectedRawValue: 0)
    }

    func testPurchaseCancelledError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .purchaseCancelledError, expectedRawValue: 1)
    }

    func testStoreProblemError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .storeProblemError, expectedRawValue: 2)
    }

    func testPurchaseNotAllowedError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .purchaseNotAllowedError, expectedRawValue: 3)
    }

    func testPurchaseInvalidError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .purchaseInvalidError, expectedRawValue: 4)
    }

    func testProductNotAvailableForPurchaseError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .productNotAvailableForPurchaseError, expectedRawValue: 5)
    }

    func testProductAlreadyPurchasedError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .productAlreadyPurchasedError, expectedRawValue: 6)
    }

    func testReceiptAlreadyInUseError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .receiptAlreadyInUseError, expectedRawValue: 7)
    }

    func testInvalidReceiptError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .invalidReceiptError, expectedRawValue: 8)
    }

    func testMissingReceiptFileError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .missingReceiptFileError, expectedRawValue: 9)
    }

    func testNetworkError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .networkError, expectedRawValue: 10)
    }

    func testInvalidCredentialsError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .invalidCredentialsError, expectedRawValue: 11)
    }

    func testUnexpectedBackendResponseError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .unexpectedBackendResponseError, expectedRawValue: 12)
    }

    func testReceiptInUseByOtherSubscriberError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .receiptInUseByOtherSubscriberError, expectedRawValue: 13)
    }

    func testInvalidAppUserIdError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .invalidAppUserIdError, expectedRawValue: 14)
    }

    func testOperationAlreadyInProgressForProductError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .operationAlreadyInProgressForProductError,
                                              expectedRawValue: 15)
    }

    func testUnknownBackendError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .unknownBackendError, expectedRawValue: 16)
    }

    func testInvalidAppleSubscriptionKeyError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .invalidAppleSubscriptionKeyError, expectedRawValue: 17)
    }

    func testIneligibleError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .ineligibleError, expectedRawValue: 18)
    }

    func testInsufficientPermissionsError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .insufficientPermissionsError, expectedRawValue: 19)
    }

    func testPaymentPendingError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .paymentPendingError, expectedRawValue: 20)
    }

    func testInvalidSubscriberAttributesError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .invalidSubscriberAttributesError, expectedRawValue: 21)
    }

    func testLogOutAnonymousUserError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .logOutAnonymousUserError, expectedRawValue: 22)
    }

    func testConfigurationError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .configurationError, expectedRawValue: 23)
    }

    func testUnsupportedError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .unsupportedError, expectedRawValue: 24)
    }

    func testEmptySubscriberAttributes() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .emptySubscriberAttributes, expectedRawValue: 25)
    }

    func testProductDiscountMissingIdentifierError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .productDiscountMissingIdentifierError, expectedRawValue: 26)
    }

    func testProductDiscountMissingSubscriptionGroupIdentifierError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .productDiscountMissingSubscriptionGroupIdentifierError,
                                              expectedRawValue: 28)
    }

    func testCustomerInfoError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .customerInfoError,
                                              expectedRawValue: 29)
    }

    func testSystemInfoError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .systemInfoError,
                                              expectedRawValue: 30)
    }

    func testBeginRefundRequestError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .beginRefundRequestError,
                                              expectedRawValue: 31)
    }

    func testProductRequestTimedOut() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .productRequestTimedOut,
                                              expectedRawValue: 32)
    }

    func testAPIEndpointBlockedError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .apiEndpointBlockedError,
                                              expectedRawValue: 33)
    }

    func testInvalidPromotionalOffer() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .invalidPromotionalOfferError,
                                              expectedRawValue: 34)
    }

    func testOfflineConnectionError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .offlineConnectionError,
                                              expectedRawValue: 35)
    }

    func testFeatureNotAvailableInCustomEntitlementsComputationMode() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .featureNotAvailableInCustomEntitlementsComputationMode,
                                              expectedRawValue: 36)
    }

    func testSignatureVerificationFailedError() {
        ensureEnumCaseMatchesExpectedRawValue(errorCode: .signatureVerificationFailed,
                                              expectedRawValue: 37)
    }

    func testErrorCodeEnumCasesAreCoveredInTests() {
        expect(ErrorCode.allCases).to(haveCount(37))
    }

    func ensureEnumCaseMatchesExpectedRawValue(errorCode: ErrorCode, expectedRawValue: Int) {
        expect(errorCode.rawValue).to(equal(expectedRawValue))
    }

    func testRemovedErrorCodesAreNotReAdded() {
        expect(ErrorCode.reservedRawValues).toNot(contain(ErrorCode.allCases.map { $0.rawValue }))
    }

}
