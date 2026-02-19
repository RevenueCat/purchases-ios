//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFeatureEventsRequestTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallFeatureEventsRequestTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testImpressionEvent() throws {
        let event = PaywallEvent.impression(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let requestEvent: FeatureEventsRequest.PaywallEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCancelEvent() throws {
        let event = PaywallEvent.cancel(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let requestEvent: FeatureEventsRequest.PaywallEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCloseEvent() throws {
        let event = PaywallEvent.close(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let requestEvent: FeatureEventsRequest.PaywallEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCanInitFromDeserializedEvent() throws {
        let expectedUserID = "test-user"
        let paywallEventCreationData: PaywallEvent.CreationData = .init(
            id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
            date: .init(timeIntervalSince1970: 1694029328)
        )
        let paywallEventData: PaywallEvent.Data = .init(
            paywallIdentifier: "test_paywall_id",
            offeringIdentifier: "offeringIdentifier",
            paywallRevision: 0,
            sessionID: .init(uuidString: "73616D70-6C65-2073-7472-696E67000000")!,
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: true
        )
        let paywallEvent = PaywallEvent.impression(paywallEventCreationData, paywallEventData)

        let storedEvent = try XCTUnwrap(StoredFeatureEvent(event: paywallEvent,
                                                           userID: expectedUserID,
                                                           feature: .paywalls,
                                                           appSessionID: Self.appSessionID,
                                                           eventDiscriminator: "impression"))
        let serializedEvent = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredFeatureEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.feature) == .paywalls

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.PaywallEvent(storedEvent: deserializedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testPaywallEventWithoutMillisecondPrecisionIsParsed() throws {
        let event = PaywallEvent.impression(Self.eventCreationData, Self.eventData)
        let storedEvent = try Self.createStoredFeatureEvent(from: event)
        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let legacySerialized = serialized.replacingOccurrences(of: ".000Z", with: "Z")
        let deserialized = try StoredFeatureEventSerializer.decode(legacySerialized)

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.PaywallEvent(storedEvent: deserialized))
        let expectedTimestamp: UInt64 = 1_694_029_328_000

        expect(requestEvent.timestamp).to(equal(expectedTimestamp))
    }

    func testPaywallRequestTimestampPreservesMilliseconds() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.234)
        let creationData = PaywallEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let event = PaywallEvent.impression(creationData, Self.eventData)
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .paywalls,
                appSessionID: UUID(),
                eventDiscriminator: nil
            )
        )
        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)
        let requestEvent = try XCTUnwrap(FeatureEventsRequest.PaywallEvent(storedEvent: deserialized))

        expect(requestEvent.timestamp).to(equal(1_694_029_328_234))
    }

    // MARK: - Milliseconds Precision Tests

    func testPaywallEventImpressionPreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.234)
        let creationData = PaywallEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = PaywallEvent.Data(
            paywallIdentifier: "test_paywall",
            offeringIdentifier: "offering_1",
            paywallRevision: 5,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )
        let event = PaywallEvent.impression(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .paywalls,
                appSessionID: UUID(),
                eventDiscriminator: nil
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(PaywallEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    func testPaywallEventClosePreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.567)
        let creationData = PaywallEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = PaywallEvent.Data(
            paywallIdentifier: "test_paywall",
            offeringIdentifier: "offering_1",
            paywallRevision: 5,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )
        let event = PaywallEvent.close(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .paywalls,
                appSessionID: UUID(),
                eventDiscriminator: nil
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(PaywallEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    func testPaywallEventCancelPreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.891)
        let creationData = PaywallEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = PaywallEvent.Data(
            paywallIdentifier: "test_paywall",
            offeringIdentifier: "offering_1",
            paywallRevision: 5,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )
        let event = PaywallEvent.cancel(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .paywalls,
                appSessionID: UUID(),
                eventDiscriminator: nil
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(PaywallEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    // MARK: -

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallFeatureEventsRequestTests {

    static func createStoredFeatureEvent(from event: PaywallEvent) throws -> StoredFeatureEvent {
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
        paywallIdentifier: "test_paywall_id",
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
