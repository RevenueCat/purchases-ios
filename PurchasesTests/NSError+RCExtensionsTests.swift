//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class NSErrorRCExtensionsTests: XCTestCase {
    func testDidBackendReceiveRequestCorrectlyFalseIfCodeIsNetworkError() {
        let errorCode = Purchases.ErrorCode.networkError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        expect(error.didBackendReceiveRequestCorrectly()) == false
    }

    func testDidBackendReceiveRequestCorrectlyFalseIfNotFinishable() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [Purchases.FinishableKey: false])
        expect(error.didBackendReceiveRequestCorrectly()) == false
    }

    func testDidBackendReceiveRequestCorrectlyFalseIfFinishableNotPresent() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        expect(error.didBackendReceiveRequestCorrectly()) == false
    }

    func testDidBackendReceiveRequestCorrectlyTrueIfFinishable() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [Purchases.FinishableKey: true])
        expect(error.didBackendReceiveRequestCorrectly()) == true
    }

    func testDidBackendReceiveRequestCorrectlyTrueIfTrueForUnderlyingError() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let underlyingError = NSError(domain: Purchases.ErrorDomain, code: errorCode,
                                      userInfo: [Purchases.FinishableKey: true])
        expect(underlyingError.didBackendReceiveRequestCorrectly()) == true

        let error = Purchases.ErrorUtils.networkError(withUnderlyingError: underlyingError)
        expect((error as NSError).didBackendReceiveRequestCorrectly()) == true
    }
}
