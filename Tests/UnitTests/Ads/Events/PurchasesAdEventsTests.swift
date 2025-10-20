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

    func testTrackAdDisplayedDoesNotCrash() async throws {
        await self.purchases.adTracker.trackAdDisplayed(.init(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        ))
    }

    func testTrackAdOpenedDoesNotCrash() async throws {
        await self.purchases.adTracker.trackAdOpened(.init(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123"
        ))
    }

    func testTrackAdRevenueDoesNotCrash() async throws {
        await self.purchases.adTracker.trackAdRevenue(.init(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            adInstanceId: "instance-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        ))
    }

}

#endif
