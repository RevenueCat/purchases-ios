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
            expect(path.url(preferIAMPath: false)).toNot(beNil())
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
            default:
                XCTAssertTrue(fallbackUrlsPaths.isEmpty)
            }
        }
    }

    func testRemoteConfigPathEscapesDomain() {
        let path = HTTPRequest.Path.remoteConfig(domain: "app workflows/project")

        expect(path.relativePath) == "/v1/config/app%20workflows%2Fproject"
        expect(path.fallbackUrls).to(beEmpty())
    }

    func testFallbackConfigPathUsesFallbackHostAndEscapesDomain() {
        let path = HTTPRequest.FallbackPath.remoteConfig(domain: "app workflows/project")

        expect(path.relativePath) == "/v1/config/app%20workflows%2Fproject"
        expect(path.url(preferIAMPath: false)?.absoluteString)
            == "https://api-production.8-lives-cat.io/v1/config/app%20workflows%2Fproject"
        expect(path.fallbackUrls).to(beEmpty())
        expect(path.authenticated).to(beTrue())
        expect(path.shouldSendEtag).to(beTrue())
        expect(path.supportsSignatureVerification).to(beTrue())
        expect(path.needsNonceForSigning).to(beFalse())
        expect(path.name) == "remote_config_fallback"
        expect(path.isFallbackHostPath).to(beTrue())
    }

    func testMainPathsAreNotFallbackHostPaths() {
        expect(HTTPRequest.Path.remoteConfig(domain: "app").isFallbackHostPath).to(beFalse())
        expect(HTTPRequest.Path.getOfferings(appUserID: "user").isFallbackHostPath).to(beFalse())
        expect(HTTPRequest.Path.logIn.isFallbackHostPath).to(beFalse())
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
        let result = HTTPRequest.Path.getCustomerInfo(appUserID: encodeableUserID).url(preferIAMPath: false)

        expect(result?.absoluteString) == expectedURL
    }

    func testURLWithNoProxy() {
        let path: HTTPRequest.Path = .health
        expect(path.url(preferIAMPath: false)?.absoluteString) == "https://api.revenuecat.com/v1/health"
        expect(path.url(proxyURL: nil, preferIAMPath: false)?.absoluteString) == "https://api.revenuecat.com/v1/health"
    }

    func testURLWithProxy() {
        let path: HTTPRequest.Path = .health
        let url = path.url(proxyURL: URL(string: "https://test_url"), preferIAMPath: false)
        expect(url?.absoluteString) == "https://test_url/v1/health"
    }

    func testURLWithAPISource() {
        let path: HTTPRequest.Path = .health
        expect(path.url(apiSourceURL: URL(string: "https://api.rc-backup.com/"), preferIAMPath: false)?.absoluteString)
            == "https://api.rc-backup.com/v1/health"
    }

    func testURLProxyTakesPrecedenceOverAPISource() {
        // A proxy pins every request to itself; passing an api source alongside it is a caller error
        // and must not silently route around the proxy.
        let path: HTTPRequest.Path = .health
        expect(path.url(proxyURL: URL(string: "https://test_url"),
                        apiSourceURL: URL(string: "https://api.rc-backup.com/"), preferIAMPath: false)).to(beNil())
    }

    func testURLFallbackIndexTakesPrecedenceOverAPISource() {
        let path: HTTPRequest.Path = .getOfferings(appUserID: Self.userID)
        expect(path.url(apiSourceURL: URL(string: "https://api.rc-backup.com/"),
                        fallbackUrlIndex: 0,
                        preferIAMPath: false)?.absoluteString)
            == path.fallbackUrls.first?.absoluteString
    }

    func testMainPathsUseAPISources() {
        for path in Self.paths {
            expect(path.usesAPISources).to(beTrue(), description: "Path '\(path)' should use API sources")
        }
    }

    func testWebBillingPathsUseAPISources() {
        let paths: [any HTTPRequestPath] = [
            HTTPRequest.WebBillingPath.getWebOfferingProducts(appUserID: Self.userID),
            HTTPRequest.WebBillingPath.getWebBillingProducts(userId: Self.userID, productIds: ["product_1"])
        ]
        for path in paths {
            expect(path.usesAPISources).to(beTrue(), description: "Path '\(path)' should use API sources")
        }
    }

    func testWebBillingOfferingProductsRelativePathIncludesAppUserID() {
        let path = HTTPRequest.WebBillingPath.getWebOfferingProducts(appUserID: Self.userID)

        expect(path.relativePath) == "/rcbilling/v1/subscribers/\(Self.userID)/offering_products"
    }

    func testWebBillingOfferingProductsRelativeIAMPathOmitsAppUserID() {
        let path = HTTPRequest.WebBillingPath.getWebOfferingProducts(appUserID: Self.userID)

        expect(path.relativeIAMPath) == "/rcbilling/v1/customer/offering_products"
        expect(path.relativeIAMPath).toNot(contain(Self.userID))
        expect(path.relativeIAMPath) != path.relativePath
    }

    func testWebBillingProductsRelativePathIncludesUserIDAndProductIDs() {
        let path = HTTPRequest.WebBillingPath.getWebBillingProducts(userId: Self.userID, productIds: ["product_1"])

        expect(path.relativePath) == "/rcbilling/v1/subscribers/\(Self.userID)/products?id=product_1"
    }

    func testWebBillingProductsRelativeIAMPathOmitsUserID() {
        let path = HTTPRequest.WebBillingPath.getWebBillingProducts(userId: Self.userID, productIds: ["product_1"])

        expect(path.relativeIAMPath) == "/rcbilling/v1/customer/products?id=product_1"
        expect(path.relativeIAMPath).toNot(contain(Self.userID))
        expect(path.relativeIAMPath) != path.relativePath
    }

    func testWebBillingProductsRelativeIAMPathJoinsMultipleProductIDs() {
        // `productIds` is a `Set`, so its iteration order isn't guaranteed: compare the
        // resulting query items as an unordered set of `id=` tokens instead of an exact string.
        let productIds: Set<String> = ["product_1", "product_2", "product_3"]
        let path = HTTPRequest.WebBillingPath.getWebBillingProducts(userId: Self.userID, productIds: productIds)

        expect(path.relativeIAMPath).to(beginWith("/rcbilling/v1/customer/products?"))

        let query = path.relativeIAMPath.replacingOccurrences(
            of: "/rcbilling/v1/customer/products?",
            with: ""
        )
        let actualTokens = Set(query.components(separatedBy: "&"))
        let expectedTokens = Set(productIds.map { "id=\($0)" })

        expect(actualTokens) == expectedTokens
    }

    func testWebBillingProductsRelativeIAMPathPercentEncodesProductIDs() {
        let productIdWithSpace = "product with space"
        let path = HTTPRequest.WebBillingPath.getWebBillingProducts(
            userId: Self.userID,
            productIds: [productIdWithSpace]
        )

        expect(path.relativeIAMPath) == "/rcbilling/v1/customer/products?id=product%20with%20space"
        expect(path.relativeIAMPath).toNot(contain(" "))
    }

    func testWebBillingProductsRelativeIAMPathWithNoProductIDsHasEmptyQuery() {
        let path = HTTPRequest.WebBillingPath.getWebBillingProducts(userId: Self.userID, productIds: [])

        expect(path.relativeIAMPath) == "/rcbilling/v1/customer/products?"
    }

    func testWebBillingPathsURLPreferringIAMPathUsesIAMRelativePath() {
        let offeringProductsPath = HTTPRequest.WebBillingPath.getWebOfferingProducts(appUserID: Self.userID)
        let productsPath = HTTPRequest.WebBillingPath.getWebBillingProducts(
            userId: Self.userID,
            productIds: ["product_1"]
        )

        expect(offeringProductsPath.url(preferIAMPath: true)?.absoluteString)
            == "https://api.revenuecat.com/rcbilling/v1/customer/offering_products"
        expect(offeringProductsPath.url(preferIAMPath: false)?.absoluteString)
            == "https://api.revenuecat.com/rcbilling/v1/subscribers/\(Self.userID)/offering_products"

        expect(productsPath.url(preferIAMPath: true)?.absoluteString)
            == "https://api.revenuecat.com/rcbilling/v1/customer/products?id=product_1"
        expect(productsPath.url(preferIAMPath: false)?.absoluteString)
            == "https://api.revenuecat.com/rcbilling/v1/subscribers/\(Self.userID)/products?id=product_1"
    }

    func testNonMainPathsDoNotUseAPISources() {
        let paths: [any HTTPRequestPath] = [
            HTTPRequest.DiagnosticsPath.postDiagnostics
        ]
        for path in paths {
            expect(path.usesAPISources).to(beFalse(), description: "Path '\(path)' should not use API sources")
        }
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

    func testRemoteConfigUsesRCContainerAcceptHeaders() {
        let request: HTTPRequest = .init(
            method: .post(RemoteConfigRequest(fetchContext: .appStart, appUserID: "app-user-id")),
            path: HTTPRequest.Path.remoteConfig(domain: "app")
        )
        let headers = request.headers(
            with: [:],
            defaultHeaders: [:],
            verificationMode: .disabled,
            internalSettings: DangerousSettings.Internal.default
        )

        expect(headers[HTTPClient.RequestHeader.accept.rawValue]) == HTTPClient.rcContainerFormatAcceptHeaderValue
        expect(headers[HTTPClient.RequestHeader.acceptRCElementEncoding.rawValue])
            == HTTPClient.rcContainerFormatElementEncodingHeaderValue
        expect(headers["Accept-Encoding"]).to(beNil())
    }

    func testFallbackConfigDoesNotRequestRCContainerFormat() {
        let request: HTTPRequest = .init(
            method: .get,
            path: HTTPRequest.FallbackPath.remoteConfig(domain: "app")
        )
        let headers = request.headers(
            with: [:],
            defaultHeaders: [:],
            verificationMode: .disabled,
            internalSettings: DangerousSettings.Internal.default
        )

        expect(headers[HTTPClient.RequestHeader.accept.rawValue]).to(beNil())
        expect(headers[HTTPClient.RequestHeader.acceptRCElementEncoding.rawValue]).to(beNil())
        expect(headers["Accept-Encoding"]).to(beNil())
    }

    func testHeaderSignatureUsesAdditionalHeaderOverride() {
        let sandboxHeader = HTTPClient.RequestHeader.sandbox.rawValue
        let request = HTTPRequest(
            method: .get,
            path: .getCustomerInfo(appUserID: "user"),
            additionalHeaders: [sandboxHeader: "false"]
        )

        let headers = request.headers(
            with: [:],
            defaultHeaders: [sandboxHeader: "true"],
            verificationMode: Signing.verificationMode(with: .informational),
            internalSettings: DangerousSettings.Internal.default
        )

        let expectedHash = HTTPRequest.signingParameterHash(["false"])
        expect(headers[sandboxHeader]) == "false"
        expect(headers[HTTPClient.RequestHeader.headerParametersForSignature.rawValue])
            == HTTPRequest.signatureHashHeader(keys: [sandboxHeader], hash: expectedHash)
    }

    // MARK: - IAM paths

    /// Maps each `HTTPRequest.Path` case (other than `.logIn`, which is disallowed under IAM) to the
    /// relative path it should resolve to when IAM access-token authorization is preferred.
    private static let iamPathComponentsByPath: [HTTPRequest.Path: String] = [
        .getCustomerInfo(appUserID: userID): "customer",
        .getOfferings(appUserID: userID): "customer/offerings",
        .getIntroEligibility(appUserID: userID): "customer/intro_eligibility",
        .postAttributionData(appUserID: userID): "customer/attribution",
        .postOfferForSigning: "offers",
        .postReceiptData: "receipts",
        .postSubscriberAttributes(appUserID: userID): "customer/attributes",
        .postAdServicesToken(appUserID: userID): "customer/adservices_attribution",
        .health: "health",
        .appHealthReport(appUserID: userID): "customer/health_report",
        .appHealthReportAvailability(appUserID: userID): "subscribers/\(userID)/health_report_availability",
        .getProductEntitlementMapping: "product_entitlement_mapping",
        .getCustomerCenterConfig(appUserID: userID): "customer/customercenter",
        .getVirtualCurrencies(appUserID: userID): "customer/virtual_currencies",
        .postRedeemWebPurchase: "subscribers/redeem_purchase",
        .postCreateTicket: "customercenter/support/create-ticket",
        .isPurchaseAllowedByRestoreBehavior(appUserID: userID): "customer/restore/eligibility",
        .rewardVerificationStatus(appUserID: userID, clientTransactionID: clientTransactionID):
            "subscribers/\(userID)/ads/reward_verifications/\(clientTransactionID)",
        .remoteConfig(domain: "app"): "config/app"
    ]

    func testRelativeIAMPathMatchesExpectedComponentPerPath() {
        for (path, expectedComponent) in Self.iamPathComponentsByPath {
            expect(path.relativeIAMPath).to(
                equal("/v1/\(expectedComponent)"),
                description: "Path '\(path)' has an unexpected IAM relative path"
            )
        }
    }

    #if !os(watchOS)
    func testRelativeIAMPathForLoginEndpointCrashes() {
        // The `.logIn` endpoint is not allowed once IAM access tokens are enabled: exchanging a
        // static app-user-id-based endpoint for a token-authenticated one doesn't make sense.
        expect {
            _ = HTTPRequest.Path.logIn.relativeIAMPath
        }.to(throwAssertion())
    }
    #endif

    func testUrlPreferringIAMPathUsesIAMRelativePath() {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)

        let regularURL = path.url(preferIAMPath: false)
        let iamURL = path.url(preferIAMPath: true)

        expect(regularURL?.absoluteString) == "https://api.revenuecat.com/v1/subscribers/\(Self.userID)"
        expect(iamURL?.absoluteString) == "https://api.revenuecat.com/v1/customer"
        expect(iamURL) != regularURL
    }

    func testUrlPreferringIAMPathForPathsWithSharedComponentMatchesRegularURL() {
        // `.health` resolves to the same relative path regardless of IAM preference.
        let path: HTTPRequest.Path = .health

        expect(path.url(preferIAMPath: true)?.absoluteString) == path.url(preferIAMPath: false)?.absoluteString
    }

    func testDefaultHTTPRequestPathIsNotAnIAMPath() {
        for path in Self.paths {
            expect(path.isIAMPath).to(
                beFalse(),
                description: "Path '\(path)' should not be reported as an IAM path by default"
            )
        }
    }

    func testDefaultRelativeIAMPathFallsBackToRelativePathForOtherPathTypes() {
        // `HTTPRequest.FallbackPath` doesn't override `relativeIAMPath`, so it should fall back
        // to the default implementation, which just returns `relativePath`.
        let path = HTTPRequest.FallbackPath.remoteConfig(domain: "app")

        expect(path.relativeIAMPath) == path.relativePath
    }

    // MARK: - Token (IAM auth) paths

    private static let tokenPaths: [HTTPRequest.Path] = [
        .tokenLogin,
        .tokenRefresh,
        .tokenLogOut
    ]

    private static let expectedTokenPathComponents: [HTTPRequest.Path: String] = [
        .tokenLogin: "/auth/login",
        .tokenRefresh: "/auth/token",
        .tokenLogOut: "/auth/revoke"
    ]

    private static let expectedTokenPathNames: [HTTPRequest.Path: String] = [
        .tokenLogin: "token_login",
        .tokenRefresh: "token_refresh",
        .tokenLogOut: "token_logout"
    ]

    func testTokenPathsHaveALeadingSlashUnlikeOtherPaths() {
        // Unlike the rest of `HTTPRequest.Path`, the token (IAM auth) endpoints live outside `/v1`,
        // so their `pathComponent` includes its own leading slash.
        for path in Self.tokenPaths {
            expect(path.pathComponent).to(
                beginWith("/"),
                description: "Path '\(path)' should have a leading slash"
            )
        }
    }

    func testTokenPathComponentsMatchExpectedValues() {
        for (path, expectedComponent) in Self.expectedTokenPathComponents {
            expect(path.pathComponent) == expectedComponent
        }
    }

    func testTokenPathsRelativePathIsNotPrefixedWithV1() {
        // `relativePath` only prepends `/v1` when the `pathComponent` doesn't already have a
        // leading slash, so the token endpoints' relative path is identical to their path component.
        for (path, expectedComponent) in Self.expectedTokenPathComponents {
            expect(path.relativePath) == expectedComponent
        }
    }

    func testTokenPathsRelativeIAMPathMatchesRelativePath() {
        for path in Self.tokenPaths {
            expect(path.relativeIAMPath) == path.relativePath
        }
    }

    func testTokenPathNamesMatchExpectedValues() {
        for (path, expectedName) in Self.expectedTokenPathNames {
            expect(path.name) == expectedName
        }
    }

    func testTokenPathsAreAuthenticated() {
        for path in Self.tokenPaths {
            expect(path.authenticated).to(
                beTrue(),
                description: "Path '\(path)' should be authenticated"
            )
        }
    }

    func testTokenPathsSendETag() {
        for path in Self.tokenPaths {
            expect(path.shouldSendEtag).to(
                beTrue(),
                description: "Path '\(path)' should send etag"
            )
        }
    }

    func testTokenPathsDoNotSupportSignatureVerification() {
        for path in Self.tokenPaths {
            expect(path.supportsSignatureVerification).to(
                beFalse(),
                description: "Path '\(path)' should not support signature verification"
            )
        }
    }

    func testTokenPathsRequireNonceForSigning() {
        for path in Self.tokenPaths {
            expect(path.needsNonceForSigning).to(
                beTrue(),
                description: "Path '\(path)' should require a nonce for signing"
            )
        }
    }

    func testTokenPathsAreIAMPaths() {
        for path in Self.tokenPaths {
            expect(path.isIAMPath).to(
                beTrue(),
                description: "Path '\(path)' should be reported as an IAM path"
            )
        }
    }

    func testTokenPathsUseAPISources() {
        for path in Self.tokenPaths {
            expect(path.usesAPISources).to(beTrue(), description: "Path '\(path)' should use API sources")
        }
    }

    func testTokenPathsHaveNoFallbackUrls() {
        for path in Self.tokenPaths {
            expect(path.fallbackUrls).to(beEmpty())
        }
    }

    func testTokenLoginURLResolvesOutsideOfTheV1Namespace() {
        let url = HTTPRequest.Path.tokenLogin.url(preferIAMPath: false)

        expect(url?.absoluteString) == "https://api.revenuecat.com/auth/login"
    }

    func testTokenPathsURLIsTheSameRegardlessOfIAMPreference() {
        for path in Self.tokenPaths {
            expect(path.url(preferIAMPath: true)?.absoluteString) == path.url(preferIAMPath: false)?.absoluteString
        }
    }

    // MARK: - Bearer authorization header

    func testBearerAuthorizationValueIsNilWhenNoAuthorizationHeaderIsSet() {
        let headers: HTTPRequest.Headers = [:]

        expect(headers.bearerAuthorizationValue).to(beNil())
    }

    func testBearerAuthorizationValueParsesBearerToken() {
        var headers: HTTPRequest.Headers = [:]
        headers.authorizationValue = "Bearer abc123"

        expect(headers.bearerAuthorizationValue) == "abc123"
    }

    func testBearerAuthorizationValueIsNilForNonBearerScheme() {
        var headers: HTTPRequest.Headers = [:]
        headers.authorizationValue = "Basic abc123"

        expect(headers.bearerAuthorizationValue).to(beNil())
    }

    func testBearerAuthorizationValueIsNilWhenSchemeHasNoSeparatingSpace() {
        var headers: HTTPRequest.Headers = [:]
        headers.authorizationValue = "Bearer"

        expect(headers.bearerAuthorizationValue).to(beNil())
    }

    func testBearerAuthorizationValueIsNilWhenPrefixIsSimilarButNotExactMatch() {
        var headers: HTTPRequest.Headers = [:]
        headers.authorizationValue = "Bearertoken abc123"

        expect(headers.bearerAuthorizationValue).to(beNil())
    }

    func testSettingBearerAuthorizationValueUpdatesAuthorizationHeader() {
        var headers: HTTPRequest.Headers = [:]
        headers.bearerAuthorizationValue = "my-access-token"

        expect(headers.authorizationValue) == "Bearer my-access-token"
    }

    func testSettingBearerAuthorizationValueToNilClearsAuthorizationHeader() {
        var headers: HTTPRequest.Headers = [:]
        headers.authorizationValue = "Bearer abc123"
        headers.bearerAuthorizationValue = nil

        expect(headers.authorizationValue).to(beNil())
    }

    func testBearerAuthorizationValueRoundTrips() {
        var headers: HTTPRequest.Headers = [:]
        headers.bearerAuthorizationValue = "round-trip-token"

        expect(headers.bearerAuthorizationValue) == "round-trip-token"
    }
}
