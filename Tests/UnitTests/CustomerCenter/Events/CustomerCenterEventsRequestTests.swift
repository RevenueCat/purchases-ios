//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEventsRequestTests.swift
//
//  Created by Cesar de la Vega on 28/11/24.

import Foundation
import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CustomerCenterEventsRequestTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testImpressionEvent() throws {
        let event = CustomerCenterEvent.impression(Self.eventCreationData, Self.eventData)
        let storedEvent: StoredEvent = try XCTUnwrap(.init(event: event,
                                                           userID: Self.userID,
                                                           feature: .customerCenter,
                                                           appSessionID: UUID()))
        let requestEvent: EventsRequest.CustomerCenterEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCloseEvent() throws {
        let event = CustomerCenterEvent.close(Self.eventCreationData, Self.eventData)
        let storedEvent: StoredEvent = try XCTUnwrap(.init(event: event,
                                                           userID: Self.userID,
                                                           feature: .customerCenter,
                                                           appSessionID: UUID()))
        let requestEvent: EventsRequest.CustomerCenterEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testSurveyCompletedEvent() throws {
        let event = CustomerCenterEvent.surveyCompleted(Self.eventCreationData, Self.eventData)
        let storedEvent: StoredEvent = try XCTUnwrap(.init(event: event,
                                                           userID: Self.userID,
                                                           feature: .customerCenter,
                                                           appSessionID: UUID()))
        let requestEvent: EventsRequest.CustomerCenterEvent = try XCTUnwrap(.init(storedEvent: storedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCanInitFromDeserializedEvent() throws {
        let expectedUserID = "test-user"
        let customerCenterEventCreationData: CustomerCenterEvent.CreationData = .init(
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

        let storedEvent = try XCTUnwrap(StoredEvent(event: customerCenterEvent,
                                                    userID: expectedUserID,
                                                    feature: .customerCenter,
                                                    appSessionID: UUID()))
        let serializedEvent = try StoredEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.feature) == .customerCenter

        let requestEvent = try XCTUnwrap(EventsRequest.CustomerCenterEvent(storedEvent: deserializedEvent))

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    // MARK: -

    private static let eventCreationData: CustomerCenterEvent.CreationData = .init(
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
}
