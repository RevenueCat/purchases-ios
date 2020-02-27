//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class NSErrorRCExtensionsTests: XCTestCase {

    func testShouldMarkSyncedKeyPresentFalseIfCodeIsNetworkError() {
        let errorCode = Purchases.ErrorCode.networkError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        expect(error.shouldMarkSyncedKeyPresent()) == false
    }

    func testShouldMarkSyncedKeyPresentFalseIfNotShouldMarkSynced() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [RCShouldMarkSyncedKey: false])
        expect(error.shouldMarkSyncedKeyPresent()) == false
    }

    func testShouldMarkSyncedKeyPresentFalseIfShouldMarkSyncedNotPresent() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        expect(error.shouldMarkSyncedKeyPresent()) == false
    }

    func testShouldMarkSyncedKeyPresentTrueIfShouldMarkSynced() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [RCShouldMarkSyncedKey: true])
        expect(error.shouldMarkSyncedKeyPresent()) == true
    }

    func testShouldMarkSyncedKeyPresentTrueIfTrueForUnderlyingError() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let underlyingError = NSError(domain: Purchases.ErrorDomain, code: errorCode,
                                      userInfo: [RCShouldMarkSyncedKey: true])
        expect(underlyingError.shouldMarkSyncedKeyPresent()) == true

        let error = Purchases.ErrorUtils.networkError(withUnderlyingError: underlyingError)
        expect((error as NSError).shouldMarkSyncedKeyPresent()) == true
    }

    func testShouldMarkSyncedKeyPresentFalseIfFalseForUnderlyingError() {
        let errorCode = Purchases.ErrorCode.networkError.rawValue
        let underlyingError = NSError(domain: Purchases.ErrorDomain, code: errorCode,
                                      userInfo: [RCShouldMarkSyncedKey: true])
        expect(underlyingError.shouldMarkSyncedKeyPresent()) == false

        let error = Purchases.ErrorUtils.networkError(withUnderlyingError: underlyingError)
        expect((error as NSError).shouldMarkSyncedKeyPresent()) == false
    }
}
