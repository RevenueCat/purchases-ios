//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequestTests.swift
//
//  Created by Nacho Soto on 3/4/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class HTTPRequestTests: TestCase {

    // MARK: - Paths

    private static let userID = "the_user"

    private static let paths: [HTTPRequest.Path] = [
        .getCustomerInfo(appUserID: userID),
        .getOfferings(appUserID: userID),
        .getIntroEligibility(appUserID: userID),
        .logIn,
        .postAttributionData(appUserID: userID),
        .postOfferForSigning,
        .postReceiptData,
        .postSubscriberAttributes(appUserID: userID),
        .health
    ]
    private static let unauthenticatedPaths: Set<HTTPRequest.Path> = [
        .health
    ]

    func testPathsDontHaveLeadingSlash() {
        for path in Self.paths {
            expect(path.description).toNot(beginWith("/"))
        }
    }

    func testPathsHaveValidURLs() {
        for path in Self.paths {
            expect(path.url).toNot(beNil())
        }
    }

    func testPathIsAuthenticated() {
        for path in Self.paths where !Self.unauthenticatedPaths.contains(path) {
            expect(path.authenticated).to(
                beTrue(),
                description: "Path '\(path)' should be authenticated"
            )
        }
    }

    func testPathIsNotAuthenticated() {
        for path in Self.unauthenticatedPaths {
            expect(path.authenticated).to(
                beFalse(),
                description: "Path '\(path)' should be authenticated"
            )
        }
    }

}
