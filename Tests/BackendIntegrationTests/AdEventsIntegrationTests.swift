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
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        let loadedData = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-456"
        )

        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-321"
        )

        let revenueData = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-789",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        Purchases.shared.adTracker.trackAdFailedToLoad(failedToLoadData)
        Purchases.shared.adTracker.trackAdLoaded(loadedData)
        Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        Purchases.shared.adTracker.trackAdOpened(openedData)
        Purchases.shared.adTracker.trackAdRevenue(revenueData)

        try await waitForEventsToBeStored(5)
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
            adFormat: .interstitial,
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        Purchases.shared.adTracker.trackAdDisplayed(displayedData)

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
            adFormat: .rewarded,
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            adUnitId: "ca-app-pub-456",
            impressionId: "impression-456"
        )

        Purchases.shared.adTracker.trackAdDisplayed(displayedData)
        Purchases.shared.adTracker.trackAdOpened(openedData)

        await self.resetSingleton()

        // Simulate app will resign active to trigger flush
        self.simulateAppWillResignActive()

        try await self.logger.verifyMessageIsEventuallyLogged(
            EventsManagerStrings.ad_events_flushed_successfully,
            level: .debug,
            expectedCount: 1
        )
    }

    func testTrackingAdEventsWithDifferentFormats() async throws {
        let bannerAd = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-banner",
            impressionId: "banner-impression-123"
        )

        let interstitialAd = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "level_complete",
            adUnitId: "ca-app-pub-interstitial",
            impressionId: "interstitial-impression-456"
        )

        let rewardedAd = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "reward_screen",
            adUnitId: "ca-app-pub-rewarded",
            impressionId: "rewarded-impression-789",
            revenueMicros: 2000000,
            currency: "USD",
            precision: .exact
        )

        let nativeAd = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "feed",
            adUnitId: "ca-app-pub-native",
            impressionId: "native-impression-321"
        )

        let customFormatAd = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: AdFormat(rawValue: "custom_format"),
            placement: "custom_placement",
            adUnitId: "ca-app-pub-custom",
            impressionId: "custom-impression-654"
        )

        Purchases.shared.adTracker.trackAdDisplayed(bannerAd)
        Purchases.shared.adTracker.trackAdDisplayed(interstitialAd)
        Purchases.shared.adTracker.trackAdRevenue(rewardedAd)
        Purchases.shared.adTracker.trackAdDisplayed(nativeAd)
        Purchases.shared.adTracker.trackAdDisplayed(customFormatAd)

        try await waitForEventsToBeStored(5)
        try await flushAndVerify(eventsCount: 5)
    }

    private func waitForEventsToBeStored(_ count: Int) async throws {
        try await self.logger.verifyMessageIsEventuallyLogged(
            "Storing ad event:",
            level: .verbose,
            expectedCount: count
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
    }

    private func simulateAppWillResignActive() {
        NotificationCenter.default.post(
            name: SystemInfo.applicationWillResignActiveNotification,
            object: nil
        )
    }

}
