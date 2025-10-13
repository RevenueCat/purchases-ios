//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesAdEventsTests.swift
//
//  Created by RevenueCat on 1/8/25.

#if ENABLE_AD_EVENTS_TRACKING

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesAdEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testTrackAdEventStoresEvent() async throws {
        await self.purchases.trackAdDisplayed(.init(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        ))

        let trackedEvents = await try self.mockPaywallEventsManager.trackedEvents
        expect(trackedEvents).to(haveCount(1))

        guard case let .displayed(_, displayedData) = trackedEvents[0] as? AdEvent else {
            fail("Expected AdEvent.displayed")
            return
        }

        expect(displayedData.networkName) == "AdMob"
        expect(displayedData.mediatorName) == "MAX"
        expect(displayedData.placement) == "home_screen"
        expect(displayedData.adUnitId) == "ca-app-pub-123"
        expect(displayedData.adInstanceId) == "instance-123"
    }

    func testTrackMultipleAdEvents() async throws {
        await self.purchases.trackAdDisplayed(.init(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        ))
        await self.purchases.trackAdOpened(.init(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        ))

        let trackedEvents = await try self.mockPaywallEventsManager.trackedEvents
        expect(trackedEvents).to(haveCount(2))

        guard case .displayed = trackedEvents[0] as? AdEvent else {
            fail("Expected first event to be AdEvent.displayed")
            return
        }

        guard case .opened = trackedEvents[1] as? AdEvent else {
            fail("Expected second event to be AdEvent.opened")
            return
        }
    }

    func testTrackRevenueEvent() async throws {
        await self.purchases.trackAdRevenue(.init(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        ))

        let trackedEvents = await try self.mockPaywallEventsManager.trackedEvents
        expect(trackedEvents).to(haveCount(1))

        guard case let .revenue(_, revenueData) = trackedEvents[0] as? AdEvent else {
            fail("Expected AdEvent.revenue")
            return
        }

        expect(revenueData.networkName) == "AdMob"
        expect(revenueData.mediatorName) == "MAX"
        expect(revenueData.placement) == "home_screen"
        expect(revenueData.adUnitId) == "ca-app-pub-123"
        expect(revenueData.adInstanceId) == "instance-123"
        expect(revenueData.revenueMicros) == 1500000
        expect(revenueData.currency) == "USD"
        expect(revenueData.precision) == .exact
    }

}

#endif
