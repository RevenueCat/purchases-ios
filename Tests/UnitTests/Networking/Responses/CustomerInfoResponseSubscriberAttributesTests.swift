//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoResponseSubscriberAttributesTests.swift
//
//  Created by RevenueCat on 8/12/26.

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
class CustomerInfoResponseSubscriberAttributesTests: TestCase {

    func testDecodeParsesAttributeWithValue() throws {
        let json = """
        {
          "$email": {"value": "user@example.com", "updatedAtMs": 1600000000000}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let attributes = try JSONDecoder().decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        expect(attributes.attributes).to(haveCount(1))
        let attribute = try XCTUnwrap(attributes.attributes.first)
        expect(attribute.key) == "$email"
        expect(attribute.value) == "user@example.com"
        expect(attribute.isSynced) == true
        expect(attribute.setTime) == Date(timeIntervalSince1970: 1_600_000_000)
    }

    func testDecodeTreatsNullValueAsEmptyString() throws {
        let json = """
        {
          "custom_key": {"value": null, "updatedAtMs": 1650000000000}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let attributes = try JSONDecoder().decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        let attribute = try XCTUnwrap(attributes.attributes.first)
        expect(attribute.key) == "custom_key"
        expect(attribute.value) == ""
    }

    func testDecodeParsesMultipleAttributes() throws {
        let json = """
        {
          "$email": {"value": "user@example.com", "updatedAtMs": 1600000000000},
          "$displayName": {"value": "Dave", "updatedAtMs": 1650000000000}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let attributes = try JSONDecoder().decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        expect(attributes.attributes).to(haveCount(2))
        expect(Set(attributes.attributes.map { $0.key })) == ["$email", "$displayName"]
    }

    func testDecodeEmptyObjectProducesNoAttributes() throws {
        let data = try XCTUnwrap("{}".data(using: .utf8))

        let attributes = try JSONDecoder().decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        expect(attributes.attributes).to(beEmpty())
    }

    func testDecodeThrowsWhenUpdatedAtMsIsMissing() throws {
        let json = """
        {
          "key": {"value": "value"}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        expect {
            try JSONDecoder().decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)
        }.to(throwError(errorType: DecodingError.self))
    }

    func testEncodeProducesValueAndUpdatedAtMsPerAttribute() throws {
        let setTime = Date(timeIntervalSince1970: 1_600_000_000)
        let attribute = SubscriberAttribute(withKey: "$email",
                                            value: "user@example.com",
                                            isSynced: true,
                                            setTime: setTime)
        let subscriberAttributes = CustomerInfoResponse.SubscriberAttributes(attributes: [attribute])

        let data = try JSONEncoder().encode(subscriberAttributes)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let emailEntry = try XCTUnwrap(json["$email"] as? [String: Any])
        expect(emailEntry["value"] as? String) == "user@example.com"
        expect(emailEntry["updatedAtMs"] as? Double) == 1_600_000_000_000
    }

    func testEncodeThenDecodeRoundTrips() throws {
        let attribute1 = SubscriberAttribute(withKey: "$email",
                                             value: "user@example.com",
                                             isSynced: true,
                                             setTime: Date(timeIntervalSince1970: 1_600_000_000))
        let attribute2 = SubscriberAttribute(withKey: "custom",
                                             value: "custom value",
                                             isSynced: true,
                                             setTime: Date(timeIntervalSince1970: 1_650_000_000))
        let original = CustomerInfoResponse.SubscriberAttributes(attributes: [attribute1, attribute2])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        expect(Set(decoded.attributes)) == Set(original.attributes)
    }

    func testDescriptionMatchesAttributesArrayDescription() {
        let attribute = SubscriberAttribute(withKey: "$email",
                                            value: "user@example.com",
                                            isSynced: true,
                                            setTime: Date(timeIntervalSince1970: 1_600_000_000))
        let subscriberAttributes = CustomerInfoResponse.SubscriberAttributes(attributes: [attribute])

        expect(subscriberAttributes.description) == [attribute].description
    }

    // MARK: - JSONDecoder.default / JSONEncoder.default
    //
    // These decode/encode with the same `.convertFromSnakeCase` / `.convertToSnakeCase` configured
    // decoder and encoder actually used in production (e.g. when decoding `CustomerInfoResponse`).
    // A plain `JSONDecoder()`/`JSONEncoder()` (as used by the tests above) never rewrites keys, so it
    // can't catch attribute names getting mangled by that key strategy -- these tests can.

    func testDecodeThroughProductionDecoderPreservesUnderscoredAttributeKeys() throws {
        let json = """
        {
          "custom_key": {"value": "custom value", "updated_at_ms": 1650000000000}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let attributes = try JSONDecoder.default.decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        let attribute = try XCTUnwrap(attributes.attributes.first)
        expect(attribute.key) == "custom_key"
        expect(attribute.value) == "custom value"
        expect(attribute.setTime) == Date(timeIntervalSince1970: 1_650_000_000)
    }

    func testEncodeThroughProductionEncoderPreservesUnderscoredAttributeKeys() throws {
        let attribute = SubscriberAttribute(withKey: "custom_key",
                                            value: "custom value",
                                            isSynced: true,
                                            setTime: Date(timeIntervalSince1970: 1_650_000_000))
        let subscriberAttributes = CustomerInfoResponse.SubscriberAttributes(attributes: [attribute])

        let data = try JSONEncoder.default.encode(subscriberAttributes)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let entry = try XCTUnwrap(json["custom_key"] as? [String: Any])
        expect(entry["value"] as? String) == "custom value"
        expect(entry["updated_at_ms"] as? Double) == 1_650_000_000_000
    }

    func testProductionEncodeDecodeRoundTripPreservesUnderscoredAttributeKeys() throws {
        let attribute = SubscriberAttribute(withKey: "custom_key",
                                            value: "custom value",
                                            isSynced: true,
                                            setTime: Date(timeIntervalSince1970: 1_650_000_000))
        let original = CustomerInfoResponse.SubscriberAttributes(attributes: [attribute])

        let data = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)

        expect(Set(decoded.attributes)) == Set(original.attributes)
    }

    func testProductionEncodeDecodeRoundTripPreservesCamelCaseAttributeKeys() throws {
        // A camelCase attribute name shouldn't be turned into snake_case on the way out either.
        let attribute = SubscriberAttribute(withKey: "myCustomAttribute",
                                            value: "value",
                                            isSynced: true,
                                            setTime: Date(timeIntervalSince1970: 1_650_000_000))
        let original = CustomerInfoResponse.SubscriberAttributes(attributes: [attribute])

        let data = try JSONEncoder.default.encode(original)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        expect(json.keys.contains("myCustomAttribute")) == true

        let decoded = try JSONDecoder.default.decode(CustomerInfoResponse.SubscriberAttributes.self, from: data)
        expect(decoded.attributes.first?.key) == "myCustomAttribute"
    }

}
