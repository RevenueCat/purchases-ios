//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class NSErrorRCExtensionsTests: XCTestCase {

    func testSuccessfullySyncedFalseIfCodeIsNetworkError() {
        let errorCode = Purchases.ErrorCode.networkError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        expect(error.successfullySynced()) == false
    }

    func testSuccessfullySyncedFalseIfNotShouldMarkSynced() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [RCSuccessfullySyncedKey: false])
        expect(error.successfullySynced()) == false
    }

    func testSuccessfullySyncedFalseIfShouldMarkSyncedNotPresent() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [:])
        expect(error.successfullySynced()) == false
    }

    func testSuccessfullySyncedTrueIfShouldMarkSynced() {
        let errorCode = Purchases.ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: Purchases.ErrorDomain, code: errorCode, userInfo: [RCSuccessfullySyncedKey: true])
        expect(error.successfullySynced()) == true
    }
}
