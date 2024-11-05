//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventSerializerTests.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallEventSerializerTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testEncodeImpressionEvent() throws {
        let originalEvent = PaywallEvent.impression(.random(), .random())
        let event: StoredEvent = try XCTUnwrap(.init(event: originalEvent,
                                                     userID: Self.userID,
                                                     feature: .paywalls))

        let encoded = try PaywallEventSerializer.encode(event)
        let decoded: StoredEvent = try PaywallEventSerializer.decode(encoded)

        expect(encoded.numberOfLines) == 1
        try verifyDecodedEvent(decoded, matches: event)
    }

    func testDecodeCancelEvent() throws {
        let originalEvent = PaywallEvent.cancel(.random(), .random())
        let event: StoredEvent = try XCTUnwrap(.init(event: originalEvent,
                                                     userID: Self.userID,
                                                     feature: .paywalls))

        let encoded = try PaywallEventSerializer.encode(event)
        let decoded: StoredEvent = try PaywallEventSerializer.decode(encoded)

        expect(encoded.numberOfLines) == 1
        try verifyDecodedEvent(decoded, matches: event)
    }

    func testDecodeCloseEvent() throws {
        let originalEvent = PaywallEvent.close(.random(), .random())
        let event: StoredEvent = try XCTUnwrap(.init(event: originalEvent,
                                                     userID: Self.userID,
                                                     feature: .paywalls))

        let encoded = try PaywallEventSerializer.encode(event)
        let decoded: StoredEvent = try PaywallEventSerializer.decode(encoded)

        expect(encoded.numberOfLines) == 1
        try verifyDecodedEvent(decoded, matches: event)
    }

    // MARK: -

    private static let userID = UUID().uuidString

    private func verifyDecodedEvent(
        _ decoded: StoredEvent,
        matches original: StoredEvent,
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        expect(file: file, line: line, decoded.userID) == original.userID
        expect(file: file, line: line, decoded.feature) == original.feature

        let eventData = try XCTUnwrap(decoded.encodedEvent.value as? [String: Any])
        do {
            let paywallEvent: PaywallEvent = try JSONDecoder.default.decode(dictionary: eventData)
            let originalEvent = try XCTUnwrap(original.encodedEvent.value as? PaywallEvent)
            expect(file: file, line: line, paywallEvent) == originalEvent
        } catch {
            XCTFail("Failed to decode PaywallEvent: \(error)")
        }
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
