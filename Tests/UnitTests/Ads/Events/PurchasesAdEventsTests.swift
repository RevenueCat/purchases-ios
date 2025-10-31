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

@_spi(Experimental) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesAdEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testTrackAdDisplayedStoresEvent() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-123"
        )

        await self.purchases.adTracker.trackAdDisplayed(displayedData)

        let trackedEvents = try await self.mockEventsManager.trackedEvents

        expect(trackedEvents).to(haveCount(1))

        guard case let .displayed(_, eventData) = trackedEvents.first as? AdEvent else {
            fail("Expected AdEvent.displayed but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "instance-123"
    }

    func testTrackAdOpenedStoresEvent() async throws {
        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-123"
        )

        await self.purchases.adTracker.trackAdOpened(openedData)

        let trackedEvents = try await self.mockEventsManager.trackedEvents

        expect(trackedEvents).to(haveCount(1))

        guard case let .opened(_, eventData) = trackedEvents.first as? AdEvent else {
            fail("Expected AdEvent.opened but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "instance-123"
    }

    func testTrackAdRevenueStoresEvent() async throws {
        let revenueData = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        await self.purchases.adTracker.trackAdRevenue(revenueData)

        let trackedEvents = try await self.mockEventsManager.trackedEvents

        expect(trackedEvents).to(haveCount(1))

        guard case let .revenue(_, eventData) = trackedEvents.first as? AdEvent else {
            fail("Expected AdEvent.revenue but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "instance-123"
        expect(eventData.revenueMicros) == 1500000
        expect(eventData.currency) == "USD"
        expect(eventData.precision) == .exact
    }

}

#endif
