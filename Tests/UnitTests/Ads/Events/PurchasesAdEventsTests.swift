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

    func testTrackAdFailedToLoadStoresEvent() async throws {
        let failedData = AdFailedToLoad(
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        self.purchases.adTracker.trackAdFailedToLoad(failedData)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .failedToLoad(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.failedToLoad but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.mediatorName) == .appLovin
        expect(eventData.adFormat) == .banner
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.mediatorErrorCode?.intValue) == 3
    }

    func testTrackAdLoadedStoresEvent() async throws {
        let loadedData = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        self.purchases.adTracker.trackAdLoaded(loadedData)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .loaded(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.loaded but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.adFormat) == .interstitial
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
    }

    func testTrackAdDisplayedStoresEvent() async throws {
        let displayedData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        self.purchases.adTracker.trackAdDisplayed(displayedData)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .displayed(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.displayed but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.adFormat) == .rewarded
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
    }

    func testTrackAdOpenedStoresEvent() async throws {
        let openedData = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        self.purchases.adTracker.trackAdOpened(openedData)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .opened(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.opened but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.adFormat) == .native
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
    }

    func testTrackAdRevenueStoresEvent() async throws {
        let revenueData = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .other,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        self.purchases.adTracker.trackAdRevenue(revenueData)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .revenue(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.revenue but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .appLovin
        expect(eventData.adFormat) == .other
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
        expect(eventData.revenueMicros) == 1500000
        expect(eventData.currency) == "USD"
        expect(eventData.precision) == .exact
    }

    func testTrackAdRewardEarnedUnverifiedStoresEvent() async throws {
        let data = AdRewardEarnedUnverified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            rewardVerificationEnabled: true,
            rewardItem: "coins",
            rewardAmount: 10
        )

        self.purchases.adTracker.trackAdRewardEarnedUnverified(data)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .rewardEarnedUnverified(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.rewardEarnedUnverified but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .adMob
        expect(eventData.adFormat) == .rewarded
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
        expect(eventData.rewardVerificationEnabled) == true
        expect(eventData.rewardItem) == "coins"
        expect(eventData.rewardAmount?.intValue) == 10
    }

    func testTrackAdRewardVerifiedStoresEvent() async throws {
        let data = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .virtualCurrency(code: "GOLD", amount: 100)
        )

        self.purchases.adTracker.trackAdRewardVerified(data)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .rewardVerified(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.rewardVerified but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .adMob
        expect(eventData.adFormat) == .rewarded
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
        expect(eventData.reward.kindRawValue) == "virtual_currency"
        expect(eventData.reward.virtualCurrency?.code) == "GOLD"
        expect(eventData.reward.virtualCurrency?.amount) == 100
    }

    func testTrackAdRewardFailedToVerifyStoresEvent() async throws {
        let data = AdRewardFailedToVerify(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            failureReason: .backendError
        )

        self.purchases.adTracker.trackAdRewardFailedToVerify(data)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(1))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents

        guard case let .rewardFailedToVerify(_, eventData) = trackedEvents.first else {
            fail("Expected AdEvent.rewardFailedToVerify but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .adMob
        expect(eventData.adFormat) == .rewarded
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
        expect(eventData.failureReason) == .backendError
    }

}
