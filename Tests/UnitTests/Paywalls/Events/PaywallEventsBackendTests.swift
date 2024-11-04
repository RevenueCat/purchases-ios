//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsBackendTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class BackendPaywallEventTests: BaseBackendTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostPaywallEventsWithNoEventsMakesNoRequests() {
        let error = waitUntilValue { completion in
            self.internalAPI.postPaywallEvents(events: [], completion: completion)
        }

        expect(error).to(beNil())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testPostPaywallEventsWithOneEvent() throws {
        let event = PaywallEvent.impression(Self.eventCreation1, Self.eventData1)
        let storedEvent: StoredEvent = try XCTUnwrap(.init(event: event,
                                                           userID: Self.userID,
                                                           feature: .paywalls))

        let error = waitUntilValue { completion in
            self.internalAPI.postPaywallEvents(events: [storedEvent], completion: completion)
        }

        expect(error).to(beNil())
    }

    func testPostPaywallEventsWithMultipleEvents() throws {
        let event1 = PaywallEvent.impression(Self.eventCreation1, Self.eventData1)
        let storedEvent1: StoredEvent = try XCTUnwrap(.init(event: event1,
                                                            userID: Self.userID,
                                                            feature: .paywalls))
        let event2 = PaywallEvent.close(Self.eventCreation2, Self.eventData2)
        let storedEvent2: StoredEvent =  try XCTUnwrap(.init(event: event2,
                                                             userID: Self.userID,
                                                             feature: .paywalls))

        let error = waitUntilValue { completion in
            self.internalAPI.postPaywallEvents(events: [storedEvent1, storedEvent2],
                                               completion: completion)
        }

        expect(error).to(beNil())
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BackendPaywallEventTests {

    static let eventCreation1: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventCreation2: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "25B68D80-68D8-461C-8C68-1A8591190A88")!,
        date: .init(timeIntervalSince1970: 1694022321)
    )

    static let eventData1: PaywallEvent.Data = .init(
        offeringIdentifier: "offering_1",
        paywallRevision: 5,
        sessionID: .init(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "es_ES",
        darkMode: true
    )

    static let eventData2: PaywallEvent.Data = .init(
        offeringIdentifier: "offering_2",
        paywallRevision: 3,
        sessionID: .init(uuidString: "10CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "en_US",
        darkMode: false
    )

}
