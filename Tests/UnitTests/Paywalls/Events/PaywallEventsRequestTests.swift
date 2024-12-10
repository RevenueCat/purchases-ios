//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsRequestTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallEventsRequestTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testImpressionEvent() throws {
        let event = PaywallEvent.impression(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredEvent(from: event)
        let requestEvent: EventsRequest.PaywallEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCancelEvent() throws {
        let event = PaywallEvent.cancel(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredEvent(from: event)
        let requestEvent: EventsRequest.PaywallEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCloseEvent() throws {
        let event = PaywallEvent.close(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredEvent(from: event)
        let requestEvent: EventsRequest.PaywallEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCanInitFromDeserializedEvent() throws {
        let expectedUserID = "test-user"
        let paywallEventCreationData: PaywallEvent.CreationData = .init(
            id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
            date: .init(timeIntervalSince1970: 1694029328)
        )
        let paywallEventData: PaywallEvent.Data = .init(
            offeringIdentifier: "offeringIdentifier",
            paywallRevision: 0,
            sessionID: .init(uuidString: "73616D70-6C65-2073-7472-696E67000000")!,
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: true
        )
        let paywallEvent = PaywallEvent.impression(paywallEventCreationData, paywallEventData)

        let storedEvent = try XCTUnwrap(StoredEvent(event: paywallEvent,
                                                    userID: expectedUserID,
                                                    feature: .paywalls,
                                                    appSessionID: Self.appSessionID,
                                                    eventDiscriminator: "impression"))
        let serializedEvent = try StoredEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.feature) == .paywalls

        let requestEvent = try XCTUnwrap(EventsRequest.PaywallEvent(storedEvent: deserializedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    // MARK: -

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEventsRequestTests {

    static func createStoredEvent(from event: PaywallEvent) throws -> StoredEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   feature: .paywalls,
                                   appSessionID: Self.appSessionID,
                                   eventDiscriminator: "impression"))
    }

    static let eventCreationData: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventData: PaywallEvent.Data = .init(
        offeringIdentifier: "offering",
        paywallRevision: 0,
        sessionID: .init(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "es_ES",
        darkMode: true
    )

    static let userID = "Jack Shepard"

    static let appSessionID = UUID(uuidString: "83164C05-2BDC-4807-8918-A4105F727DEB")

}
