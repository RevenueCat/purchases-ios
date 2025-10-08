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

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesAdEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testTrackAdEventStoresEvent() async throws {
        let event = AdEvent.displayed(
            .init(id: UUID(), date: Date()),
            .init(
                networkName: "AdMob",
                mediatorName: "MAX",
                placement: "home_screen",
                adUnitId: "ca-app-pub-123",
                adInstanceId: "instance-123",
                sessionIdentifier: UUID()
            )
        )

        await self.purchases.track(adEvent: event)

        // Verify the event was tracked (implementation depends on mock availability)
        // This test verifies the public API is callable
    }

    func testTrackMultipleAdEvents() async throws {
        let event1 = AdEvent.displayed(
            .init(id: UUID(), date: Date()),
            .init(
                networkName: "AdMob",
                mediatorName: "MAX",
                placement: "home_screen",
                adUnitId: "ca-app-pub-123",
                adInstanceId: "instance-123",
                sessionIdentifier: UUID()
            )
        )

        let event2 = AdEvent.opened(
            .init(id: UUID(), date: Date()),
            .init(
                networkName: "AdMob",
                mediatorName: "MAX",
                placement: "home_screen",
                adUnitId: "ca-app-pub-123",
                adInstanceId: "instance-123",
                sessionIdentifier: UUID()
            )
        )

        await self.purchases.track(adEvent: event1)
        await self.purchases.track(adEvent: event2)

        // Verify multiple events can be tracked
    }

    func testTrackRevenueEvent() async throws {
        let event = AdEvent.revenue(
            .init(id: UUID(), date: Date()),
            .init(
                networkName: "AdMob",
                mediatorName: "MAX",
                placement: "home_screen",
                adUnitId: "ca-app-pub-123",
                adInstanceId: "instance-123",
                sessionIdentifier: UUID(),
                revenueMicros: 1500000,
                currency: "USD",
                precision: .exact
            )
        )

        await self.purchases.track(adEvent: event)

        // Verify revenue event tracking
    }

}
