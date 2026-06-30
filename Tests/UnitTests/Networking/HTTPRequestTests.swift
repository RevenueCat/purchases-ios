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
    private static let clientTransactionID = "AABBCCDD-1111-2222-3333-444455556666"

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
        .getProductEntitlementMapping,
        .rewardVerificationStatus(appUserID: userID, clientTransactionID: clientTransactionID),
        .getWorkflows(appUserID: userID, type: nil),
        .getWorkflow(appUserID: userID, workflowId: "wf_1"),
        .remoteConfig(domain: "app")
    ]
    private static let unauthenticatedPaths: Set<HTTPRequest.Path> = [
        .health
    ]
    private static let pathsWithoutETags: Set<HTTPRequest.Path> = [
        .health,
        .remoteConfig(domain: "app")
    ]
    private static let pathsWithSignatureVerification: Set<HTTPRequest.Path> = [
        .getCustomerInfo(appUserID: userID),
        .logIn,
        .postReceiptData,
        .health,
        .getOfferings(appUserID: userID),
        .getProductEntitlementMapping,
        .rewardVerificationStatus(appUserID: userID, clientTransactionID: clientTransactionID),
        .getWorkflows(appUserID: userID, type: nil),
        .getWorkflow(appUserID: userID, workflowId: "wf_1"),
        .remoteConfig(domain: "app")
    ]
    private static let pathsThatRequireNonce: Set<HTTPRequest.Path> = [
        .getCustomerInfo(appUserID: userID),
        .logIn,
        .postReceiptData,
        .health,
        .remoteConfig(domain: "app"),
        .rewardVerificationStatus(appUserID: userID, clientTransactionID: clientTransactionID)
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
            expect(path.pathComponent).toNot(beginWith("/"))
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
            .getProductEntitlementMapping,
            .getWorkflows(appUserID: Self.userID, type: nil),
            .getWorkflow(appUserID: Self.userID, workflowId: "wf_1")
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

    func testPathsWithFallbackUrls() {
        for path in Self.paths {
            let fallbackUrlsPaths = path.fallbackUrls.map { $0.absoluteString }
            switch path {
            case .getProductEntitlementMapping:
                XCTAssertEqual(fallbackUrlsPaths,
                               ["https://api-production.8-lives-cat.io/v1/product_entitlement_mapping"])
            case .getOfferings:
                XCTAssertEqual(fallbackUrlsPaths,
                               ["https://api-production.8-lives-cat.io/v1/offerings"])
            case .getWorkflows(_, let type):
                let expected = type.map {
                    "https://api-production.8-lives-cat.io/workflows/v1/workflows?type=\($0)"
                } ?? "https://api-production.8-lives-cat.io/workflows/v1/workflows"
                XCTAssertEqual(fallbackUrlsPaths, [expected])
            case let .getWorkflow(_, workflowId):
                XCTAssertEqual(fallbackUrlsPaths,
                               ["https://api-production.8-lives-cat.io/workflows/v1/workflows/\(workflowId)"])
            case .remoteConfig:
                XCTAssertEqual(fallbackUrlsPaths,
                               ["https://api-production.8-lives-cat.io/v1/config/app"])
            default:
                XCTAssertTrue(fallbackUrlsPaths.isEmpty)
            }
        }
    }

    func testGetWorkflowsFallbackUrlIncludesTypeParam() {
        let path = HTTPRequest.Path.getWorkflows(appUserID: Self.userID, type: "PAYWALL")
        XCTAssertEqual(
            path.fallbackUrls.map { $0.absoluteString },
            ["https://api-production.8-lives-cat.io/workflows/v1/workflows?type=PAYWALL"]
        )
    }

    func testRemoteConfigPathEscapesDomain() {
        let path = HTTPRequest.Path.remoteConfig(domain: "app workflows/project")

        expect(path.relativePath) == "/v1/config/app%20workflows%2Fproject"
        expect(path.fallbackUrls.map { $0.absoluteString })
            == ["https://api-production.8-lives-cat.io/v1/config/app%20workflows%2Fproject"]
    }

    func testGetWorkflowFallbackUrlEscapesWorkflowId() {
        let path = HTTPRequest.Path.getWorkflow(appUserID: Self.userID, workflowId: "wf id/with special")
        XCTAssertEqual(
            path.fallbackUrls.map { $0.absoluteString },
            ["https://api-production.8-lives-cat.io/workflows/v1/workflows/wf%20id%2Fwith%20special"]
        )
    }

    func testUserIDEscaping() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let expectedPath = "subscribers/\(encodedUserID)"

        expect(HTTPRequest.Path.getCustomerInfo(appUserID: encodeableUserID).pathComponent) == expectedPath
    }

    func testUserIDEscapingOnURL() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let expectedURL = "https://api.revenuecat.com/v1/subscribers/\(encodedUserID)"
        let result = HTTPRequest.Path.getCustomerInfo(appUserID: encodeableUserID).url

        expect(result?.absoluteString) == expectedURL
    }

    func testURLWithNoProxy() {
        let path: HTTPRequest.Path = .health
        expect(path.url?.absoluteString) == "https://api.revenuecat.com/v1/health"
        expect(path.url(proxyURL: nil)?.absoluteString) == "https://api.revenuecat.com/v1/health"
    }

    func testURLWithProxy() {
        let path: HTTPRequest.Path = .health
        expect(path.url(proxyURL: URL(string: "https://test_url"))?.absoluteString) == "https://test_url/v1/health"
    }

    func testAddNonceIfRequiredWithExistingNonceDoesNotReplaceNonce() throws {
        let existingNonce = Data.randomNonce()
        let request: HTTPRequest = .init(method: .get, path: .health, nonce: existingNonce)
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce) == existingNonce
    }

    func testAddNonceIfRequiredWithDisabledVerification() throws {
        let request: HTTPRequest = .init(method: .get, path: .mockPath)
        expect(request.requestAddingNonceIfRequired(with: .disabled).nonce).to(beNil())
    }

    func testAddNonceIfRequiredWithPathWithNoSignatureVerification() throws {
        let request: HTTPRequest = .init(method: .get, path: .postOfferForSigning)
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).to(beNil())
    }

    func testAddNonceIfRequiredWithPathNotRequiringNonce() throws {
        let request: HTTPRequest = .init(method: .get, path: .getOfferings(appUserID: Self.userID))
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).to(beNil())
    }

    func testAddNonceIfRequiredForPathWithSignatureVerificationWhenEnforced() throws {
        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"))
        let mode = Signing.enforcedVerificationMode()

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).toNot(beNil())
    }

    func testAddNonceIfRequiredForPathWithSignatureVerificationWhenModeInformational() throws {
        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"))
        let mode = Signing.verificationMode(with: .informational)

        expect(request.requestAddingNonceIfRequired(with: mode).nonce).toNot(beNil())
    }

    func testRequestIsNotRetryableByDefault() {
        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"))
        expect(request.isRetryable).to(beFalse())
    }

    func testRequestIsRetryableIfSet() {
        let request: HTTPRequest = .init(method: .get, path: .getCustomerInfo(appUserID: "user"), isRetryable: true)
        expect(request.isRetryable).to(beTrue())
    }

    func testRemoteConfigUsesRCContainerAcceptHeader() {
        let request: HTTPRequest = .init(
            method: .post(RemoteConfigRequest(appUserID: "app-user-id")),
            path: .remoteConfig(domain: "app")
        )
        let headers = request.headers(
            with: [:],
            defaultHeaders: [:],
            verificationMode: .disabled,
            internalSettings: DangerousSettings.Internal.default
        )

        expect(headers[HTTPClient.RequestHeader.accept.rawValue]) == HTTPClient.rcContainerFormatAcceptHeaderValue
        expect(headers[HTTPClient.RequestHeader.acceptEncoding.rawValue])
            == HTTPClient.rcContainerFormatAcceptEncodingHeaderValue
    }
}
