//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventTests.swift
//
//  Created by RevenueCat on 1/23/26.

import Nimble
import XCTest

@_spi(Experimental) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class AdEventTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    // MARK: - AdFailedToLoad Equality

    func testAdFailedToLoadEqualityWithDifferentAdFormat() {
        let event1 = AdFailedToLoad(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        let event2 = AdFailedToLoad(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        expect(event1) != event2
    }

    func testAdFailedToLoadEqualityWithSameProperties() {
        let event1 = AdFailedToLoad(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        let event2 = AdFailedToLoad(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        expect(event1) == event2
    }

    // MARK: - AdLoaded Equality

    func testAdLoadedEqualityWithDifferentAdFormat() {
        let event1 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) != event2
    }

    func testAdLoadedEqualityWithSameProperties() {
        let event1 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) == event2
    }

    // MARK: - AdDisplayed Equality

    func testAdDisplayedEqualityWithDifferentAdFormat() {
        let event1 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) != event2
    }

    func testAdDisplayedEqualityWithSameProperties() {
        let event1 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) == event2
    }

    // MARK: - AdOpened Equality

    func testAdOpenedEqualityWithDifferentAdFormat() {
        let event1 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .appOpen,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) != event2
    }

    func testAdOpenedEqualityWithSameProperties() {
        let event1 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) == event2
    }

    // MARK: - AdRevenue Equality

    func testAdRevenueEqualityWithDifferentAdFormat() {
        let event1 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        let event2 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .mrec,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        expect(event1) != event2
    }

    func testAdRevenueEqualityWithSameProperties() {
        let event1 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .mrec,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        let event2 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .mrec,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        expect(event1) == event2
    }

}
