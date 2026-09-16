//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewNavigationFailureTests.swift
//
//  Created by Antonio Pallares on 4/9/26.
//

@testable import RevenueCatUI
import XCTest

final class WebViewNavigationFailureTests: TestCase {

    func testURLCancellationIsACancellation() {
        XCTAssertTrue(
            WebViewNavigationFailure.isCancellation(
                NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
            )
        )
    }

    func testPolicyChangeIsACancellation() {
        XCTAssertTrue(
            WebViewNavigationFailure.isCancellation(NSError(domain: "WebKitErrorDomain", code: 102))
        )
    }

    func testARealNetworkFailureIsNotACancellation() {
        XCTAssertFalse(
            WebViewNavigationFailure.isCancellation(
                NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
            )
        )
    }

    func testAnotherWebKitErrorIsNotACancellation() {
        XCTAssertFalse(
            WebViewNavigationFailure.isCancellation(NSError(domain: "WebKitErrorDomain", code: 101))
        )
    }

    /// The codes only mean cancellation within their own domain.
    func testTheSameCodeInAnotherDomainIsNotACancellation() {
        XCTAssertFalse(
            WebViewNavigationFailure.isCancellation(NSError(domain: "com.example.other", code: 102))
        )
    }

}
