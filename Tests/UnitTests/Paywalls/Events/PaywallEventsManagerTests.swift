//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsManagerTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
import Nimble

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallEventsManagerTests: TestCase {

    private var api: MockInternalAPI!
    private var userProvider: MockCurrentUserProvider!
    private var store: MockPaywallEventStore!
    private var manager: PaywallEventsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.api = .init()
        self.userProvider = .init(mockAppUserID: Self.userID)
        self.store = .init()
        self.manager = .init(
            internalAPI: self.api,
            userProvider: self.userProvider,
            store: self.store
        )
    }

    func testTrackEvent() async {
        let event: PaywallEvent = .view(.random())

        await self.manager.track(paywallEvent: event)

        let events = await self.store.storedEvents
        expect(events) == [
            .init(event: event, userID: Self.userID)
        ]
    }

    // MARK: -

    private static let userID = "nacho"

}

// MARK: -

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockPaywallEventStore: PaywallEventStoreType {

    var storedEvents: [PaywallStoredEvent] = []

    func store(_ storedEvent: PaywallStoredEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [PaywallStoredEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(count)
    }

}
