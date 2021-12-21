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

    func testResolvedHost() {
        let host = DNSChecker.resolvedHost(fromURL: URL(string: "https://api.revenuecat.com")!)
        let validIpAddressRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

        expect(host!.range(of: validIpAddressRegex, options: .regularExpression)).toNot(beNil())
        expect(DNSChecker.invalidHosts.contains(host!)).to(equal(false))
    }

    func testIsBlockedURL() {
        let blockedURLs = ["https://127.0.0.1/subscribers", "https://0.0.0.0/offers"];

        for urlString in blockedURLs {
            expect(DNSChecker.isBlockedURL(URL(string: urlString)!)) == true
        }

        expect(DNSChecker.isBlockedURL(URL(string: "https://api.revenuecat.com/offers")!)) == false
    }

    func testIsBlockedHostFromError() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: URL(string: "https://127.0.0.1/subscribers")!]
        let nsErrorWithUserInfo = NSError(domain: "Testing",
                                          code: -1,
                                          userInfo: userInfo as [String: Any])
        let blocked = DNSChecker.blockedHostFromError(nsErrorWithUserInfo as Error)
        expect(blocked) == "127.0.0.1"
    }

    func testIsBlockedLocalHostIPAPIError() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: URL(string: "https://127.0.0.1/subscribers")!]
        let nsErrorWithUserInfo = NSError(domain: "Testing",
                                          code: -1,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == true
    }

    func testIsBlockedZerosIPHostAPIError() {
        let userInfo: [String: Any] = [NSURLErrorFailingURLErrorKey: URL(string: "https://0.0.0.0/subscribers")!]
        let nsErrorWithUserInfo = NSError(domain: "Testing",
                                          code: -1,
                                          userInfo: userInfo as [String: Any])
        expect(DNSChecker.isBlockedAPIError(nsErrorWithUserInfo as Error)) == true
    }

}
