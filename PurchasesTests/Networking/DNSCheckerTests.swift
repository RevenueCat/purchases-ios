//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DNSCheckerTests.swift
//
//  Created by Joshua Liebowitz on 12/21/21.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class DNSCheckerTests: XCTestCase {

    let apiURL = URL(string: "https://api.revenuecat.com")!
    let fakeSubscribersURL1 = URL(string: "https://0.0.0.0/subscribers")!
    let fakeSubscribersURL2 = URL(string: "https://127.0.0.1/subscribers")!
    let fakeOffersURL = URL(string: "https://0.0.0.0/offers")!

    func testResolvedHost() {
        let host = DNSChecker.resolvedHost(fromURL: apiURL)
        // swiftlint:disable:next line_length
        let validIPAddressRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

        expect(host!.range(of: validIPAddressRegex, options: .regularExpression)).toNot(beNil())
        expect(DNSChecker.invalidHosts.contains(host!)).to(equal(false))
    }

    func testIsBlockedURL() throws {
        let blockedURLs = ["https://127.0.0.1/subscribers", "https://0.0.0.0/offers"]

        for urlString in blockedURLs {
            expect(DNSChecker.isBlockedURL(try XCTUnwrap(URL(string: urlString)))) == true
        }

        expect(DNSChecker.isBlockedURL(try XCTUnwrap(URL(string: "https://api.revenuecat.com/offers")))) == false
    }

    func testIsBlockedHostFromError() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL2]
        let nsErrorWithUserInfo = NSError(domain: "Testing",
                                          code: -1,
                                          userInfo: userInfo as [String: Any])
        let blocked = DNSChecker.blockedHostFromError(nsErrorWithUserInfo as Error)
        expect(blocked) == "127.0.0.1"
    }

    func testIsBlockedLocalHostIPAPIError() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL1]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == true
    }

    func testWrongErrorCode() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL2]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: -1,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == false
    }

    func testWrongErrorDomain() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL2]
        let nsErrorWithUserInfo = NSError(domain: "FakeDomain",
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == false
    }

    func testWrongErrorDomainAndWrongErrorCode() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL2]
        let nsErrorWithUserInfo = NSError(domain: "FakeDomain",
                                          code: -1,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == false
    }

    func testIsOnlyValidForCorrectErrorDomainAnd() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL2]
        let nsErrorWithUserInfo = NSError(domain: "FakeDomain",
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == false
    }

    func testIsBlockedZerosIPHostAPIError() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: fakeSubscribersURL1]
        let nsErrorWithUserInfo = NSError(domain: NSURLErrorDomain,
                                          code: NSURLErrorCannotConnectToHost,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == true
    }

}
