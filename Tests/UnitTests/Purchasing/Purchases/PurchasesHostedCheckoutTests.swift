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
        try self.stubStatus(.succeeded)

        _ = await self.purchases.pollHostedCheckout(session: Self.session(for: Self.otherAppUserID))

        let parameters = try XCTUnwrap(try self.mockWebBillingAPI.invokedGetHostedCheckoutStatusParameters)
        expect(parameters.operationSessionID) == Self.operationSessionID
        expect(parameters.appUserID) == Self.otherAppUserID
    }

    /// The purchase the checkout landed is on the customer's account, not in the cache the caller is about
    /// to read, so it is fetched before the outcome is reported.
    func testFetchesCustomerInfoOnceTheCheckoutLands() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        let session = self.startedSession()
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let result = await self.purchases.pollHostedCheckout(session: session)

        expect(result) == .succeeded
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore + 1
    }

    /// The customer got the product some other way, which the cache may not show yet.
    func testFetchesCustomerInfoWhenTheCustomerAlreadyOwnsTheProduct() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.failed(.init(code: 5, message: "product_already_purchased")))
        let session = self.startedSession()
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let result = await self.purchases.pollHostedCheckout(session: session)

        expect(result) == .alreadyPurchased
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore + 1
    }

    func testDoesNotFetchCustomerInfoWhenTheCheckoutDidNotLand() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.failed(.init(code: 3, message: "payment_charge_failed")))
        let session = self.startedSession()
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let result = await self.purchases.pollHostedCheckout(session: session)

        expect(result) == .failed(code: 3, message: "payment_charge_failed")
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore
    }

    /// A fetch that does not land does not take the purchase away from the customer.
    func testStillReportsThePurchaseWhenCustomerInfoCannotBeFetched() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let session = self.startedSession()

        let result = await self.purchases.pollHostedCheckout(session: session)

        expect(result) == .succeeded
    }

    /// The cached `CustomerInfo` predates the purchase. Marking it stale is not enough, since a stale cache is
    /// still served, so it must be gone once the fetch meant to replace it fails.
    func testClearsTheCachedCustomerInfoWhenItCannotBeFetched() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let session = self.startedSession()
        self.deviceCache.cache(customerInfo: Data(), appUserID: session.appUserID)

        _ = await self.purchases.pollHostedCheckout(session: session)

        expect(self.deviceCache.cachedCustomerInfoData(appUserID: session.appUserID)).to(beNil())
    }

    /// The purchase is on the account of the customer who made it, not on the one who logged in meanwhile.
    func testFetchesTheBuyersCustomerInfoWhenAnotherCustomerLogsInBeforeThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        let session = self.startedSession()
        self.identityManager.mockAppUserID = Self.otherAppUserID

        _ = await self.purchases.pollHostedCheckout(session: session)

        expect(try self.mockWebBillingAPI.invokedGetHostedCheckoutStatusParameters?.appUserID) == session.appUserID
        expect(self.backend.userID) == session.appUserID
    }

    func testFetchesTheBuyersCustomerInfoWhenAnotherCustomerLogsInDuringThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        let session = self.startedSession()
        try self.logInWhileThePollRuns(Self.otherAppUserID)

        _ = await self.purchases.pollHostedCheckout(session: session)

        expect(self.backend.userID) == session.appUserID
    }

    func testClearsOnlyTheBuyersCachedCustomerInfoWhenAnotherCustomerLogsInDuringThePoll() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let session = self.startedSession()
        self.deviceCache.cache(customerInfo: Data(), appUserID: session.appUserID)
        self.deviceCache.cache(customerInfo: Data(), appUserID: Self.otherAppUserID)
        try self.logInWhileThePollRuns(Self.otherAppUserID)

        _ = await self.purchases.pollHostedCheckout(session: session)

        expect(self.deviceCache.cachedCustomerInfoData(appUserID: session.appUserID)).to(beNil())
        expect(self.deviceCache.cachedCustomerInfoData(appUserID: Self.otherAppUserID)).toNot(beNil())
    }

    func testKeepsTheFetchedCustomerInfo() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        let session = self.startedSession()
        let clearsBefore = self.deviceCache.invokedClearCustomerInfoCacheCount

        _ = await self.purchases.pollHostedCheckout(session: session)

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
                     successURL: URL(string: "https://api.revenuecat.com/checkout-return?status=success")!,
                     cancelURL: URL(string: "https://api.revenuecat.com/checkout-return?status=cancel")!)
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
