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

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallEventsRequestTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testImpressionEvent() throws {
        let event: PaywallStoredEvent = .init(event: .impression(Self.eventCreationData,
                                                                 Self.eventData), userID: Self.userID)
        let requestEvent: PaywallEventsRequest.Event = .init(storedEvent: event)

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCancelEvent() throws {
        let event: PaywallStoredEvent = .init(event: .cancel(Self.eventCreationData,
                                                             Self.eventData), userID: Self.userID)
        let requestEvent: PaywallEventsRequest.Event = .init(storedEvent: event)

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    func testCloseEvent() throws {
        let event: PaywallStoredEvent = .init(event: .close(Self.eventCreationData,
                                                            Self.eventData), userID: Self.userID)
        let requestEvent: PaywallEventsRequest.Event = .init(storedEvent: event)

        assertSnapshot(matching: requestEvent, as: .formattedJson)
    }

    // MARK: -

    private static let eventCreationData: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    private static let eventData: PaywallEvent.Data = .init(
        offeringIdentifier: "offering",
        paywallRevision: 5,
        sessionID: .init(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .condensedFooter,
        localeIdentifier: "es_ES",
        darkMode: true
    )

    private static let userID = "Jack Shepard"

}
