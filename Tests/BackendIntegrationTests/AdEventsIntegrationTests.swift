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
        // Simulate backgrounding to trigger flush
        self.simulateBackgroundingApp()
        // Wait for async flush to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Verify no flush happened (empty store)
        self.logger.verifyMessageWasNotLogged(
            Strings.analytics.flush_events_success,
            level: .debug
        )
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

        // Simulate backgrounding to trigger flush (flushes all events)
        self.simulateBackgroundingApp()
        // Wait for async flush to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1
        )

        // Simulate backgrounding again - should flush nothing
        self.simulateBackgroundingApp()
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Verify no additional flush happened
        self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1 // Still only 1 flush total
        )
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

        // Simulate backgrounding to trigger flush
        self.simulateBackgroundingApp()
        // Wait for async flush to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1
        )
    }

    private func flushAndVerify(eventsCount: Int) async throws {
        // Simulate backgrounding to trigger flush
        self.simulateBackgroundingApp()
        // Wait for async flush to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1
        )
    }

    private func simulateBackgroundingApp() {
        NotificationCenter.default.post(
            name: SystemInfo.applicationDidEnterBackgroundNotification,
            object: nil
        )
    }

}

#endif
