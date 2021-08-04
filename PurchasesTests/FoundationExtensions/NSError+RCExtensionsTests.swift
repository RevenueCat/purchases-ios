//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases
@testable import PurchasesCoreSwift

class NSErrorRCExtensionsTests: XCTestCase {

    func testSuccessfullySyncedFalseIfCodeIsNetworkError() {
        let errorCode = ErrorCode.networkError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        expect(error.rc_successfullySynced()) == false
    }

    func testSuccessfullySyncedFalseIfNotShouldMarkSynced() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [Backend.RCSuccessfullySyncedKey as String: false])
        expect(error.rc_successfullySynced()) == false
    }

    func testSuccessfullySyncedFalseIfShouldMarkSyncedNotPresent() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        expect(error.rc_successfullySynced()) == false
    }

    func testSuccessfullySyncedTrueIfShouldMarkSynced() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [Backend.RCSuccessfullySyncedKey as String: true])
        expect(error.rc_successfullySynced()) == true
    }

    func testSubscriberAttributesErrorsNilIfNoAttributesErrors() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [Backend.RCSuccessfullySyncedKey as String: true])
        expect(error.rc_subscriberAttributesErrors()).to(beNil())
    }

    func testSubscriberAttributesErrorsReturnsAttributesErrorsInUserInfo() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let attributeErrors = ["$phoneNumber": "phone number is in invalid format",
                               "$email": "email is too long"]
        let error = NSError(domain: RCPurchasesErrorCodeDomain,
                            code: errorCode,
                            userInfo: [Backend.RCAttributeErrorsKey as String: attributeErrors])
        expect(error.rc_subscriberAttributesErrors()).toNot(beNil())
        expect(error.rc_subscriberAttributesErrors() as? [String: String]) == attributeErrors
    }
}
