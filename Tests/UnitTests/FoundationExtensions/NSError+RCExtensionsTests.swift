//
// Created by RevenueCat on 2/26/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class NSErrorRCExtensionsTests: TestCase {

    func testSubscriberAttributesErrorsNilIfNoAttributesErrors() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let error = NSError(
            domain: RCPurchasesErrorCodeDomain,
            code: errorCode,
            userInfo: [:]
        )
        expect(error.subscriberAttributesErrors).to(beNil())
    }

    func testSubscriberAttributesErrorsReturnsAttributesErrorsInUserInfo() {
        let errorCode = ErrorCode.purchaseNotAllowedError.rawValue
        let attributeErrors = ["$phoneNumber": "phone number is in invalid format",
                               "$email": "email is too long"]
        let error = NSError(
            domain: RCPurchasesErrorCodeDomain,
            code: errorCode,
            userInfo: [ErrorDetails.attributeErrorsKey: attributeErrors]
        )
        expect(error.subscriberAttributesErrors).toNot(beNil())
        expect(error.subscriberAttributesErrors) == attributeErrors
    }
}
