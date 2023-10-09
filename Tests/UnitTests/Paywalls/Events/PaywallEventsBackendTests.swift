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

    func testPostPaywallEventsWithOneEvent() {
        let event: PaywallStoredEvent = .init(event: .impression(Self.event1), userID: Self.userID)

        let error = waitUntilValue { completion in
            self.internalAPI.postPaywallEvents(events: [event], completion: completion)
        }

        expect(error).to(beNil())
    }

    func testPostPaywallEventsWithMultipleEvents() {
        let event1: PaywallStoredEvent = .init(event: .impression(Self.event1), userID: Self.userID)
        let event2: PaywallStoredEvent = .init(event: .close(Self.event2), userID: Self.userID)

        let error = waitUntilValue { completion in
            self.internalAPI.postPaywallEvents(events: [event1, event2],
                                               completion: completion)
        }

        expect(error).to(beNil())
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BackendPaywallEventTests {

    static let event1: PaywallEvent.Data = .init(
        offeringIdentifier: "offering_1",
        paywallRevision: 5,
        sessionID: .init(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "es_ES",
        darkMode: true,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let event2: PaywallEvent.Data = .init(
        offeringIdentifier: "offering_2",
        paywallRevision: 3,
        sessionID: .init(uuidString: "10CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "en_US",
        darkMode: false,
        date: .init(timeIntervalSince1970: 1694022321)
    )

}
