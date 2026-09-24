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

    func testAsksAboutTheSessionForTheCurrentCustomer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)

        _ = await self.purchases.pollHostedCheckout(operationSessionID: Self.operationSessionID)

        let parameters = try XCTUnwrap(try self.mockWebBillingAPI.invokedGetHostedCheckoutStatusParameters)
        expect(parameters.operationSessionID) == Self.operationSessionID
        expect(parameters.appUserID) == self.identityManager.currentAppUserID
    }

    /// The purchase the checkout landed is on the customer's account, not in the cache the caller is about
    /// to read, so it is fetched before the outcome is reported.
    func testFetchesCustomerInfoOnceTheCheckoutLands() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let result = await self.purchases.pollHostedCheckout(operationSessionID: Self.operationSessionID)

        expect(result) == .succeeded
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore + 1
    }

    func testDoesNotFetchCustomerInfoWhenTheCheckoutDidNotLand() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.failed(.init(code: 3, message: "payment_charge_failed")))
        let fetchesBefore = self.backend.getCustomerInfoCallCount

        let result = await self.purchases.pollHostedCheckout(operationSessionID: Self.operationSessionID)

        expect(result) == .failed(code: 3, message: "payment_charge_failed")
        expect(self.backend.getCustomerInfoCallCount) == fetchesBefore
    }

    /// A fetch that does not land does not take the purchase away from the customer.
    func testStillReportsThePurchaseWhenCustomerInfoCannotBeFetched() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))

        let result = await self.purchases.pollHostedCheckout(operationSessionID: Self.operationSessionID)

        expect(result) == .succeeded
    }

    /// The cached `CustomerInfo` predates the purchase, so it must not be served as current once the fetch
    /// meant to replace it fails.
    func testMarksTheCachedCustomerInfoStaleWhenItCannotBeFetched() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try self.stubStatus(.succeeded)
        self.backend.overrideCustomerInfoResult = .failure(.networkError(.offlineConnection()))
        let clearsBefore = self.deviceCache.clearCustomerInfoCacheTimestampCount

        _ = await self.purchases.pollHostedCheckout(operationSessionID: Self.operationSessionID)

        expect(self.deviceCache.clearCustomerInfoCacheTimestampCount) > clearsBefore
    }

}

private extension PurchasesHostedCheckoutTests {

    static let operationSessionID = "opsession_123"

    func stubStatus(_ status: HostedCheckoutStatusResponse.Status) throws {
        try self.mockWebBillingAPI.stubbedGetHostedCheckoutStatusCompletionResult = .success(.init(status: status))
    }

}
