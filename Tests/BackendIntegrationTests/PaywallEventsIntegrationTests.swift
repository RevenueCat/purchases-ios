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

    func testPurchasingPackageWithPresentedPaywall() async throws {
        let offering = try await self.currentOffering
        let paywall = try XCTUnwrap(offering.paywall)
        let package = try XCTUnwrap(offering.monthly)
        let event: PaywallEvent.Data = .init(
            offering: offering,
            paywall: paywall,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .current,
            darkMode: true
        )

        try await self.purchases.track(paywallEvent: .view(event))

        let transaction = try await XCTAsyncUnwrap(try await self.purchases.purchase(package: package).transaction)

        self.logger.verifyMessageWasLogged(
            Strings.purchase.transaction_poster_handling_transaction(
                transactionID: transaction.transactionIdentifier,
                productID: package.storeProduct.productIdentifier,
                transactionDate: transaction.purchaseDate,
                offeringID: package.offeringIdentifier,
                paywallSessionID: event.sessionIdentifier
            )
        )
    }

}
