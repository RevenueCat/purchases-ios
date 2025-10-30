//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventsRequestTests.swift
//
//  Created by RevenueCat on 1/8/25.

#if ENABLE_AD_EVENTS_TRACKING

import Foundation
import Nimble
@_spi(Experimental) @testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class AdEventsRequestTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testDisplayedEvent() throws {
        let event = AdEvent.displayed(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let requestEvent: EventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testOpenedEvent() throws {
        let event = AdEvent.opened(Self.eventCreationData, Self.openedData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let requestEvent: EventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testRevenueEvent() throws {
        let event = AdEvent.revenue(Self.eventCreationData, Self.revenueData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let requestEvent: EventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCanInitFromDeserializedEvent() throws {
        let expectedUserID = "test-user"
        let adEventCreationData: AdEvent.CreationData = .init(
            id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
            date: .init(timeIntervalSince1970: 1694029328)
        )
        let adEventData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123456789",
            adInstanceId: "instance-123"
        )
        let adEvent = AdEvent.displayed(adEventCreationData, adEventData)

        let storedEvent = try XCTUnwrap(StoredEvent(event: adEvent,
                                                    userID: expectedUserID,
                                                    feature: .ads,
                                                    appSessionID: Self.appSessionID,
                                                    eventDiscriminator: nil))
        let serializedEvent = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredFeatureEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.feature) == .ads

        let requestEvent = try XCTUnwrap(EventsRequest.AdEventRequest(storedEvent: deserializedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    // MARK: -

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension AdEventsRequestTests {

    static func createStoredFeatureEvent(from event: AdEvent) throws -> StoredEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   feature: .ads,
                                   appSessionID: Self.appSessionID,
                                   eventDiscriminator: nil))
    }

    static let eventCreationData: AdEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventData: AdDisplayed = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        adInstanceId: "instance-123"
    )

    static let openedData: AdOpened = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        adInstanceId: "instance-123"
    )

    static let revenueData: AdRevenue = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        adInstanceId: "instance-123",
        revenueMicros: 1500000,
        currency: "USD",
        precision: .exact
    )

    static let userID = "test-user-id"

    static let appSessionID = UUID(uuidString: "83164C05-2BDC-4807-8918-A4105F727DEB")

}

#endif
