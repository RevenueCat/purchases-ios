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

    private static let endpoint = "https://api.example.com/rcbilling/v1/hosted-checkout-return"

    private let returnURL = WebCheckoutReturnURL(
        successURL: URL(string: "\(WebCheckoutReturnURLTests.endpoint)?status=success")!,
        cancelURL: URL(string: "\(WebCheckoutReturnURLTests.endpoint)?status=cancel")!
    )!

    // MARK: - Construction

    func testCannotBeBuiltWhenTheSuccessURLHasNoOrigin() {
        XCTAssertNil(
            WebCheckoutReturnURL(
                successURL: URL(string: "/hosted-checkout-return?status=success")!,
                cancelURL: URL(string: "\(Self.endpoint)?status=cancel")!
            )
        )
    }

    func testCannotBeBuiltWhenTheCancelURLHasNoOrigin() {
        XCTAssertNil(
            WebCheckoutReturnURL(
                successURL: URL(string: "\(Self.endpoint)?status=success")!,
                cancelURL: URL(string: "/hosted-checkout-return?status=cancel")!
            )
        )
    }

    // MARK: - Matching

    func testMatchesTheEndpointWithoutAnyQuery() {
        XCTAssertTrue(self.returnURL.matches(URL(string: Self.endpoint)!))
    }

    func testMatchesEitherReturnURL() {
        XCTAssertTrue(self.returnURL.matches(URL(string: "\(Self.endpoint)?status=success")!))
        XCTAssertTrue(self.returnURL.matches(URL(string: "\(Self.endpoint)?status=cancel")!))
    }

    /// Providers append parameters of their own beside the ones the backend configured.
    func testMatchesRegardlessOfExtraParameters() {
        XCTAssertTrue(self.returnURL.matches(URL(string: "\(Self.endpoint)?status=success&session_id=abc")!))
    }

    /// The checkout still has to end, even when we cannot tell which way it went.
    func testMatchesAnUnrecognizedStatus() {
        XCTAssertTrue(self.returnURL.matches(URL(string: "\(Self.endpoint)?status=maybe")!))
    }

    func testMatchesRegardlessOfAFragment() {
        XCTAssertTrue(self.returnURL.matches(URL(string: "\(Self.endpoint)#done")!))
    }

    func testMatchesRegardlessOfATrailingSlash() {
        XCTAssertTrue(self.returnURL.matches(URL(string: "\(Self.endpoint)/")!))
    }

    func testATrailingSlashInTheConfiguredURLStillMatchesOneWithout() {
        let withSlash = WebCheckoutReturnURL(
            successURL: URL(string: "\(Self.endpoint)/?status=success")!,
            cancelURL: URL(string: "\(Self.endpoint)/?status=cancel")!
        )!

        XCTAssertTrue(withSlash.matches(URL(string: Self.endpoint)!))
    }

    func testDoesNotMatchADifferentPath() {
        XCTAssertFalse(self.returnURL.matches(URL(string: "https://api.example.com/rcbilling/v1/hosted-checkout")!))
    }

    func testDoesNotMatchAPathThatMerelyContainsIt() {
        XCTAssertFalse(self.returnURL.matches(URL(string: "\(Self.endpoint)/extra")!))
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
        XCTAssertEqual(self.returnURL.status(of: URL(string: "\(Self.endpoint)?status=success")!), .success)
    }

    func testReadsACancelStatus() {
        XCTAssertEqual(self.returnURL.status(of: URL(string: "\(Self.endpoint)?status=cancel")!), .cancel)
    }

    func testReadsTheStatusAlongsideOtherParameters() {
        XCTAssertEqual(
            self.returnURL.status(of: URL(string: "\(Self.endpoint)?session=abc&status=success&locale=en")!),
            .success
        )
    }

    func testHasNoStatusWhenTheParameterIsAbsent() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "\(Self.endpoint)?session=abc")!))
    }

    func testHasNoStatusWhenTheValueIsNotRecognized() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "\(Self.endpoint)?status=maybe")!))
    }

    func testHasNoStatusWhenTheValueIsEmpty() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "\(Self.endpoint)?status=")!))
    }

    func testHasNoStatusForAnEndpointItDoesNotRecognize() {
        XCTAssertNil(self.returnURL.status(of: URL(string: "https://api.example.com/elsewhere?status=success")!))
    }

    func testHasNoStatusForNil() {
        XCTAssertNil(self.returnURL.status(of: nil))
    }

    // MARK: - Status, told apart by something other than a `status` parameter

    /// Nothing assumes the parameter is named `status`, only that the backend configured the two URLs
    /// with something that tells them apart.
    func testTellsTheURLsApartByAnyParameter() {
        let returnURL = WebCheckoutReturnURL(
            successURL: URL(string: "\(Self.endpoint)?outcome=paid")!,
            cancelURL: URL(string: "\(Self.endpoint)?outcome=abandoned")!
        )!

        XCTAssertEqual(returnURL.status(of: URL(string: "\(Self.endpoint)?outcome=paid")!), .success)
        XCTAssertEqual(returnURL.status(of: URL(string: "\(Self.endpoint)?outcome=abandoned")!), .cancel)
    }

    func testTellsTheURLsApartByPathWhenTheyCarryNoQuery() {
        let returnURL = WebCheckoutReturnURL(
            successURL: URL(string: "\(Self.endpoint)/success")!,
            cancelURL: URL(string: "\(Self.endpoint)/cancel")!
        )!

        XCTAssertEqual(returnURL.status(of: URL(string: "\(Self.endpoint)/success")!), .success)
        XCTAssertEqual(returnURL.status(of: URL(string: "\(Self.endpoint)/cancel")!), .cancel)
    }

    /// A misconfiguration, reported the safe way round rather than as a purchase that may not exist.
    func testReportsACancelWhenTheTwoURLsCannotBeToldApart() {
        let returnURL = WebCheckoutReturnURL(
            successURL: URL(string: Self.endpoint)!,
            cancelURL: URL(string: Self.endpoint)!
        )!

        XCTAssertEqual(returnURL.status(of: URL(string: Self.endpoint)!), .cancel)
    }

}

#endif
