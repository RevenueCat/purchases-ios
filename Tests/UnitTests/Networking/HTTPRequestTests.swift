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
    private static let pathsWithoutETags: Set<HTTPRequest.Path> = [
        .health
    ]
    private static let pathsWithSignatureValidation: Set<HTTPRequest.Path> = [
        .getCustomerInfo(appUserID: userID),
        .logIn,
        .postReceiptData,
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
                description: "Path '\(path)' should not be authenticated"
            )
        }
    }

    func testPathsSendETag() {
        for path in Self.paths where !Self.pathsWithoutETags.contains(path) {
            expect(path.shouldSendEtag).to(
                beTrue(),
                description: "Path '\(path)' should send etag"
            )
        }
    }

    func testPathsDontSendEtag() {
        for path in Self.pathsWithoutETags {
            expect(path.shouldSendEtag).to(
                beFalse(),
                description: "Path '\(path)' should not send etag"
            )
        }
    }

    func testPathsHaveSignatureValidation() {
        for path in Self.pathsWithSignatureValidation {
            expect(path.hasSignatureValidation).to(
                beTrue(),
                description: "Path '\(path)' should have signature validation"
            )
        }
    }

    func testPathsWithoutSignatureValidation() {
        for path in Self.paths where !Self.pathsWithSignatureValidation.contains(path) {
            expect(path.hasSignatureValidation).to(
                beFalse(),
                description: "Path '\(path)' should not have signature validation"
            )
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredWithExistingNonceDoesNotReplaceNonce() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let existingNonce = Data.randomNonce()
        let request: HTTPRequest = .init(method: .get, path: .health, nonce: existingNonce)
        let mode = Signing.verificationMode(with: .enforced)

        expect(request.requestAddingNonceIfRequired(with: mode).nonce) == existingNonce
    }

    func testAddNonceIfRequiredWithDisabledVerification() throws {
        let request: HTTPRequest = .init(method: .get, path: .mockPath)
        expect(request.requestAddingNonceIfRequired(with: .disabled).nonce).to(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredWithPathWithNoSignatureValidation() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let request: HTTPRequest = .init(method: .get, path: .postOfferForSigning)
        let mode = Signing.verificationMode(with: .enforced)

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).to(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredForPathWithSignatureValidationWhenEnforced() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"))
        let mode = Signing.verificationMode(with: .enforced)

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).toNot(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredForPathWithSignatureValidationWhenModeInformational() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"))
        let mode = Signing.verificationMode(with: .informational)

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).toNot(beNil())
    }

    func testAddNonceIfRequiredForOldVersions() throws {
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
            throw XCTSkip("Test only for older versions")
        }

        let request: HTTPRequest = .init(method: .get, path: .logIn)
        expect(request.requestAddingNonceIfRequired(with: .disabled).nonce).to(beNil())
    }

}
