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
        let paywallEvent = PaywallEvent.purchaseInitiated(.init(), self.eventData)

        let transaction = try await XCTAsyncUnwrap(
            try await self.purchases.purchase(
                package: package, promotionalOffer: nil, paywallEvent: paywallEvent
            ).transaction
        )

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testPurchasingPackageWithCachedPurchaseData() async throws {
        let productId = self.package.storeProduct.productIdentifier
        try self.purchases.cachePurchaseData(
            presentedOfferingContext: self.package.presentedOfferingContext,
            paywallEvent: .purchaseInitiated(.init(), self.eventData),
            productIdentifier: productId
        )

        let transaction = try await XCTAsyncUnwrap(
            try await self.purchases.purchase(package: self.package).transaction
        )

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testPurchasingPackageAfterClearingCachedPurchaseData() async throws {
        let productId = self.package.storeProduct.productIdentifier
        try self.purchases.cachePurchaseData(
            presentedOfferingContext: self.package.presentedOfferingContext,
            paywallEvent: .purchaseInitiated(.init(), self.eventData),
            productIdentifier: productId
        )
        try self.purchases.clearCachedPurchaseData(productIdentifier: productId)

        let transaction = try await XCTAsyncUnwrap(
            try await self.purchases.purchase(package: self.package).transaction
        )

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    // MARK: - Events that do NOT cache paywall data

    func testImpressionAloneDoesNotIncludePaywallData() async throws {
        // Only tracking impression sends analytics but does NOT cache paywall data
        try await self.purchases.track(paywallEvent: .impression(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    // MARK: - Cached data persists through unrelated events

    func testCachedPurchaseDataSurvivesCloseEvent() async throws {
        let productId = self.package.storeProduct.productIdentifier
        try self.purchases.cachePurchaseData(
            presentedOfferingContext: self.package.presentedOfferingContext,
            paywallEvent: .purchaseInitiated(.init(), self.eventData),
            productIdentifier: productId
        )
        // close event (analytics only) should NOT affect the cached data
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    func testCachedPurchaseDataSurvivesExitOfferEvent() async throws {
        let productId = self.package.storeProduct.productIdentifier
        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: .dismiss,
            exitOfferingIdentifier: "exit_offer_id"
        )
        try self.purchases.cachePurchaseData(
            presentedOfferingContext: self.package.presentedOfferingContext,
            paywallEvent: .purchaseInitiated(.init(), self.eventData),
            productIdentifier: productId
        )
        // exitOffer event (analytics only) should NOT affect the cached data
        try await self.purchases.track(paywallEvent: .exitOffer(.init(), self.eventData, exitOfferData))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: self.eventData.sessionIdentifier)
    }

    @available(iOS 17.0, *)
    func testPurchasingAfterFailureAndClearingCachedDataHasNoPaywallData() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.networkError(URLError(.unknown))), forAPI: .purchase)

        let productId = self.package.storeProduct.productIdentifier
        try self.purchases.cachePurchaseData(
            presentedOfferingContext: self.package.presentedOfferingContext,
            paywallEvent: .purchaseInitiated(.init(), self.eventData),
            productIdentifier: productId
        )

        do {
            _ = try await self.purchases.purchase(package: self.package)
            fail("Expected error")
        } catch {
            // Simulate PurchaseHandler clearing the cache on error
            try self.purchases.clearCachedPurchaseData(productIdentifier: productId)
        }

        self.logger.clearMessages()

        try await self.testSession.setSimulatedError(nil, forAPI: .purchase)

        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: self.package).transaction)

        self.verifyTransactionHandled(with: transaction, sessionID: nil)
    }

    func testFlushingEmptyEvents() async throws {
        let result = try await self.purchases.flushPaywallEvents(count: 1)
        expect(result) == 0
    }

    func testFlushingEvents() async throws {
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        let result = try await self.purchases.flushPaywallEvents(count: 3)
        expect(result) == 3
    }

    func testFlushingEventsClearsThem() async throws {
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
        try await self.purchases.track(paywallEvent: .close(.init(), self.eventData))

        _ = try await self.purchases.flushPaywallEvents(count: 3)
        let result = try await self.purchases.flushPaywallEvents(count: 10)
        expect(result) == 0
    }

    func testFlushingPaywallControlInteractionEvents() async throws {
        let interaction = PaywallEvent.ControlInteractionData(
            componentType: .button,
            componentName: nil,
            componentValue: "restore_purchases"
        )
        try await self.purchases.track(
            paywallEvent: .controlInteraction(.init(), self.eventData, interaction)
        )

        let result = try await self.purchases.flushPaywallEvents(count: 1)
        expect(result) == 1
    }

    func testRemembersEventsWhenReopeningApp() async throws {
        try await self.purchases.track(paywallEvent: .cancel(.init(), self.eventData))
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
