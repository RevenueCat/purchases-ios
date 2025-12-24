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
        let failedToLoadData = AdFailedToLoad(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        let loadedData = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-456"
        )

        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-321"
        )

        let revenueData = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-789",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        await Purchases.shared.adTracker.trackAdFailedToLoad(failedToLoadData)
        await Purchases.shared.adTracker.trackAdLoaded(loadedData)
        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdOpened(openedData)
        await Purchases.shared.adTracker.trackAdRevenue(revenueData)

        try await flushAndVerify(eventsCount: 5)
    }

    func testFlushingEmptyAdEvents() async throws {
        // Simulate app will resign active to trigger flush
        self.simulateAppWillResignActive()

        try await self.logger.verifyMessageIsEventuallyLogged(
            EventsManagerStrings.ad_event_flush_with_empty_store,
            level: .verbose
        )

        // Verify no flush happened (empty store)
        self.logger.verifyMessageWasNotLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            allowNoMessages: true
        )
    }

    func testFlushingAdEventsClearsThem() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)

        // Simulate app will resign active to trigger flush
        self.simulateAppWillResignActive()

        try await self.logger.verifyMessageIsEventuallyLogged(
            EventsManagerStrings.ad_events_flushed_successfully,
            level: .debug,
            expectedCount: 1
        )

        self.logger.clearMessages()

        // Simulate app will resign active to trigger flush
        self.simulateAppWillResignActive()

        try await self.logger.verifyMessageIsEventuallyLogged(
            EventsManagerStrings.ad_event_flush_with_empty_store,
            level: .verbose
        )

        // Verify no additional flush happened
        self.logger.verifyMessageWasNotLogged(EventsManagerStrings.ad_events_flushed_successfully)
    }

    func testRemembersAdEventsWhenReopeningApp() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adUnitId: "ca-app-pub-456",
            impressionId: "impression-456"
        )

        await Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        await Purchases.shared.adTracker.trackAdOpened(openedData)

        await self.resetSingleton()

        // Simulate app will resign active to trigger flush
        self.simulateAppWillResignActive()

        try await self.logger.verifyMessageIsEventuallyLogged(
            EventsManagerStrings.ad_events_flushed_successfully,
            level: .debug,
            expectedCount: 1
        )
    }

    private func flushAndVerify(eventsCount: Int) async throws {
        // Simulate app will resign active to trigger flush
        self.simulateAppWillResignActive()

        try await self.logger.verifyMessageIsEventuallyLogged(
            EventsManagerStrings.ad_events_flushed_successfully,
            level: .debug
        )

        self.logger.verifyMessageWasLogged(
            EventsManagerStrings.ad_event_flush_starting(eventsCount),
            level: .verbose
        )
//
//        self.logger.verifyMessageWasLogged(
//            Strings.analytics.flush_events_success,
//            level: .debug,
//            expectedCount: 1
//        )
    }

    private func simulateAppWillResignActive() {
        NotificationCenter.default.post(
            name: SystemInfo.applicationWillResignActiveNotification,
            object: nil
        )
    }

}
