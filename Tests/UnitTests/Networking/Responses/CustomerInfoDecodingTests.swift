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

class CustomerInfoDecodingTests: BaseHTTPResponseTest {

    private static let dateFormatter = ISO8601DateFormatter()

    private var customerInfo: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.customerInfo = try self.decodeFixture("CustomerInfo")
    }

    func testSchemaVersion() {
        expect(self.customerInfo.schemaVersion) == "4"
    }

    func testResponseDataIsCorrect() throws {
        expect(self.customerInfo.requestDate) == Date(timeIntervalSince1970: 1646761378)

        let subscriber = self.customerInfo.subscriber
        expect(subscriber.firstSeen) == Self.dateFormatter.date(from: "2022-03-08T17:42:58Z")
        expect(subscriber.managementUrl) == URL(string: "https://apps.apple.com/account/subscriptions")!
        expect(subscriber.originalAppUserId) == "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1"
        expect(subscriber.originalApplicationVersion) == "1.0"
        expect(subscriber.originalPurchaseDate) == Self.dateFormatter.date(from: "2022-04-12T00:03:24Z")

        let nonSubscriptionID = "com.revenuecat.product.tip"

        expect(Set(subscriber.nonSubscriptions.keys)) == [nonSubscriptionID]
        expect(subscriber.nonSubscriptions[nonSubscriptionID]).to(haveCount(1))

        let transaction = try XCTUnwrap(subscriber.nonSubscriptions[nonSubscriptionID]?.first)
        expect(transaction.purchaseDate) == Self.dateFormatter.date(from: "2022-02-11T00:03:28Z")
        expect(transaction.originalPurchaseDate) == Self.dateFormatter.date(from: "2022-03-10T00:04:28Z")
        expect(transaction.transactionIdentifier) == "17459f5ff7"
        expect(transaction.store) == .appStore
        expect(transaction.isSandbox) == false

        let subscriptionID = "com.revenuecat.monthly_4.99.1_week_intro"

        expect(Set(subscriber.subscriptions.keys)) == [subscriptionID]
        let subscription = try XCTUnwrap(subscriber.subscriptions[subscriptionID])

        expect(subscription.billingIssuesDetectedAt).to(beNil())
        expect(subscription.expiresDate) == Self.dateFormatter.date(from: "2022-04-12T00:03:35Z")
        expect(subscription.isSandbox) == true
        expect(subscription.originalPurchaseDate) == Self.dateFormatter.date(from: "2022-04-12T00:03:28Z")
        expect(subscription.periodType) == .intro
        expect(subscription.purchaseDate) == Self.dateFormatter.date(from: "2022-04-12T00:03:28Z")
        expect(subscription.store) == .appStore
        expect(subscription.unsubscribeDetectedAt).to(beNil())

        expect(Set(subscriber.entitlements.keys)) == ["premium", "tip"]

        let entitlement1 = try XCTUnwrap(subscriber.entitlements["premium"])
        expect(entitlement1.expiresDate) == Self.dateFormatter.date(from: "1990-08-30T02:40:36Z")
        expect(entitlement1.productIdentifier) == subscriptionID
        expect(entitlement1.purchaseDate) == Self.dateFormatter.date(from: "1990-08-30T02:40:36Z")

        let entitlement2 = try XCTUnwrap(subscriber.entitlements["tip"])
        expect(entitlement2.expiresDate).to(beNil())
        expect(entitlement2.productIdentifier) == nonSubscriptionID
        expect(entitlement2.purchaseDate) == Self.dateFormatter.date(from: "1990-09-30T02:40:36Z")
    }

    func testReencoding() {
        expect(try self.customerInfo.encodeAndDecode()) == self.customerInfo
    }

    func testFailsToDecode() {
        expect(try CustomerInfo.decode("[]")).to(throwError(ErrorCode.customerInfoError))
    }

    func testEncoding() {
        assertSnapshot(matching: self.customerInfo, as: .formattedJson)
    }

}
