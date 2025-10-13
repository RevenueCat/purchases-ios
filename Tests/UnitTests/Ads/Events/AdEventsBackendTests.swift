//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventsBackendTests.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class BackendAdEventTests: BaseBackendTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostAdEventsWithNoEventsMakesNoRequests() {
        let error = waitUntilValue { completion in
            self.internalAPI.postAdEvents(events: [], completion: completion)
        }

        expect(error).to(beNil())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testPostAdEventsWithOneEvent() throws {
        let event = AdEvent.displayed(Self.eventCreation1, Self.eventData1)
        let storedEvent: StoredEvent = try Self.createStoredEvent(from: event)

        let error = waitUntilValue { completion in
            self.internalAPI.postAdEvents(events: [storedEvent], completion: completion)
        }

        expect(error).to(beNil())
    }

    func testPostAdEventsWithMultipleEvents() throws {
        let event1 = AdEvent.displayed(Self.eventCreation1, Self.eventData1)
        let storedEvent1: StoredEvent = try Self.createStoredEvent(from: event1, appSessionID: Self.appSessionID1)
        let event2 = AdEvent.opened(Self.eventCreation2, Self.openedData2)
        let storedEvent2: StoredEvent = try Self.createStoredEvent(from: event2, appSessionID: Self.appSessionID2)

        let error = waitUntilValue { completion in
            self.internalAPI.postAdEvents(events: [storedEvent1, storedEvent2],
                                          completion: completion)
        }

        expect(error).to(beNil())
    }

    func testPostAdEventsWithRevenueEvent() throws {
        let event = AdEvent.revenue(Self.eventCreation1, Self.revenueData1)
        let storedEvent: StoredEvent = try Self.createStoredEvent(from: event)

        let error = waitUntilValue { completion in
            self.internalAPI.postAdEvents(events: [storedEvent], completion: completion)
        }

        expect(error).to(beNil())
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BackendAdEventTests {

    static let eventCreation1: AdEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventCreation2: AdEvent.CreationData = .init(
        id: .init(uuidString: "25B68D80-68D8-461C-8C68-1A8591190A88")!,
        date: .init(timeIntervalSince1970: 1694022321)
    )

    static let eventData1: AdDisplayed = .init(
        networkName: "AdMob",
        mediatorName: "MAX",
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        adInstanceId: "instance-123"
    )

    static let eventData2: AdDisplayed = .init(
        networkName: "AppLovin",
        mediatorName: "MAX",
        placement: "game_over",
        adUnitId: "ca-app-pub-987654321",
        adInstanceId: "instance-456"
    )

    static let openedData2: AdOpened = .init(
        networkName: "AppLovin",
        mediatorName: "MAX",
        placement: "game_over",
        adUnitId: "ca-app-pub-987654321",
        adInstanceId: "instance-456"
    )

    static let revenueData1: AdRevenue = .init(
        networkName: "AdMob",
        mediatorName: "MAX",
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        adInstanceId: "instance-123",
        revenueMicros: 1500000,
        currency: "USD",
        precision: .exact
    )

    static let appSessionID1 = UUID(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!
    static let appSessionID2 = UUID(uuidString: "10CC0F1D-7665-4093-9624-1D7308FFF4DB")!

    static func createStoredEvent(from event: AdEvent, appSessionID: UUID = appSessionID1) throws -> StoredEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   feature: .ads,
                                   appSessionID: appSessionID,
                                   eventDiscriminator: nil))
    }

}
