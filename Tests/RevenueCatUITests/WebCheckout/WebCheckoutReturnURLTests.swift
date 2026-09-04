//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutReturnURLTests.swift
//
//  Created by Antonio Pallares on 4/9/26.
//

@testable import RevenueCatUI
import XCTest

#if os(iOS) && canImport(WebKit)

final class WebCheckoutReturnURLTests: TestCase {

    private let returnURL = WebCheckoutReturnURL(
        url: URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return")!
    )!

    // MARK: - Construction

    func testCannotBeBuiltFromAURLWithoutAnOrigin() {
        XCTAssertNil(WebCheckoutReturnURL(url: URL(string: "/hosted-checkout-return")!))
    }

    // MARK: - Matching

    func testMatchesTheExactURL() {
        XCTAssertTrue(
            self.returnURL.matches(URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return")!)
        )
    }

    /// The outcome arrives in the query, and providers append parameters of their own beside it.
    func testMatchesRegardlessOfTheQuery() {
        XCTAssertTrue(
            self.returnURL.matches(
                URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return?status=success&x=1")!
            )
        )
    }

    func testMatchesRegardlessOfAFragment() {
        XCTAssertTrue(
            self.returnURL.matches(URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return#done")!)
        )
    }

    func testMatchesRegardlessOfATrailingSlash() {
        XCTAssertTrue(
            self.returnURL.matches(URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return/")!)
        )
    }

    func testATrailingSlashInTheConfiguredURLStillMatchesOneWithout() {
        let withSlash = WebCheckoutReturnURL(
            url: URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return/")!
        )!

        XCTAssertTrue(
            withSlash.matches(URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return")!)
        )
    }

    func testDoesNotMatchADifferentPath() {
        XCTAssertFalse(
            self.returnURL.matches(URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout")!)
        )
    }

    func testDoesNotMatchAPathThatMerelyContainsIt() {
        XCTAssertFalse(
            self.returnURL.matches(
                URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return/extra")!
            )
        )
    }

    func testDoesNotMatchADifferentHost() {
        XCTAssertFalse(
            self.returnURL.matches(URL(string: "https://evil.example/rcbilling/v1/hosted-checkout-return")!)
        )
    }

    func testDoesNotMatchTheSameHostOverPlainHTTP() {
        XCTAssertFalse(
            self.returnURL.matches(URL(string: "http://api.example.com/rcbilling/v1/hosted-checkout-return")!)
        )
    }

    func testDoesNotMatchADifferentPort() {
        XCTAssertFalse(
            self.returnURL.matches(URL(string: "https://api.example.com:8443/rcbilling/v1/hosted-checkout-return")!)
        )
    }

    func testDoesNotMatchNil() {
        XCTAssertFalse(self.returnURL.matches(nil))
    }

    // MARK: - Status

    func testReadsASuccessStatus() {
        XCTAssertEqual(
            self.returnURL.status(
                of: URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return?status=success")!
            ),
            .success
        )
    }

    func testReadsACancelStatus() {
        XCTAssertEqual(
            self.returnURL.status(
                of: URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout-return?status=cancel")!
            ),
            .cancel
        )
    }

    func testReadsTheStatusAlongsideOtherParameters() {
        XCTAssertEqual(
            self.returnURL.status(
                of: URL(string: "https://api.example.com/x?session=abc&status=success&locale=en")!
            ),
            .success
        )
    }

    func testHasNoStatusWhenTheParameterIsAbsent() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "https://api.example.com/x?session=abc")!))
    }

    func testHasNoStatusWhenTheValueIsNotRecognized() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "https://api.example.com/x?status=maybe")!))
    }

    func testHasNoStatusWhenTheValueIsEmpty() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "https://api.example.com/x?status=")!))
    }

    func testHasNoStatusForNil() {
        XCTAssertNil(self.returnURL.status(of: nil))
    }

}

#endif
