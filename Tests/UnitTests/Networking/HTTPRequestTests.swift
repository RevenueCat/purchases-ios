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
    private static let anonymousUser = "$RCAnonymousID:8252eb283bbc4453a3f81c978f1a6ee1"

    private static let paths: [HTTPRequest.Path] = [
        .getCustomerInfo(appUserID: userID),
        .getOfferings(appUserID: userID),
        .getIntroEligibility(appUserID: userID),
        .logIn,
        .postAttributionData(appUserID: userID),
        .postOfferForSigning,
        .postReceiptData,
        .postSubscriberAttributes(appUserID: userID),
        .health,
        .getProductEntitlementMapping
    ]
    private static let unauthenticatedPaths: Set<HTTPRequest.Path> = [
        .health
    ]
    private static let pathsWithoutETags: Set<HTTPRequest.Path> = [
        .health
    ]
    private static let pathsWithSignatureVerification: Set<HTTPRequest.Path> = [
        .getCustomerInfo(appUserID: userID),
        .logIn,
        .postReceiptData,
        .health,
        .getOfferings(appUserID: userID),
        .getProductEntitlementMapping
    ]
    private static let pathsThatRequireNonce: Set<HTTPRequest.Path> = [
        .getCustomerInfo(appUserID: userID),
        .logIn,
        .postReceiptData,
        .health
    ]
    private static let pathsWithUserID: [HTTPRequest.Path] = [
        .getCustomerInfo(appUserID: anonymousUser),
        .getOfferings(appUserID: anonymousUser),
        .getIntroEligibility(appUserID: anonymousUser),
        .postAttributionData(appUserID: anonymousUser),
        .postSubscriberAttributes(appUserID: anonymousUser)
    ]

    func testPathsDontHaveLeadingSlash() {
        for path in Self.paths {
            expect(path.relativePath).toNot(beginWith("/"))
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

    func testPathsSupportingSignatureSignatureVerification() {
        for path in Self.pathsWithSignatureVerification {
            expect(path.supportsSignatureVerification).to(
                beTrue(),
                description: "Path '\(path)' should have signature verification"
            )
        }
    }

    func testPathsNotSupportingSignatureVerification() {
        for path in Self.paths where !Self.pathsWithSignatureVerification.contains(path) {
            expect(path.supportsSignatureVerification).to(
                beFalse(),
                description: "Path '\(path)' should not have signature verification"
            )
        }
    }

    func testPathsRequiringNonceForSignature() {
        for path in Self.pathsThatRequireNonce {
            expect(path.needsNonceForSigning).to(
                beTrue(),
                description: "Path '\(path)' requires nonce for signing"
            )
        }
    }

    func testPathsNotRequiringNonceForSignature() {
        for path in Self.paths where !Self.pathsThatRequireNonce.contains(path) {
            expect(path.needsNonceForSigning).to(
                beFalse(),
                description: "Path '\(path)' does not require nonce for signing"
            )
        }
    }

    func testPathsThatRequireANonceSupportSignatureVerification() {
        for path in Self.paths where path.needsNonceForSigning {
            expect(path.supportsSignatureVerification).to(
                beTrue(),
                description: "Path '\(path)' should support signature verification"
            )
        }
    }

    func testStaticEndpoints() {
        let staticEndpoints = Self.paths
            .filter { $0.supportsSignatureVerification }
            .filter { !$0.needsNonceForSigning }

        expect(staticEndpoints) == [
            .getOfferings(appUserID: Self.userID),
            .getProductEntitlementMapping
        ]
    }

    func testPathsEscapeUserID() {
        for path in Self.pathsWithUserID {
            expect(path.relativePath).toNot(
                contain(Self.anonymousUser),
                description: "Path '\(path)' should escape user ID"
            )
            expect(path.relativePath).to(
                contain(Self.anonymousUser.trimmedAndEscaped),
                description: "Path '\(path)' should escape user ID"
            )
        }
    }

    func testUserIDEscaping() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let expectedPath = "subscribers/\(encodedUserID)"

        expect(HTTPRequest.Path.getCustomerInfo(appUserID: encodeableUserID).relativePath) == expectedPath
    }

    func testURLWithNoProxy() {
        let path: HTTPRequest.Path = .health
        expect(path.url) == URL(string: "https://api.revenuecat.com/v1/health")
        expect(path.url(proxyURL: nil)) == URL(string: "https://api.revenuecat.com/v1/health")
    }

    func testURLWithProxy() {
        let path: HTTPRequest.Path = .health
        expect(path.url(proxyURL: URL(string: "https://test_url"))) == URL(string: "https://test_url/v1/health")
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredWithExistingNonceDoesNotReplaceNonce() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let existingNonce = Data.randomNonce()
        let request: HTTPRequest = .init(method: .get, path: .health, nonce: existingNonce)
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce) == existingNonce
    }

    func testAddNonceIfRequiredWithDisabledVerification() throws {
        let request: HTTPRequest = .init(method: .get, path: .mockPath)
        expect(request.requestAddingNonceIfRequired(with: .disabled).nonce).to(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredWithPathWithNoSignatureVerification() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let request: HTTPRequest = .init(method: .get, path: .postOfferForSigning)
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).to(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredWithPathNotRequiringNonce() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let request: HTTPRequest = .init(method: .get, path: .getOfferings(appUserID: Self.userID))
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).to(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredForPathWithSignatureVerificationWhenEnforced() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"))
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).toNot(beNil())
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testAddNonceIfRequiredForPathWithSignatureVerificationWhenModeInformational() throws {
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
