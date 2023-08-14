//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoDecodingTests.swift
//
//  Created by Nacho Soto on 4/12/22.

import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

private let dateFormatter = ISO8601DateFormatter.default

class CustomerInfoDecodingTests: BaseHTTPResponseTest {

    private static let nonSubscriptionID = "com.revenuecat.product.tip"
    private static let subscriptionID = "com.revenuecat.monthly_4.99.1_week_intro"

    private var customerInfo: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.customerInfo = try self.decodeFixture("CustomerInfo")
    }

    func testSchemaVersion() {
        expect(self.customerInfo.schemaVersion) == "4"
    }

    func testRequestDate() throws {
        expect(self.customerInfo.requestDate) == Date(timeIntervalSince1970: 1646761378)
    }

    func testSubscriberData() throws {
        let subscriber = self.customerInfo.subscriber

        expect(subscriber.firstSeen) == dateFormatter.date(from: "2022-03-08T17:42:58Z")
        expect(subscriber.managementUrl) == URL(string: "https://apps.apple.com/account/subscriptions")!
        expect(subscriber.originalAppUserId) == "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1"
        expect(subscriber.originalApplicationVersion) == "1.0"
        expect(subscriber.originalPurchaseDate) == dateFormatter.date(from: "2022-04-12T00:03:24Z")
    }

    func testNonSubscriptions() throws {
        let subscriber = self.customerInfo.subscriber

        expect(Set(subscriber.nonSubscriptions.keys)) == [Self.nonSubscriptionID]
        expect(subscriber.nonSubscriptions[Self.nonSubscriptionID]).to(haveCount(1))

        let transaction = try XCTUnwrap(subscriber.nonSubscriptions[Self.nonSubscriptionID]?.first)
        expect(transaction.purchaseDate) == dateFormatter.date(from: "2022-02-11T00:03:28Z")
        expect(transaction.originalPurchaseDate) == dateFormatter.date(from: "2022-03-10T00:04:28Z")
        expect(transaction.transactionIdentifier) == "17459f5ff7"
        expect(transaction.storeTransactionIdentifier) == "340001090153249"
        expect(transaction.store) == .appStore
        expect(transaction.isSandbox) == false
    }

    func testSubscriptions() throws {
        let subscriber = self.customerInfo.subscriber

        expect(Set(subscriber.subscriptions.keys)) == [
            Self.subscriptionID,
            "com.revenuecat.ABCDNA12U.ProductName"
        ]
        let subscription = try XCTUnwrap(subscriber.subscriptions[Self.subscriptionID])

        expect(subscription.billingIssuesDetectedAt).to(beNil())
        expect(subscription.expiresDate) == dateFormatter.date(from: "2022-04-12T00:03:35Z")
        expect(subscription.isSandbox) == true
        expect(subscription.originalPurchaseDate) == dateFormatter.date(from: "2022-04-12T00:03:28Z")
        expect(subscription.periodType) == .intro
        expect(subscription.purchaseDate) == dateFormatter.date(from: "2022-04-12T00:03:28Z")
        expect(subscription.store) == .appStore
        expect(subscription.unsubscribeDetectedAt).to(beNil())

        expect(Set(subscriber.entitlements.keys)) == ["premium", "tip"]
    }

    func testEntitlements() throws {
        let subscriber = self.customerInfo.subscriber

        let entitlement1 = try XCTUnwrap(subscriber.entitlements["premium"])
        expect(entitlement1.expiresDate) == dateFormatter.date(from: "1990-08-30T02:40:36Z")
        expect(entitlement1.productIdentifier) == Self.subscriptionID
        expect(entitlement1.purchaseDate) == dateFormatter.date(from: "1990-08-30T02:40:36Z")

        let entitlement2 = try XCTUnwrap(subscriber.entitlements["tip"])
        expect(entitlement2.expiresDate).to(beNil())
        expect(entitlement2.productIdentifier) == Self.nonSubscriptionID
        expect(entitlement2.purchaseDate) == dateFormatter.date(from: "1990-09-30T02:40:36Z")
    }

    func testEntitlementsContainAllRawData() throws {
        let entitlement = try XCTUnwrap(self.customerInfo.subscriber.entitlements["premium"])

        let futureData = try XCTUnwrap(
            entitlement.rawData["future_data"],
            "Unparsed key is not included in raw data"
        )
        let parsedData = try XCTUnwrap(
            futureData as? [String: String],
            "Data is the wrong type: \(futureData)"
        )

        expect(parsedData) == ["is_included": "in_raw_data"]
    }

    func testRawDataIsNotEncoded() throws {
        expect(try self.customerInfo.asDictionary().keys).toNot(contain("raw_data"))
    }

    func testRawDataIncludesUnparsedKeys() throws {
        let futureData = try XCTUnwrap(
            self.customerInfo.rawData["future_data"],
            "Unparsed key is not included in raw data"
        )
        let parsedData = try XCTUnwrap(
            futureData as? [String: String],
            "Data is the wrong type: \(futureData)"
        )

        expect(parsedData) == ["is_included": "in_raw_data"]
    }

    func testReencoding() {
        expect(try self.customerInfo.encodeAndDecode()) == self.customerInfo
    }

    func testFailsToDecode() {
        expect(try CustomerInfo.decode("[]")).to(throwError(ErrorCode.customerInfoError))
    }

    func testEncoding() {
        assertSnapshot(matching: self.customerInfo, as: .backwardsCompatibleFormattedJson)
    }

    func testEncodingWithVerifiedResponse() {
        assertSnapshot(matching: self.customerInfo.copy(with: .verified),
                       as: .backwardsCompatibleFormattedJson)
    }

    func testEncodingWithFailedVerificationResponse() {
        assertSnapshot(matching: self.customerInfo.copy(with: .failed),
                       as: .backwardsCompatibleFormattedJson)
    }

}

class CustomerInfoVersion2DecodingTests: BaseHTTPResponseTest {

    private var customerInfo: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.customerInfo = try self.decodeFixture("CustomerInfo-v2")
    }

    func testSchemaVersion() {
        expect(self.customerInfo.schemaVersion) == "2"
    }

    func testRequestDate() throws {
        expect(self.customerInfo.requestDate) == Date(timeIntervalSince1970: 1673555557)
    }

    func testSubscriberData() throws {
        let subscriber = self.customerInfo.subscriber

        expect(subscriber.firstSeen) == dateFormatter.date(from: "2023-01-12T20:15:09Z")
        expect(subscriber.managementUrl) == URL(string: "https://apps.apple.com/account/subscriptions")!
        expect(subscriber.originalAppUserId) == "$RCAnonymousID:8e603271a2e24df49f02f14704d8287c"
        expect(subscriber.originalApplicationVersion) == "1.0"
        expect(subscriber.originalPurchaseDate) == dateFormatter.date(from: "2013-08-01T07:00:00Z")
    }

    func testNonSubscriptions() throws {
        expect(self.customerInfo.subscriber.nonSubscriptions).to(beEmpty())
    }

    func testSubscriptions() throws {
        let subscriber = self.customerInfo.subscriber

        expect(Set(subscriber.subscriptions.keys)) == [
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.intro_test.monthly.no_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "com.revenuecat.intro_test.monthly.1_week_intro"
        ]
        let subscription = try XCTUnwrap(subscriber.subscriptions["com.revenuecat.monthly_4.99.1_week_intro"])

        expect(subscription.billingIssuesDetectedAt).to(beNil())
        expect(subscription.expiresDate) == dateFormatter.date(from: "2023-01-12T20:34:44Z")
        expect(subscription.isSandbox) == true
        expect(subscription.originalPurchaseDate) == dateFormatter.date(from: "2022-12-19T22:34:04Z")
        expect(subscription.periodType) == .normal
        expect(subscription.purchaseDate) == dateFormatter.date(from: "2023-01-12T20:29:44Z")
        expect(subscription.store) == .appStore
        expect(subscription.unsubscribeDetectedAt).to(beNil())
    }

    func testEntitlements() throws {
        let entitlements = self.customerInfo.subscriber.entitlements
        expect(Set(entitlements.keys)) == ["premium"]

        let entitlement = try XCTUnwrap(entitlements["premium"])
        expect(entitlement.expiresDate) == dateFormatter.date(from: "2023-01-12T20:34:44Z")
        expect(entitlement.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(entitlement.purchaseDate) == dateFormatter.date(from: "2023-01-12T20:29:44Z")
    }

    func testReencoding() {
        expect(try self.customerInfo.encodeAndDecode()) == self.customerInfo
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testDecodingDefaultsToEntitlementsNotValidated() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        expect(self.customerInfo.entitlements.verification) == .notRequested
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testVerificationIsEncoded() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let reencoded = try self.customerInfo.copy(with: .verified).encodeAndDecode()

        expect(reencoded.entitlements.verification) == .verified
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testFailedVerificationIsEncoded() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let reencoded = try self.customerInfo.copy(with: .failed).encodeAndDecode()

        expect(reencoded.entitlements.verification) == .failed
    }

}

class CustomerInfoInvalidDataDecodingTests: BaseHTTPResponseTest {

    func testDecodingCustomerInfoWithInvalidSubscriptionFailsToDecode() throws {
        expect {
            let _: CustomerInfo = try self.decodeFixture("CustomerInfoWithInvalidSubscription")
        }
        .to(throwError(ErrorCode.customerInfoError))
    }

}
