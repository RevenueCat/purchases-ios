//
// Created by RevenueCat on 3/28/22.
// Copyright (c) 2022 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
final class BackendSubscriberAttributesTestsiOS13AndBelow: BaseBackendSubscriberAttributesTestClass {

    // MARK: PostReceipt with subscriberAttributes

    override func testPostReceiptWithSubscriberAttributesSendsThemCorrectly() throws {
        try super.testPostReceiptWithSubscriberAttributesSendsThemCorrectly()
    }

    override func testPostReceiptWithSubscriberAttributesReturnsBadJson() throws {
        try super.testPostReceiptWithSubscriberAttributesReturnsBadJson()
    }

    override func testPostReceiptWithoutSubscriberAttributesSkipsThem() throws {
        try super.testPostReceiptWithoutSubscriberAttributesSkipsThem()
    }

    override func testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsError() throws {
        try super.testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsError()
    }

    override func testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsSuccess() throws {
        try super.testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsSuccess()
    }

    override func invokeTest() {
        guard #available(iOS 14.0.0, tvOS 14.0.0, macOS 11.0.0, watchOS 7.0, *) else {
            return super.invokeTest()
        }

        print("Skipping test because it's iOS 12 to 13.x only.")
    }

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}
