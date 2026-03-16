//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallEventTests.swift
//
//  Created by Rick van der Linden.

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CustomPaywallEventTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    // MARK: - Event Creation

    func testEventCreationWithPaywallId() {
        let event = CustomPaywallEvent.impression(
            Self.creationData,
            .init(paywallId: "my_paywall_id", offeringId: "offering_1")
        )

        expect(event.creationData.id) == Self.creationData.id
        expect(event.creationData.date) == Self.creationData.date
        expect(event.data.paywallId) == "my_paywall_id"
        expect(event.data.offeringId) == "offering_1"
        expect(event.feature) == .customPaywalls
        expect(event.eventDiscriminator).to(beNil())
    }

    func testEventCreationWithNilPaywallId() {
        let event = CustomPaywallEvent.impression(
            Self.creationData,
            .init(paywallId: nil)
        )

        expect(event.data.paywallId).to(beNil())
        expect(event.data.offeringId).to(beNil())
        expect(event.feature) == .customPaywalls
        expect(event.eventDiscriminator).to(beNil())
    }

    // MARK: - Request Encoding

    func testRequestEncodingWithPaywallId() throws {
        let event = CustomPaywallEvent.impression(
            Self.creationData,
            .init(paywallId: "my_paywall", offeringId: "offering_1")
        )
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: Self.appSessionID,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))

        expect(requestEvent.id) == Self.creationData.id.uuidString
        expect(requestEvent.version) == 1
        expect(requestEvent.type) == "custom_paywall_impression"
        expect(requestEvent.appUserID) == Self.userID
        expect(requestEvent.appSessionID) == Self.appSessionID.uuidString
        expect(requestEvent.timestamp) == Self.creationData.date.millisecondsSince1970
        expect(requestEvent.paywallId) == "my_paywall"
        expect(requestEvent.offeringId) == "offering_1"
    }

    func testRequestEncodingWithoutPaywallId() throws {
        let event = CustomPaywallEvent.impression(Self.creationData, .init(paywallId: nil))
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: nil,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))

        expect(requestEvent.paywallId).to(beNil())
    }

    func testRequestEncodingAppSessionIdOmittedWhenNil() throws {
        let event = CustomPaywallEvent.impression(Self.creationData, .init(paywallId: "pw"))
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: nil,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))
        expect(requestEvent.appSessionID).to(beNil())

        let encoded = try JSONEncoder.default.encode(requestEvent)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        expect(json["app_session_id"]).to(beNil())
    }

    func testRequestEncodingPaywallIdOmittedWhenNil() throws {
        let event = CustomPaywallEvent.impression(Self.creationData, .init(paywallId: nil))
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: nil,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))
        let encoded = try JSONEncoder.default.encode(requestEvent)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        expect(json["paywall_id"]).to(beNil())
    }

    func testRequestEncodingOfferingIdAppearsInJSON() throws {
        let event = CustomPaywallEvent.impression(
            Self.creationData,
            .init(paywallId: "pw", offeringId: "offering_abc")
        )
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: nil,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))
        let encoded = try JSONEncoder.default.encode(requestEvent)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        expect(json["offering_id"] as? String) == "offering_abc"
    }

    func testRequestEncodingOfferingIdOmittedWhenNil() throws {
        let event = CustomPaywallEvent.impression(Self.creationData, .init(paywallId: "pw", offeringId: nil))
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: nil,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))
        let encoded = try JSONEncoder.default.encode(requestEvent)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        expect(json["offering_id"]).to(beNil())
    }

    func testRequestTypeAndVersion() throws {
        let event = CustomPaywallEvent.impression(Self.creationData, .init(paywallId: "pw"))
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: nil,
                eventDiscriminator: nil
            )
        )

        let requestEvent = try XCTUnwrap(FeatureEventsRequest.CustomPaywallEvent(storedEvent: storedEvent))

        expect(requestEvent.type) == "custom_paywall_impression"
        expect(requestEvent.version) == 1
    }

    // MARK: - StoredEvent Round-Trip

    func testCanInitFromDeserializedEvent() throws {
        let event = CustomPaywallEvent.impression(
            Self.creationData,
            .init(paywallId: "my_paywall", offeringId: "offering_round_trip")
        )
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: Self.appSessionID,
                eventDiscriminator: nil
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        expect(deserialized.userID) == Self.userID
        expect(deserialized.feature) == .customPaywalls

        let requestEvent = try XCTUnwrap(
            FeatureEventsRequest.CustomPaywallEvent(storedEvent: deserialized)
        )

        expect(requestEvent.id) == Self.creationData.id.uuidString
        expect(requestEvent.appUserID) == Self.userID
        expect(requestEvent.appSessionID) == Self.appSessionID.uuidString
        expect(requestEvent.paywallId) == "my_paywall"
        expect(requestEvent.offeringId) == "offering_round_trip"
    }

    func testTimestampPreservesMilliseconds() throws {
        let dateWithMilliseconds = Date(timeIntervalSince1970: 1694029328.890)
        let creationData = CustomPaywallEvent.CreationData(
            id: UUID(),
            date: dateWithMilliseconds
        )
        let event = CustomPaywallEvent.impression(
            creationData,
            .init(paywallId: nil)
        )
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: Self.appSessionID,
                eventDiscriminator: nil
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)
        let requestEvent = try XCTUnwrap(
            FeatureEventsRequest.CustomPaywallEvent(storedEvent: deserialized)
        )

        expect(requestEvent.timestamp) == 1_694_029_328_890
    }

    func testPreservesMillisecondsInCreationDate() throws {
        let timeIntervalWithMilliseconds: TimeInterval = 1694029328.890
        let creationData = CustomPaywallEvent.CreationData(
            id: UUID(),
            date: Date(timeIntervalSince1970: timeIntervalWithMilliseconds)
        )
        let event = CustomPaywallEvent.impression(
            creationData,
            .init(paywallId: "test")
        )
        let storedEvent = try XCTUnwrap(
            StoredFeatureEvent(
                event: event,
                userID: Self.userID,
                feature: .customPaywalls,
                appSessionID: Self.appSessionID,
                eventDiscriminator: nil
            )
        )

        let serialized = try StoredFeatureEventSerializer.encode(storedEvent)
        let deserialized = try StoredFeatureEventSerializer.decode(serialized)

        let jsonData = try XCTUnwrap(deserialized.encodedEvent.data(using: .utf8))
        let decodedEvent = try JSONDecoder.default.decode(CustomPaywallEvent.self, from: jsonData)

        expect(decodedEvent.creationData.date.timeIntervalSince1970)
            .to(equal(timeIntervalWithMilliseconds))
    }

    // MARK: - Params

    func testParamsWithPaywallId() {
        let params = CustomPaywallImpressionParams(paywallId: "my_paywall")
        expect(params.paywallId) == "my_paywall"
    }

    func testParamsDefaultPaywallIdIsNil() {
        let params = CustomPaywallImpressionParams()
        expect(params.paywallId).to(beNil())
    }

    func testParamsWithOfferingId() {
        let params = CustomPaywallImpressionParams(paywallId: "pw", offeringId: "my_offering")
        expect(params.offeringId) == "my_offering"
    }

    func testParamsDefaultOfferingIdIsNil() {
        let params = CustomPaywallImpressionParams()
        expect(params.offeringId).to(beNil())
    }

    // MARK: - Helpers

    private static let userID = "test-user"
    private static let appSessionID = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!

    private static let creationData = CustomPaywallEvent.CreationData(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

}
