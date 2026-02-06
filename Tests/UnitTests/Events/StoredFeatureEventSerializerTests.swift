//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoredFeatureEventSerializerTests.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoredFeatureEventSerializerTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testEncodeImpressionEvent() throws {
        let originalEvent = PaywallEvent.impression(.random(), .random())
        let event = try Self.createStoredFeatureEvent(from: originalEvent)
        expect(try event.encodeAndDecode()) == event
    }

    func testDecodeCancelEvent() throws {
        let originalEvent = PaywallEvent.cancel(.random(), .random())
        let event = try Self.createStoredFeatureEvent(from: originalEvent)

        expect(try event.encodeAndDecode()) == event
    }

    func testDecodeCloseEvent() throws {
        let originalEvent = PaywallEvent.close(.random(), .random())
        let event = try Self.createStoredFeatureEvent(from: originalEvent)

        expect(try event.encodeAndDecode()) == event
    }

    func testEncodingBooleans() throws {
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

        let storedEvent = try Self.createStoredFeatureEvent(from: paywallEvent, expectedUserID: expectedUserID)
        let serializedEvent = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserializedEvent = try StoredFeatureEventSerializer.decode(serializedEvent)
        expect(deserializedEvent.userID) == expectedUserID
        expect(deserializedEvent.feature) == .paywalls

        let jsonData = try XCTUnwrap(storedEvent.encodedEvent.data(using: .utf8))
        let decodedPaywallEvent = try JSONDecoder.default.decode(PaywallEvent.self, from: jsonData)
        expect(decodedPaywallEvent) == paywallEvent
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoredFeatureEventSerializerTests {

    static let userID = UUID().uuidString

    static func createStoredFeatureEvent(
        from event: PaywallEvent,
        expectedUserID: String = userID
    ) throws -> StoredFeatureEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: expectedUserID,
                                   feature: .paywalls,
                                   appSessionID: UUID(),
                                   eventDiscriminator: "impression"))
    }

}

// MARK: - Extensions

private extension String {

    var numberOfLines: Int {
        return self.split(separator: "\n").count
    }

}

extension Date {

    /// - Returns: a Date with no milliseconds so it can be compared after being serialized.
    var removingMilliseconds: Self {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: self
        )

        return calendar.date(from: components) ?? self
    }

}
