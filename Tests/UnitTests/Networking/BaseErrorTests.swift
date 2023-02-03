//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseErrorTests.swift
//
//  Created by Nacho Soto on 4/7/22.

// swiftlint:disable multiline_parameters

import Nimble
@testable import RevenueCat
import XCTest

class BaseErrorTests: TestCase {

    /// Compares the result of calling `asPurchasesError` on a `PurchasesErrorConvertible`
    /// against the expected `ErrorCode`.
    final func verifyPurchasesError(
        _ error: PurchasesErrorConvertible,
        expectedCode: ErrorCode,
        underlyingError: Error? = nil,
        userInfoKeys: [NSError.UserInfoKey]? = nil,
        file: FileString = #file, line: UInt = #line
    ) {
        let nsError = error.asPurchasesError as NSError

        expect(
            file: file, line: line,
            nsError.domain
        ) == RCPurchasesErrorCodeDomain
        expect(
            file: file, line: line,
            nsError.code
        ) == expectedCode.rawValue

        if let underlyingError = underlyingError {
            expect(
                file: file, line: line,
                nsError.userInfo[NSUnderlyingErrorKey] as? NSError
            ).to(matchError(underlyingError),
                 description: "Invalid underlying error")
        } else {
            expect(
                file: file, line: line,
                nsError.userInfo[NSUnderlyingErrorKey]
            ).to(beNil(), description: "Expected no underlying error")
        }

        if let userInfoKeys = userInfoKeys {
            expect(nsError.userInfo.keys).to(contain(userInfoKeys as [String]))
        }
    }

}
