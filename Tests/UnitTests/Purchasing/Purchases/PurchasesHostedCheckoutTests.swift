//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesHostedCheckoutTests.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@MainActor
final class PurchasesHostedCheckoutTests: BasePurchasesTests {

    private var mockWebBillingAPI: MockWebBillingAPI {
        get throws {
            return try XCTUnwrap(self.backend.webBilling as? MockWebBillingAPI)
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.setupPurchases()
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesHostedCheckoutTests {

    func testAsksAboutTheSessionForTheCustomerItWasCreatedFor() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))

        _ = await self.purchases.pollHostedCheckout(sessionID: Self.session(for: Self.otherAppUserID).id)

        let parameters = try XCTUnwrap(try self.mockWebBillingAPI.invokedGetHostedCheckoutStatusParameters)
        expect(parameters.operationSessionID) == Self.operationSessionID
        expect(parameters.appUserID) == Self.otherAppUserID
    }

    /// The purchase the checkout landed is on the customer's account, not in the cache the caller is about
    /// to read, so it is fetched before the outcome is reported.
    func testFetchesCustomerInfoOnceTheCheckoutLands() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let session = self.startedSession()
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let (result, _) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(result) == .succeeded(nil)
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore + 1
    }

    /// The paywall reports the purchase with it, rather than fetching it again.
    func testReturnsTheFetchedCustomerInfoOnceTheCheckoutLands() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let purchased = try Self.customerInfoWithActiveEntitlement()
        self.backend.overrideCustomerInfoResult = .success(purchased)
        let session = self.startedSession()

        let (_, customerInfo) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(customerInfo) == purchased
    }

    func testReturnsTheTransactionTheCheckoutMade() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(.init(storeTransactionIdentifier: "txn_123",
                                             productIdentifier: "monthly",
                                             purchaseDate: Date(timeIntervalSince1970: 1609459200),
                                             isSandbox: false)))
        let session = self.startedSession()

        let (result, _) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        guard case let .succeeded(transaction?) = result else {
            return XCTFail("Expected a transaction, got \(result)")
        }
        expect(transaction.transactionIdentifier) == "txn_123"
        expect(transaction.productIdentifier) == "monthly"
    }

    /// The customer got the product some other way, which the cache may not show yet.
    func testFetchesCustomerInfoWhenTheCustomerAlreadyOwnsTheProduct() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.failed(.init(code: 5, message: "product_already_purchased")))
        let session = self.startedSession()
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let (result, _) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(result) == .alreadyPurchased
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore + 1
    }

    func testDoesNotFetchCustomerInfoWhenTheCheckoutDidNotLand() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.failed(.init(code: 3, message: "payment_charge_failed")))
        let session = self.startedSession()
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let (result, customerInfo) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(result) == .failed(code: 3, message: "payment_charge_failed")
        expect(customerInfo).to(beNil())
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore
    }

    /// A fetch that does not land does not take the purchase away from the customer.
    func testStillReportsThePurchaseWhenCustomerInfoCannotBeFetched() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let session = self.startedSession()

        let (result, customerInfo) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(result) == .succeeded(nil)
        expect(customerInfo).to(beNil())
    }

    /// The cached `CustomerInfo` predates the purchase. Marking it stale is not enough, since a stale cache is
    /// still served, so it must be gone once the fetch meant to replace it fails.
    func testClearsTheCachedCustomerInfoWhenItCannotBeFetched() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let session = self.startedSession()
        self.deviceCache.cache(customerInfo: Data(), appUserID: session.id.appUserID)

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.deviceCache.cachedCustomerInfoData(appUserID: session.id.appUserID)).to(beNil())
    }

    /// The purchase is on the account of the customer who made it, not on the one who logged in meanwhile.
    func testFetchesTheBuyersCustomerInfoWhenAnotherCustomerLogsInBeforeThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let session = self.startedSession()
        self.identityManager.mockAppUserID = Self.otherAppUserID

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(try self.mockWebBillingAPI.invokedGetHostedCheckoutStatusParameters?.appUserID) == session.id.appUserID
        expect(self.backend.userID) == session.id.appUserID
    }

    func testFetchesTheBuyersCustomerInfoWhenAnotherCustomerLogsInDuringThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let session = self.startedSession()
        try self.logInWhileThePollRuns(Self.otherAppUserID)

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.backend.userID) == session.id.appUserID
    }

    /// The paywall reports the purchase with it, so it has to be the buyer's, not that of whoever is logged in.
    func testReturnsTheBuyersCustomerInfoWhenAnotherCustomerLogsInDuringThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let purchased = try Self.customerInfoWithActiveEntitlement()
        self.backend.overrideCustomerInfoResult = .success(purchased)
        let session = self.startedSession()
        try self.logInWhileThePollRuns(Self.otherAppUserID)

        let (_, customerInfo) = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.backend.userID) == session.id.appUserID
        expect(customerInfo) == purchased
    }

    func testClearsOnlyTheBuyersCachedCustomerInfoWhenAnotherCustomerLogsInDuringThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let session = self.startedSession()
        self.deviceCache.cache(customerInfo: Data(), appUserID: session.id.appUserID)
        self.deviceCache.cache(customerInfo: Data(), appUserID: Self.otherAppUserID)
        try self.logInWhileThePollRuns(Self.otherAppUserID)

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.deviceCache.cachedCustomerInfoData(appUserID: session.id.appUserID)).to(beNil())
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: Self.otherAppUserID)).toNot(beNil())
    }

    func testSendsTheLandedPurchaseToTheListeners() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let purchased = try Self.customerInfoWithActiveEntitlement()
        self.backend.overrideCustomerInfoResult = .success(purchased)
        let session = self.startedSession()

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.customerInfoManager.lastSentCustomerInfo) == purchased
        await expect(self.purchasesDelegate.customerInfo).toEventually(equal(purchased))
    }

    /// The listeners follow whoever is logged in, so the buyer's `CustomerInfo` would pass for theirs.
    func testDoesNotSendTheBuyersCustomerInfoToTheListenersWhenAnotherCustomerLogsInDuringThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let purchased = try Self.customerInfoWithActiveEntitlement()
        self.backend.overrideCustomerInfoResult = .success(purchased)
        let session = self.startedSession()
        try self.logInWhileThePollRuns(Self.otherAppUserID)

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.backend.userID) == session.id.appUserID
        expect(self.customerInfoManager.lastSentCustomerInfo) != purchased
    }

    func testKeepsTheFetchedCustomerInfo() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded(nil))
        let session = self.startedSession()
        let clearsBefore = self.deviceCache.invokedClearCustomerInfoCacheCount

        _ = await self.purchases.pollHostedCheckout(sessionID: session.id)

        expect(self.deviceCache.invokedClearCustomerInfoCacheCount) == clearsBefore
    }

}

private extension PurchasesHostedCheckoutTests {

    static let operationSessionID = "opsession_123"
    static let otherAppUserID = "another_customer"

    static func session(for appUserID: String) -> HostedCheckoutSession {
        return .init(operationSessionID: Self.operationSessionID,
                     appUserID: appUserID,
                     checkoutURL: URL(string: "https://pay.example.com/session")!,
                     successURL: URL(string: "https://api.revenuecat.com/checkout-return?status=success")!)
    }

    static func customerInfoWithActiveEntitlement() throws -> CustomerInfo {
        let expirationDate = ISO8601DateFormatter.default.string(from: Date().addingTimeInterval(60 * 60))

        return try CustomerInfo(data: [
            "request_date": ISO8601DateFormatter.default.string(from: Date()),
            "subscriber": [
                "original_app_user_id": BasePurchasesTests.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [
                    "monthly": [
                        "expires_date": expirationDate,
                        "purchase_date": "2026-09-28T10:00:00Z",
                        "store": "rc_billing"
                    ] as [String: Any]
                ],
                "non_subscriptions": [:] as [String: Any],
                "entitlements": [
                    "pro": [
                        "product_identifier": "monthly",
                        "expires_date": expirationDate,
                        "purchase_date": "2026-09-28T10:00:00Z"
                    ] as [String: Any]
                ]
            ] as [String: Any]
        ])
    }

    /// A session as the checkout creates it, for whoever is logged in when it starts.
    func startedSession() -> HostedCheckoutSession {
        return Self.session(for: self.identityManager.currentAppUserID)
    }

    func stubStatus(_ status: HostedCheckoutStatusResponse.Status) throws {
        try self.mockWebBillingAPI.stubbedGetHostedCheckoutStatusCompletionResult = .success(.init(status: status))
    }

    func logInWhileThePollRuns(_ appUserID: String) throws {
        let identityManager: MockIdentityManager = self.identityManager
        try self.mockWebBillingAPI.whileGettingHostedCheckoutStatus = { identityManager.mockAppUserID = appUserID }
    }

}
