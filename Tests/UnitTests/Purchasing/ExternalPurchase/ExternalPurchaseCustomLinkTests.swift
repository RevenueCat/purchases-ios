//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseCustomLinkTests.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ExternalPurchaseCustomLinkTests: TestCase {

    // MARK: - Token types

    func testTokenTypeRawValues() {
        expect(ExternalPurchaseTokenType.inApp.rawValue) == "IN_APP"
        expect(ExternalPurchaseTokenType.linkOut.rawValue) == "LINK_OUT"
    }

    func testTokenTypeForwardsUnrecognizedValues() {
        expect(ExternalPurchaseTokenType(rawValue: "SOMETHING_ELSE").rawValue) == "SOMETHING_ELSE"
    }

    // MARK: - StoreKit mapping

    // ExternalPurchaseCustomLink was introduced in the iOS 18.1 SDK / Swift 6.0.2.
    #if compiler(>=6.0.2)

    func testNoticeTypeMapsToStoreKitNoticeType() throws {
        guard #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) else {
            throw XCTSkip("Requires StoreKit's external purchase custom link API")
        }

        expect(ExternalPurchaseNoticeType.browser.storeKitNoticeType) == .browser
        expect(ExternalPurchaseNoticeType.withinApp.storeKitNoticeType) == .withinApp
    }

    func testNoticeResultMapsFromStoreKitNoticeResult() throws {
        guard #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) else {
            throw XCTSkip("Requires StoreKit's external purchase custom link API")
        }

        expect(ExternalPurchaseNoticeResult(.continued)) == .continued
        expect(ExternalPurchaseNoticeResult(.cancelled)) == .cancelled
    }

    #endif

    // MARK: - StoreKit implementation

    func testIsAPIAvailableMatchesTheBuildAndRuntimeEnvironment() {
        let customLink = StoreKitExternalPurchaseCustomLink()

        #if compiler(>=6.0.2)
        if #available(iOS 18.1, macOS 15.1, tvOS 18.1, watchOS 11.1, visionOS 2.1, *) {
            expect(customLink.isAPIAvailable) == true
        } else {
            expect(customLink.isAPIAvailable) == false
        }
        #else
        expect(customLink.isAPIAvailable) == false
        #endif
    }

    func testUnavailableAPIThrowsWhenRequestingAToken() async throws {
        let customLink = StoreKitExternalPurchaseCustomLink()

        guard !customLink.isAPIAvailable else {
            throw XCTSkip("Only reachable when the external purchase custom link API is unavailable")
        }

        do {
            _ = try await customLink.token(for: .inApp)
            fail("Expected an error")
        } catch {
            expect(error).to(matchError(ExternalPurchaseError.apiUnavailable))
        }

        let isEligible = await customLink.isEligible()
        expect(isEligible) == false
    }

    // MARK: - Mock

    func testMockReportsIneligible() async {
        let customLink = MockExternalPurchaseCustomLink()
        customLink.stubbedIsEligible = false

        let isEligible = await customLink.isEligible()

        expect(isEligible) == false
        expect(customLink.invokedIsEligibleCount) == 1
    }

    func testMockReturnsNoTokenWithoutFailing() async throws {
        let customLink = MockExternalPurchaseCustomLink()
        customLink.stubbedTokenResult = .success(nil)

        let token = try await customLink.token(for: .linkOut)

        expect(token).to(beNil())
        expect(customLink.invokedTokenTypes) == [.linkOut]
    }

    func testMockPropagatesTokenFailures() async {
        let customLink = MockExternalPurchaseCustomLink()
        let expectedError = NSError(domain: "ExternalPurchaseCustomLinkTests", code: 1)
        customLink.stubbedTokenResult = .failure(expectedError)

        do {
            _ = try await customLink.token(for: .inApp)
            fail("Expected an error")
        } catch {
            expect(error).to(matchError(expectedError))
        }

        expect(customLink.invokedTokenTypes) == [.inApp]
    }

    func testMockReportsCancelledNotice() async throws {
        let customLink = MockExternalPurchaseCustomLink()
        customLink.stubbedNoticeResult = .success(.cancelled)

        let result = try await customLink.showNotice(type: .withinApp)

        expect(result) == .cancelled
        expect(customLink.invokedNoticeTypes) == [.withinApp]
    }

    func testMockPropagatesNoticeFailures() async {
        let customLink = MockExternalPurchaseCustomLink()
        let expectedError = NSError(domain: "ExternalPurchaseCustomLinkTests", code: 2)
        customLink.stubbedNoticeResult = .failure(expectedError)

        do {
            _ = try await customLink.showNotice(type: .browser)
            fail("Expected an error")
        } catch {
            expect(error).to(matchError(expectedError))
        }

        expect(customLink.invokedNoticeTypes) == [.browser]
    }

}
