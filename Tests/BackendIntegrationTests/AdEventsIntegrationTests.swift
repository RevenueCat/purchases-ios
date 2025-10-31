//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventsIntegrationTests.swift
//
//  Created by RevenueCat.

#if ENABLE_AD_EVENTS_TRACKING

import Nimble
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@_spi(Internal) @_spi(Experimental) @testable import RevenueCat_CustomEntitlementComputation
#else
@_spi(Internal) @_spi(Experimental) @testable import RevenueCat
#endif

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
final class AdEventsIntegrationTests: BaseBackendIntegrationTests {

    func testTrackingAndFlushingAdEvents() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-123"
        )

        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-456"
        )

        let revenueData = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-789",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdOpened(openedData)
        await Purchases.shared.adTracker.trackAdRevenue(revenueData)

        try await flushAndVerify(eventsCount: 3)
    }

    func testFlushingEmptyAdEvents() async throws {
        let result = try await Purchases.shared.flushAdEvents(count: 1)
        expect(result) == 0
    }

    func testFlushingAdEventsClearsThem() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-123"
        )

        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)

        let result1 = try await Purchases.shared.flushAdEvents(count: 10)
        expect(result1) == 3

        let result2 = try await Purchases.shared.flushAdEvents(count: 10)
        expect(result2) == 0
    }

    func testRemembersAdEventsWhenReopeningApp() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adUnitId: "ca-app-pub-123",
            impressionId: "instance-123"
        )

        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adUnitId: "ca-app-pub-456",
            impressionId: "instance-456"
        )

        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdOpened(openedData)

        await self.resetSingleton()

        let result = try await Purchases.shared.flushAdEvents(count: 10)
        expect(result) == 2
    }

    private func flushAndVerify(eventsCount: Int) async throws {
        let result = try await Purchases.shared.flushAdEvents(count: eventsCount)
        expect(result) == eventsCount

        self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1
        )
    }

}

#endif
