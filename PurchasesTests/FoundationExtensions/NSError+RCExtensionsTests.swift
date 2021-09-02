//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import RevenueCat

class NSErrorRCExtensionsTests: XCTestCase {

    func testSuccessfullySyncedFalseIfCodeIsNetworkError() {
        let errorCode = ErrorCode.networkError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        expect(error.successfullySynced) == false
    }

    func testSuccessfullySyncedFalseIfNotShouldMarkSynced() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [Backend.RCSuccessfullySyncedKey as String: false])
        expect(error.successfullySynced) == false
    }

    func testSuccessfullySyncedFalseIfShouldMarkSyncedNotPresent() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        expect(error.successfullySynced) == false
    }

    func testSuccessfullySyncedTrueIfShouldMarkSynced() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [Backend.RCSuccessfullySyncedKey as String: true])
        expect(error.successfullySynced) == true
    }

    func testSubscriberAttributesErrorsNilIfNoAttributesErrors() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [Backend.RCSuccessfullySyncedKey as String: true])
        expect(error.subscriberAttributesErrors).to(beNil())
    }

    func testSubscriberAttributesErrorsReturnsAttributesErrorsInUserInfo() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let attributeErrors = ["$phoneNumber": "phone number is in invalid format",
                               "$email": "email is too long"]
        let error = NSError(domain: RCPurchasesErrorCodeDomain,
                            code: errorCode,
                            userInfo: [Backend.RCAttributeErrorsKey as String: attributeErrors])
        expect(error.subscriberAttributesErrors).toNot(beNil())
        expect(error.subscriberAttributesErrors) == attributeErrors
    }
}
