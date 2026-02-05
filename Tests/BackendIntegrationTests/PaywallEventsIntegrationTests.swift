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
@_spi(Internal) @testable import RevenueCat
import XCTest

class PaywallEventsIntegrationTests: BaseStoreKitIntegrationTests {

    private var offering: Offering!
    private var package: Package!
    private var paywall: PaywallData!
    private var eventData: PaywallEvent.Data!

    override func setUp() async throws {
        try await super.setUp()

        self.offering = try await XCTAsyncUnwrap(try await self.offeringWithV1Paywall)
        self.package = try XCTUnwrap(self.offering.monthly)
        self.paywall = try XCTUnwrap(self.offering.paywall)

        self.eventData = .init(
            offering: self.offering,
            paywall: self.paywall,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .current,
            darkMode: true
        ).withPurchaseInfo(packageId: self.package.identifier,
                           productId: self.package.storeProduct.productIdentifier,
                           errorCode: nil,
                           errorMessage: nil)
    }

    func testPurchasingPackageWithPurchaseInitiatedPaywall() async throws {
        try await self.purchases.track(paywallEvent: .purchaseInitiated(
            .init(),
            self.eventData,
            self.package.presentedOfferingContext
        ))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testPurchasingPackageAfterCancelClearsPurchaseInitiatedPaywall() async throws {
        try await self.purchases.track(paywallEvent: .purchaseInitiated(
            .init(),
            self.eventData,
            self.package.presentedOfferingContext
        ))
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    func testPurchasingPackageAfterPurchaseErrorClearsPurchaseInitiatedPaywall() async throws {
        let errorData = self.eventData.withPurchaseInfo(
            packageId: self.package.identifier,
            productId: self.package.storeProduct.productIdentifier,
            errorCode: 123,
            errorMessage: "Test error"
        )
        try await self.purchases.track(paywallEvent: .purchaseInitiated(
            .init(),
            self.eventData,
            self.package.presentedOfferingContext
        ))
        try await self.purchases.track(paywallEvent: .purchaseError(.init(), errorData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    // MARK: - Events that do NOT cache paywall data

    func testImpressionAloneDoesNotIncludePaywallData() async throws {
        // Only tracking impression should NOT include paywall data
        // (paywall data is only cached on purchaseInitiated)
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    // MARK: - Events that do NOT clear the cache

    func testCloseDoesNotClearPurchaseInitiatedPaywall() async throws {
        // close event should NOT clear the purchaseInitiated cache
        try await self.purchases.track(paywallEvent: .purchaseInitiated(
            .init(),
            self.eventData,
            self.package.presentedOfferingContext
        ))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        // Paywall data should still be included because close doesn't clear the cache
        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testExitOfferDoesNotClearPurchaseInitiatedPaywall() async throws {
        // exitOffer event should NOT clear the purchaseInitiated cache
        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: .dismiss,
            exitOfferingIdentifier: "exit_offer_id"
        )
        try await self.purchases.track(paywallEvent: .purchaseInitiated(
            .init(),
            self.eventData,
            self.package.presentedOfferingContext
        ))
        try await self.purchases.track(paywallEvent: .exitOffer(.init(), self.eventData, exitOfferData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        // Paywall data should still be included because exitOffer doesn't clear the cache
        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    @available(iOS 17.0, *)
    func testPurchasingAfterAFailureAndPurchaseErrorEventClearsPaywallData() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.networkError(URLError(.unknown))), forAPI: .purchase)

        try await self.purchases.track(paywallEvent: .purchaseInitiated(
            .init(),
            self.eventData,
            self.package.presentedOfferingContext
        ))

        do {
            _ = try await self.purchases.purchase(package: self.package)
            fail("Expected error")
        } catch {
            // Expected error - track purchaseError to clear the cache (as PurchaseHandler would do)
            let errorData = self.eventData.withPurchaseInfo(
                packageId: self.package.identifier,
                productId: self.package.storeProduct.productIdentifier,
                errorCode: (error as NSError).code,
                errorMessage: error.localizedDescription
            )
            try await self.purchases.track(paywallEvent: .purchaseError(.init(), errorData))
        }

        self.logger.clearMessages()

        try await self.testSession.setSimulatedError(nil, forAPI: .purchase)

        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil) // No paywall session id included
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
                offeringID: self.package.presentedOfferingContext.offeringIdentifier,
                placementID: self.package.presentedOfferingContext.placementIdentifier,
                paywallSessionID: sessionID
            )
        )
    }

}
