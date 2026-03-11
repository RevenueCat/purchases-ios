//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesCustomPaywallEventsTests.swift
//
//  Created by Rick van der Linden.

import Nimble
import StoreKit
import XCTest

@_spi(Experimental) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesCustomPaywallEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testTrackCustomPaywallImpressionWithPaywallId() async throws {
        let params = CustomPaywallImpressionParams(paywallId: "my_paywall")
        self.purchases.trackCustomPaywallImpression(params)

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.paywallId) == "my_paywall"
    }

    func testTrackCustomPaywallImpressionWithoutParams() async throws {
        self.purchases.trackCustomPaywallImpression()

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.paywallId).to(beNil())
    }

    func testTrackCustomPaywallImpressionWithNilPaywallId() async throws {
        let params = CustomPaywallImpressionParams(paywallId: nil)
        self.purchases.trackCustomPaywallImpression(params)

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.paywallId).to(beNil())
    }

}
