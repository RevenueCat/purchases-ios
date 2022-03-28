//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
final class BackendSubscriberAttributesTestsiOS14AndAbove: BaseBackendSubscriberAttributesTestClass {

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
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) else {
            print("Skipping test because it's iOS 14+ only.")
            return
        }

        return super.invokeTest()
    }

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}
