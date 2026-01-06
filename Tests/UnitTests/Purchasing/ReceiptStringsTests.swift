//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptStringsTests.swift
//
//  Created by Nick Kohrn on 3/7/24.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class ReceiptStringsTests: TestCase {

    private enum TestError: LocalizedError {
        case testError

        var errorDescription: String? { "An error occurred." }
    }

    func testDataObjectIdentifierNotFoundReceipt() {
        let subject = ReceiptStrings
            .data_object_identifier_not_found_receipt
        let expectedDescription = "The data object identifier couldn't be found on the receipt."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testForceRefreshingReceipt() {
        let subject = ReceiptStrings
            .force_refreshing_receipt
        let expectedDescription = "Force refreshing the receipt to get latest transactions from Apple."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testThrottlingForceRefreshingReceipt() {
        let subject = ReceiptStrings
            .throttling_force_refreshing_receipt
        let expectedDescription = "Throttled request to refresh receipt."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testLoadedReceipt() {
        let url = URL(fileURLWithPath: "/dev/null")
        let subject = ReceiptStrings
            .loaded_receipt(url: url)
        let expectedDescription = "Loaded receipt from url file:///dev/null"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testNoSandboxReceiptIntroEligibility() {
        let subject = ReceiptStrings
            .no_sandbox_receipt_intro_eligibility
        let expectedDescription = "App running on sandbox without a receipt file. " +
        "Unable to determine intro eligibility unless you've purchased " +
        "before and there is a receipt available."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testNoSandboxReceiptRestore() {
        let subject = ReceiptStrings
            .no_sandbox_receipt_restore
        let expectedDescription = "App running in sandbox without a receipt file. Restoring " +
        "transactions won't work until a purchase is made to generate a receipt. " +
        "This should not happen in production unless user is logged out of Apple account."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testParsingReceiptLocallyError() {
        let subject = ReceiptStrings
            .parse_receipt_locally_error(error: TestError.testError)
        let expectedDescription = "There was an error when trying to parse the receipt " +
        "locally, details: An error occurred."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testParsingReceiptFailed() {
        let subject = ReceiptStrings
            .parsing_receipt_failed(
                fileName: "ThisFile",
                functionName: "thisFunction()"
            )
        let expectedDescription = "ThisFile-thisFunction(): Could not parse receipt, conservatively returning true"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testParsingReceiptSuccess() {
        let subject = ReceiptStrings
            .parsing_receipt_success
        let expectedDescription = "Receipt parsed successfully"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testParsingReceipt() {
        let subject = ReceiptStrings
            .parsing_receipt
        let expectedDescription = "Parsing receipt"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testRefreshingEmptyReceipt() {
        let subject = ReceiptStrings
            .refreshing_empty_receipt
        let expectedDescription = "Receipt empty, refreshing"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testUnableToLoadReceipt() {
        let subject = ReceiptStrings
            .unable_to_load_receipt(TestError.testError)
        let expectedDescription = "Unable to load receipt, ensure you are logged in to a valid Apple account.\n" +
        "Error: testError"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testPostingReceipt() {
        let receipt = AppleReceipt(
            environment: .unknown,
            bundleId: "bundleId",
            applicationVersion: "applicationVersion",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date.distantPast,
            expirationDate: nil,
            inAppPurchases: []
        )
        let subject = ReceiptStrings
            .posting_receipt(
                receipt,
                initiationSource: "initiationSource"
            )
        let expectedDescriptionPrefix = "Posting receipt (source: 'initiationSource') " +
        "(note: the contents might not be up-to-date, " +
        "but it will be refreshed with Apple's servers):"

        // The full `debugDescription` of `AppleReceipt` is not asserted against
        // because the conformance to `CustomDebugStringConvertible` has an internal
        // implementation of `try? self.encodedJSON`, which does not print the JSON
        // deterministically.
        expect(subject.category).to(equal("receipt"))
        expect(subject.description.hasPrefix(expectedDescriptionPrefix)).to(beTrue())
    }

    func testPostingJWS() {
        let subject = ReceiptStrings
            .posting_jws(
                "JWS",
                initiationSource: "initiationSource"
            )
        let expectedDescription = "Posting JWS token (source: 'initiationSource'):\nJWS"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testPostingSK2Receipt() {
        let subject = ReceiptStrings
            .posting_sk2_receipt(
                "SK2 receipt",
                initiationSource: "initiationSource"
            )
        let expectedDescription = "Posting StoreKit 2 receipt (source: 'initiationSource'):\nSK2 receipt"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testSubscriptionPurchaseEqualsExpiration() {
        let date = Date.distantPast
        let subject = ReceiptStrings
            .receipt_subscription_purchase_equals_expiration(
                productIdentifier: "productIdentifier",
                purchase: date,
                expiration: date
            )
        let expectedDescription = "Receipt for product 'productIdentifier' has the same purchase " +
        "(0001-01-01 00:00:00 +0000) and expiration (0001-01-01 00:00:00 +0000) dates. " +
        "This is likely a StoreKit bug."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testLocalReceiptMissingPurchase() {
        let receipt = AppleReceipt(
            environment: .unknown,
            bundleId: "bundleId",
            applicationVersion: "applicationVersion",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date.distantPast,
            expirationDate: nil,
            inAppPurchases: []
        )
        let subject = ReceiptStrings
            .local_receipt_missing_purchase(
                receipt,
                forProductIdentifier: "productIdentifier"
            )
        let expectedDescriptionPrefix = "Local receipt is still missing purchase for 'productIdentifier':"

        // The full `debugDescription` of `AppleReceipt` is not asserted against
        // because the conformance to `CustomDebugStringConvertible` has an internal
        // implementation of `try? self.encodedJSON`, which does not print the JSON
        // deterministically.
        expect(subject.category).to(equal("receipt"))
        expect(subject.description.hasPrefix(expectedDescriptionPrefix)).to(beTrue())
    }

    func testRetryingReceiptFetchAfterDuration() {
        let subject = ReceiptStrings
            .retrying_receipt_fetch_after(sleepDuration: 2)
        let expectedDescription = "Retrying receipt fetch after  2 seconds"

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

    func testErrorValidatingBundleSignature() {
        let subject = ReceiptStrings
            .error_validating_bundle_signature
        let expectedDescription = "Error validating app bundle signature."

        expect(subject.category).to(equal("receipt"))
        expect(subject.description).to(equal(expectedDescription))
    }

}
