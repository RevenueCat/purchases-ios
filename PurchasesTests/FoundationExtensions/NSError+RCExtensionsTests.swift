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
        let errorCode = ErrorCodes.networkError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        expect(error.rc_successfullySynced()) == false
    }

    func testSuccessfullySyncedFalseIfNotShouldMarkSynced() {
        let errorCode = ErrorCodes.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [RCSuccessfullySyncedKey: false])
        expect(error.rc_successfullySynced()) == false
    }

    func testSuccessfullySyncedFalseIfShouldMarkSyncedNotPresent() {
        let errorCode = ErrorCodes.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        expect(error.rc_successfullySynced()) == false
    }

    func testSuccessfullySyncedTrueIfShouldMarkSynced() {
        let errorCode = ErrorCodes.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [RCSuccessfullySyncedKey: true])
        expect(error.rc_successfullySynced()) == true
    }

    func testSubscriberAttributesErrorsNilIfNoAttributesErrors() {
        let errorCode = ErrorCodes.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [RCSuccessfullySyncedKey: true])
        expect(error.rc_subscriberAttributesErrors()).to(beNil())
    }

    func testSubscriberAttributesErrorsReturnsAttributesErrorsInUserInfo() {
        let errorCode = ErrorCodes.purchaseNotAllowedError.rawValue
        let attributeErrors = ["$phoneNumber": "phone number is in invalid format",
                               "$email": "email is too long"]
        let error = NSError(domain: RCPurchasesErrorCodeDomain,
                            code: errorCode,
                            userInfo: [RCAttributeErrorsKey: attributeErrors])
        expect(error.rc_subscriberAttributesErrors()).toNot(beNil())
        expect(error.rc_subscriberAttributesErrors() as? [String: String]) == attributeErrors
    }
}
