//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdFeatureEventsRequestTests.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation
import Nimble
@_spi(Experimental) @testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class AdFeatureEventsRequestTests: TestCase {
    // Uncomment these lines to manually record snapshots:
//    override func setUp() async throws {
//        isRecording = true
//    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testFailedToLoadEvent() throws {
        let event = AdEvent.failedToLoad(Self.eventCreationData, Self.failedToLoadData)
        let storedEvent = try Self.createStoredAdEvent(from: event)
        let requestEvent: AdEventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testLoadedEvent() throws {
        let event = AdEvent.loaded(Self.eventCreationData, Self.loadedData)
        let storedEvent = try Self.createStoredAdEvent(from: event)
        let requestEvent: AdEventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testDisplayedEvent() throws {
        let event = AdEvent.displayed(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredAdEvent(from: event)
        let requestEvent: AdEventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testOpenedEvent() throws {
        let event = AdEvent.opened(Self.eventCreationData, Self.openedData)
        let storedEvent = try Self.createStoredAdEvent(from: event)
        let requestEvent: AdEventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testRevenueEvent() throws {
        let event = AdEvent.revenue(Self.eventCreationData, Self.revenueData)
        let storedEvent = try Self.createStoredAdEvent(from: event)
        let requestEvent: AdEventsRequest.AdEventRequest = try XCTUnwrap(.init(storedEvent: storedEvent))

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
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123456789",
            impressionId: "impression-123"
        )
        let adEvent = AdEvent.displayed(adEventCreationData, adEventData)

        let storedEvent = try XCTUnwrap(StoredAdEvent(event: adEvent,
                                                      userID: expectedUserID,
                                                      appSessionID: Self.appSessionID))
        let serializedEvent = try StoredAdEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredAdEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.appSessionID) == Self.appSessionID

        let requestEvent = try XCTUnwrap(AdEventsRequest.AdEventRequest(storedEvent: deserializedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testAdEventWithoutMillisecondPrecisionIsParsed() throws {
        let event = AdEvent.displayed(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredAdEvent(from: event)
        let serialized = try StoredAdEventSerializer.encode(storedEvent)
        let legacySerialized = serialized.replacingOccurrences(of: ".000Z", with: "Z")
        let deserialized = try StoredAdEventSerializer.decode(legacySerialized)

        let requestEvent = try XCTUnwrap(AdEventsRequest.AdEventRequest(storedEvent: deserialized))
        let expectedTimestamp: UInt64 = 1_694_029_328_000

        expect(requestEvent.timestamp).to(equal(expectedTimestamp))
    }

    func testAdRequestTimestampPreservesMilliseconds() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.123)
        let creationData = AdEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let event = AdEvent.displayed(creationData, Self.eventData)
        let storedEvent = try XCTUnwrap(
            StoredAdEvent(
                event: event,
                userID: "test-user",
                appSessionID: UUID()
            )
        )
        let serialized = try StoredAdEventSerializer.encode(storedEvent)
        let deserialized = try StoredAdEventSerializer.decode(serialized)
        let requestEvent = try XCTUnwrap(AdEventsRequest.AdEventRequest(storedEvent: deserialized))

        expect(requestEvent.timestamp).to(equal(1_694_029_328_123))
    }

    // MARK: - Milliseconds Precision Tests

    func testAdEventPreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.123)
        let creationData = AdEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )
        let event = AdEvent.displayed(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredAdEvent(
                event: event,
                userID: "test-user",
                appSessionID: UUID()
            )
        )

        let serialized = try StoredAdEventSerializer.encode(storedEvent)
        let deserialized = try StoredAdEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(AdEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    func testAdEventRevenuePreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.456)
        let creationData = AdEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-456",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )
        let event = AdEvent.revenue(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredAdEvent(
                event: event,
                userID: "test-user",
                appSessionID: UUID()
            )
        )

        let serialized = try StoredAdEventSerializer.encode(storedEvent)
        let deserialized = try StoredAdEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(AdEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    func testAdEventFailedToLoadPreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.789)
        let creationData = AdEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = AdFailedToLoad(
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )
        let event = AdEvent.failedToLoad(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredAdEvent(
                event: event,
                userID: "test-user",
                appSessionID: UUID()
            )
        )

        let serialized = try StoredAdEventSerializer.encode(storedEvent)
        let deserialized = try StoredAdEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(AdEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    // MARK: -

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension AdFeatureEventsRequestTests {

    static func createStoredAdEvent(from event: AdEvent) throws -> StoredAdEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   appSessionID: Self.appSessionID))
    }

    static let eventCreationData: AdEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let failedToLoadData: AdFailedToLoad = .init(
        mediatorName: .appLovin,
        adFormat: .banner,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        mediatorErrorCode: 3
    )

    static let loadedData: AdLoaded = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        adFormat: .interstitial,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        impressionId: "impression-123"
    )

    static let eventData: AdDisplayed = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        adFormat: .rewarded,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        impressionId: "impression-123"
    )

    static let openedData: AdOpened = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        adFormat: .native,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        impressionId: "impression-123"
    )

    static let revenueData: AdRevenue = .init(
        networkName: "AdMob",
        mediatorName: .appLovin,
        adFormat: .mrec,
        placement: "home_screen",
        adUnitId: "ca-app-pub-123456789",
        impressionId: "impression-123",
        revenueMicros: 1500000,
        currency: "USD",
        precision: .exact
    )

    static let userID = "test-user-id"

    static let appSessionID = UUID(uuidString: "83164C05-2BDC-4807-8918-A4105F727DEB")!

}
