//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterFeatureEventsRequestTests.swift
//
//  Created by Cesar de la Vega on 28/11/24.

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CustomerCenterFeatureEventsRequestTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testImpressionEvent() throws {
        let event = CustomerCenterEvent.impression(Self.eventCreationData, Self.eventData)
        let eventDiscriminator: String = CustomerCenterEventDiscriminator.lifecycle.rawValue
        let storedEvent: StoredFeatureEvent = try XCTUnwrap(.init(event: event,
                                                                  userID: Self.userID,
                                                                  feature: .customerCenter,
                                                                  appSessionID: Self.appSessionID,
                                                                  eventDiscriminator: eventDiscriminator))
        let requestEvent = try XCTUnwrap(
            FeatureEventsRequest.CustomerCenterEventBaseRequest.createBase(from: storedEvent)
        )

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCanInitFromDeserializedEvent() throws {
        let expectedUserID = "test-user"
        let customerCenterEventCreationData: CustomerCenterEventCreationData = .init(
            id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
            date: .init(timeIntervalSince1970: 1694029328)
        )
        let customerCenterEventData: CustomerCenterEvent.Data = .init(
            locale: .init(identifier: "en_US"),
            darkMode: true,
            isSandbox: true,
            displayMode: .fullScreen
        )
        let customerCenterEvent = CustomerCenterEvent.impression(customerCenterEventCreationData,
                                                                 customerCenterEventData)

        let storedEvent = try XCTUnwrap(StoredFeatureEvent(event: customerCenterEvent,
                                                           userID: expectedUserID,
                                                           feature: .customerCenter,
                                                           appSessionID: Self.appSessionID,
                                                           eventDiscriminator: "impression"))
        let serializedEvent = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredFeatureEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.feature) == .customerCenter

        let requestEvent =
        try XCTUnwrap(FeatureEventsRequest.CustomerCenterEventBaseRequest.createBase(from: deserializedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCustomerCenterEventWithoutMillisecondPrecisionIsParsed() throws {
        let event = CustomerCenterEvent.impression(Self.eventCreationData, Self.eventData)
        let eventDiscriminator: String = CustomerCenterEventDiscriminator.lifecycle.rawValue
        let storedEvent: StoredFeatureEvent = try XCTUnwrap(.init(event: event,
                                                                  userID: Self.userID,
                                                                  feature: .customerCenter,
                                                                  appSessionID: Self.appSessionID,
                                                                  eventDiscriminator: eventDiscriminator))
        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let legacySerialized = serialized.replacingOccurrences(of: ".000Z", with: "Z")
        let deserialized = try StoredFeatureEventSerializer.decode(legacySerialized)

        let requestEvent = try XCTUnwrap(
            FeatureEventsRequest.CustomerCenterEventBaseRequest.createBase(from: deserialized)
        )
        let expectedTimestamp: UInt64 = 1_694_029_328_000

        expect(requestEvent.timestamp).to(equal(expectedTimestamp))
    }

    func testCustomerCenterRequestTimestampPreservesMilliseconds() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.890)
        let creationData = CustomerCenterEventCreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let event = CustomerCenterEvent.impression(creationData, Self.eventData)
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .customerCenter,
                appSessionID: UUID(),
                eventDiscriminator: CustomerCenterEventDiscriminator.lifecycle.rawValue
            )
        )
        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)
        let requestEvent = try XCTUnwrap(
            FeatureEventsRequest.CustomerCenterEventBaseRequest.createBase(from: deserialized)
        )

        expect(requestEvent.timestamp).to(equal(1_694_029_328_890))
    }

    // MARK: - Milliseconds Precision Tests

    func testCustomerCenterEventImpressionPreservesMillisecondsInCreationDate() throws {
        let timeIntervalWithMilliseconds: TimeInterval = 1694029328.890
        let creationData = CustomerCenterEventCreationData(
            id: UUID(),
            date: Date(timeIntervalSince1970: timeIntervalWithMilliseconds)
        )
        let eventData = CustomerCenterEvent.Data(
            locale: Locale(identifier: "en_US"),
            darkMode: false,
            isSandbox: true,
            displayMode: .sheet
        )
        let event = CustomerCenterEvent.impression(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .customerCenter,
                appSessionID: UUID(),
                eventDiscriminator: CustomerCenterEventDiscriminator.lifecycle.rawValue
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(CustomerCenterEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(timeIntervalWithMilliseconds))
    }

    func testCustomerCenterAnswerSubmittedEventPreservesMillisecondsInCreationDate() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.999)
        let creationData = CustomerCenterEventCreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let eventData = CustomerCenterAnswerSubmittedEvent.Data(
            locale: Locale(identifier: "en_US"),
            darkMode: false,
            isSandbox: true,
            displayMode: .sheet,
            path: .cancel,
            url: URL(string: "https://example.com"),
            surveyOptionID: "survey-123",
            additionalContext: "test context",
            revisionID: 1
        )
        let event = CustomerCenterAnswerSubmittedEvent.answerSubmitted(creationData, eventData)

        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: "test-user",
                feature: .customerCenter,
                appSessionID: UUID(),
                eventDiscriminator: CustomerCenterEventDiscriminator.answerSubmitted.rawValue
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(
            CustomerCenterAnswerSubmittedEvent.self,
            from: jsonData
        )

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(dateWithMilliseconds.timeIntervalSince1970))
    }

    // MARK: -

    private static let eventCreationData: CustomerCenterEventCreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    private static let eventData: CustomerCenterEvent.Data = .init(
        locale: .init(identifier: "es_ES"),
        darkMode: true,
        isSandbox: true,
        displayMode: .fullScreen
    )

    private static let userID = "Jack Shepard"

    private static let appSessionID = UUID(uuidString: "83164C05-2BDC-4807-8918-A4105F727DEB")

}
