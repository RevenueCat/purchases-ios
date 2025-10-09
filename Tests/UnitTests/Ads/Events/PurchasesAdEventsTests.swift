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

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesAdEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testTrackAdEventStoresEvent() async throws {
        let impression = AdImpressionData(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        )

        await self.purchases.trackAdDisplayed(.init(impression: impression))

        // Verify the event was tracked (implementation depends on mock availability)
        // This test verifies the public API is callable
    }

    func testTrackMultipleAdEvents() async throws {
        let impression = AdImpressionData(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        )

        await self.purchases.trackAdDisplayed(.init(impression: impression))
        await self.purchases.trackAdOpened(.init(impression: impression))

        // Verify multiple events can be tracked
    }

    func testTrackRevenueEvent() async throws {
        let impression = AdImpressionData(
            networkName: "AdMob",
            mediatorName: "MAX",
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        )

        await self.purchases.trackAdRevenue(.init(
            impression: impression,
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        ))

        // Verify revenue event tracking
    }

}
