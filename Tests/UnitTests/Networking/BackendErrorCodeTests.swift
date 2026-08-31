//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendErrorCodeTests.swift
//
//  Created by RevenueCat on 8/18/26.

import Nimble
import XCTest

@testable import RevenueCat

class BackendErrorCodeTests: TestCase {

    // MARK: - invalidIAMToken

    func testInvalidIAMTokenDecodesFromItsRawIntValue() {
        expect(BackendErrorCode(code: 7981)) == .invalidIAMToken
    }

    func testInvalidIAMTokenDecodesFromItsRawStringValue() {
        expect(BackendErrorCode(code: "7981")) == .invalidIAMToken
    }

    func testInvalidIAMTokenMapsToInvalidCredentialsError() {
        expect(BackendErrorCode.invalidIAMToken.toPurchasesErrorCode()) == .invalidCredentialsError
    }

    // MARK: - cannotAliasToAuthenticatedUser

    func testCannotAliasToAuthenticatedUserDecodesFromItsRawIntValue() {
        expect(BackendErrorCode(code: 8077)) == .cannotAliasToAuthenticatedUser
    }

    func testCannotAliasToAuthenticatedUserDecodesFromItsRawStringValue() {
        expect(BackendErrorCode(code: "8077")) == .cannotAliasToAuthenticatedUser
    }

    func testCannotAliasToAuthenticatedUserMapsToConfigurationError() {
        expect(BackendErrorCode.cannotAliasToAuthenticatedUser.toPurchasesErrorCode()) == .configurationError
    }

    // MARK: - unknownVirtualCurrencyCode

    func testUnknownVirtualCurrencyCodeDecodesFromItsRawIntValue() {
        expect(BackendErrorCode(code: 7870)) == .unknownVirtualCurrencyCode
    }

    func testUnknownVirtualCurrencyCodeDecodesFromItsRawStringValue() {
        expect(BackendErrorCode(code: "7870")) == .unknownVirtualCurrencyCode
    }

    func testUnknownVirtualCurrencyCodeMapsToPurchaseInvalidError() {
        expect(BackendErrorCode.unknownVirtualCurrencyCode.toPurchasesErrorCode()) == .purchaseInvalidError
    }

    // MARK: - duplicateVirtualCurrencyTransaction

    func testDuplicateVirtualCurrencyTransactionDecodesFromItsRawIntValue() {
        expect(BackendErrorCode(code: 8139)) == .duplicateVirtualCurrencyTransaction
    }

    func testDuplicateVirtualCurrencyTransactionDecodesFromItsRawStringValue() {
        expect(BackendErrorCode(code: "8139")) == .duplicateVirtualCurrencyTransaction
    }

    func testDuplicateVirtualCurrencyTransactionMapsToPurchaseInvalidError() {
        expect(BackendErrorCode.duplicateVirtualCurrencyTransaction.toPurchasesErrorCode()) == .purchaseInvalidError
    }

    // MARK: - invalidIdempotencyKey

    func testInvalidIdempotencyKeyDecodesFromItsRawIntValue() {
        expect(BackendErrorCode(code: 8140)) == .invalidIdempotencyKey
    }

    func testInvalidIdempotencyKeyDecodesFromItsRawStringValue() {
        expect(BackendErrorCode(code: "8140")) == .invalidIdempotencyKey
    }

    func testInvalidIdempotencyKeyMapsToPurchaseInvalidError() {
        expect(BackendErrorCode.invalidIdempotencyKey.toPurchasesErrorCode()) == .purchaseInvalidError
    }

}
