//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsIntegrationTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

import Nimble
@testable import RevenueCat
import XCTest

class PaywallEventsIntegrationTests: BaseStoreKitIntegrationTests {

    private var offering: Offering!
    private var package: Package!
    private var paywall: PaywallData!
    private var eventData: PaywallEvent.Data!

    override func setUp() async throws {
        try await super.setUp()

        self.offering = try await XCTAsyncUnwrap(try await self.currentOffering)
        self.package = try XCTUnwrap(self.offering.monthly)
        self.paywall = try XCTUnwrap(self.offering.paywall)

        self.eventData = .init(
            offering: self.offering,
            paywall: self.paywall,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .current,
            darkMode: true
        )
    }

    func testPurchasingPackageWithPresentedPaywall() async throws {
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testPurchasingPackageAfterClearingPresentedPaywall() async throws {
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    func testPurchasingAfterAFailureRemembersPresentedPaywall() async throws {
        self.testSession.failTransactionsEnabled = true
        self.testSession.failureError = .unknown

        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))

        do {
            _ = try await self.purchases.purchase(package: self.package)
            fail("Expected error")
        } catch {
            // Expected error
        }

        self.logger.clearMessages()

        self.testSession.failTransactionsEnabled = false
        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testFlushingEmptyEvents() async throws {
        let result = try await self.purchases.flushPaywallEvents(count: 1)
        expect(result) == 0
    }

    func testFlushingEvents() async throws {
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        let result = try await self.purchases.flushPaywallEvents(count: 3)
        expect(result) == 3
    }

    func testFlushingEventsClearsThem() async throws {
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        _ = try await self.purchases.flushPaywallEvents(count: 3)
        let result = try await self.purchases.flushPaywallEvents(count: 10)
        expect(result) == 0
    }

    func testRemembersEventsWhenReopeningApp() async throws {
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        await self.resetSingleton()

        let result = try await self.purchases.flushPaywallEvents(count: 10)
        expect(result) == 2
    }

}

private extension PaywallEventsIntegrationTests {

    func verifyTransactionHandled(
        with transaction: StoreTransaction,
        sessionID: PaywallEvent.SessionID?
    ) {
        self.logger.verifyMessageWasLogged(
            Strings.purchase.transaction_poster_handling_transaction(
                transactionID: transaction.transactionIdentifier,
                productID: self.package.storeProduct.productIdentifier,
                transactionDate: transaction.purchaseDate,
                offeringID: self.package.offeringIdentifier,
                paywallSessionID: sessionID
            )
        )
    }

}
