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

}
