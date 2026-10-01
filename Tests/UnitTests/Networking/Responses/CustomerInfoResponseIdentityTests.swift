//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoResponseIdentityTests.swift
//
//  Created by RevenueCat on 9/2/26.

import Nimble
import XCTest

@testable import RevenueCat

class CustomerInfoResponseIdentityTests: TestCase {

    private typealias Identity = CustomerInfoResponse.User.Identity

    // MARK: - Decoding known fields

    func testDecodeParsesIdAndMethod() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123", "method": "email"}
        """.data(using: .utf8))

        let identity = try JSONDecoder().decode(Identity.self, from: data)

        expect(identity.id) == "user-123"
        expect(identity.method) == "email"
    }

    func testDecodeAllowsNilId() throws {
        let data = try XCTUnwrap("""
        {"id": null, "method": "anonymous"}
        """.data(using: .utf8))

        let identity = try JSONDecoder().decode(Identity.self, from: data)

        expect(identity.id).to(beNil())
        expect(identity.method) == "anonymous"
    }

    func testDecodeThrowsWhenMethodIsMissing() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123"}
        """.data(using: .utf8))

        expect {
            try JSONDecoder().decode(Identity.self, from: data)
        }.to(throwError(errorType: DecodingError.self))
    }

    // MARK: - `rawData` preserves everything transmitted

    func testDecodeRawDataMatchesTransmittedKnownKeys() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123", "method": "email"}
        """.data(using: .utf8))

        let identity = try JSONDecoder().decode(Identity.self, from: data)

        expect(Data.encodeJSON(identity.rawData)).to(matchJSONData(data))
    }

    func testDecodeRawDataIncludesUnknownFutureKeys() throws {
        let data = try XCTUnwrap("""
        {
          "id": "user-123",
          "method": "email",
          "provider_id": "abc-999",
          "verified": true,
          "metadata": {"source": "sso"}
        }
        """.data(using: .utf8))

        let identity = try JSONDecoder().decode(Identity.self, from: data)

        // Known fields still decode correctly...
        expect(identity.id) == "user-123"
        expect(identity.method) == "email"

        // ...and every transmitted key/value (known or not) is preserved in `rawData`,
        // matching the wire representation exactly.
        expect(Data.encodeJSON(identity.rawData)).to(matchJSONData(data))
    }

    func testDecodeRawDataContainsExactlyTheTransmittedKeySet() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123", "method": "email", "created_at": 1700000000, "extra_flag": false}
        """.data(using: .utf8))

        let identity = try JSONDecoder().decode(Identity.self, from: data)

        expect(Set(identity.rawData.keys)) == ["id", "method", "created_at", "extra_flag"]
    }

    func testDecodeRawDataIsUnaffectedByKeyOrder() throws {
        let data1 = try XCTUnwrap("""
        {"id": "user-123", "method": "email", "provider_id": "abc-999", "verified": true}
        """.data(using: .utf8))
        let data2 = try XCTUnwrap("""
        {"verified": true, "method": "email", "id": "user-123", "provider_id": "abc-999"}
        """.data(using: .utf8))

        let identity1 = try JSONDecoder().decode(Identity.self, from: data1)
        let identity2 = try JSONDecoder().decode(Identity.self, from: data2)

        expect(identity1.id) == identity2.id
        expect(identity1.method) == identity2.method

        // Dictionaries are inherently unordered, so re-serializing both should
        // produce identical JSON regardless of the order keys were transmitted in.
        let encoded1 = try XCTUnwrap(Data.encodeJSON(identity1.rawData))
        let encoded2 = try XCTUnwrap(Data.encodeJSON(identity2.rawData))
        expect(encoded1) == encoded2
    }

    // MARK: - Production decoder (snake_case <-> camelCase conversion)
    //
    // `JSONDecoder.default` (used in production to decode `CustomerInfoResponse`) configures
    // `.convertFromSnakeCase`. That conversion is only applied to schema-defined `CodingKey`s
    // (like `Identity`'s `id`/`method`), not to the dynamic keys captured by `decodeRawData()`
    // into a plain `[String: Any]` -- see the similar note on `SubscriberAttributes` decoding.
    // These tests exist to catch a regression where `rawData` keys get silently mangled
    // (e.g. "provider_user_id" -> "providerUserId").

    func testDecodeThroughProductionDecoderPreservesSnakeCaseKeysInRawData() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123", "method": "email", "provider_user_id": "sso-42", "linked_at_ms": 1700000000000}
        """.data(using: .utf8))

        let identity = try JSONDecoder.default.decode(Identity.self, from: data)

        expect(identity.id) == "user-123"
        expect(identity.method) == "email"
        expect(identity.rawData["provider_user_id"] as? String) == "sso-42"
        expect(identity.rawData["linked_at_ms"] as? Int) == 1_700_000_000_000
        expect(identity.rawData["providerUserId"]).to(beNil())
        expect(Data.encodeJSON(identity.rawData)).to(matchJSONData(data))
    }

    // MARK: - Encoding

    func testEncodeWritesRawDataVerbatim() throws {
        let rawData: [String: Any] = [
            "id": "user-123",
            "method": "email",
            "future_key": "future_value"
        ]
        let identity = Identity(id: "user-123", method: "email", rawData: rawData)

        let data = try JSONEncoder().encode(identity)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(json["id"] as? String) == "user-123"
        expect(json["method"] as? String) == "email"
        expect(json["future_key"] as? String) == "future_value"
    }

    func testEncodeSerializesRawDataRatherThanTheDecodedProperties() throws {
        // `rawData` is intentionally different from `id`/`method` here to prove that
        // `encode(to:)` serializes `rawData` -- not the individually-decoded properties.
        let identity = Identity(
            id: "decoded-id",
            method: "decoded-method",
            rawData: ["id": "raw-id", "method": "raw-method"]
        )

        let data = try JSONEncoder().encode(identity)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(json["id"] as? String) == "raw-id"
        expect(json["method"] as? String) == "raw-method"
    }

    func testEncodeThenDecodeRoundTripPreservesAllKeys() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123", "method": "email", "provider_id": "abc-999", "verified": true}
        """.data(using: .utf8))
        let original = try JSONDecoder().decode(Identity.self, from: data)

        let reencoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Identity.self, from: reencoded)

        expect(decoded.id) == original.id
        expect(decoded.method) == original.method

        let originalEncoded = try XCTUnwrap(Data.encodeJSON(original.rawData))
        let decodedEncoded = try XCTUnwrap(Data.encodeJSON(decoded.rawData))
        expect(decodedEncoded) == originalEncoded
    }

    func testProductionEncodeDecodeRoundTripPreservesSnakeCaseKeys() throws {
        let data = try XCTUnwrap("""
        {"id": "user-123", "method": "email", "provider_user_id": "sso-42"}
        """.data(using: .utf8))
        let original = try JSONDecoder.default.decode(Identity.self, from: data)

        let reencoded = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(Identity.self, from: reencoded)

        expect(decoded.rawData["provider_user_id"] as? String) == "sso-42"

        let originalEncoded = try XCTUnwrap(Data.encodeJSON(original.rawData))
        let decodedEncoded = try XCTUnwrap(Data.encodeJSON(decoded.rawData))
        expect(decodedEncoded) == originalEncoded
    }

    // MARK: - Integration through `CustomerInfoResponse.User`

    func testUserIdentitiesArrayPreservesEachIdentitysRawDataIndependently() throws {
        let data = try XCTUnwrap("""
        {
          "amr": ["pwd"],
          "id": "user-123",
          "identities": [
            {"id": "user-123", "method": "email", "provider_id": "email-1"},
            {"id": null, "method": "anonymous", "session_id": "sess-1"}
          ]
        }
        """.data(using: .utf8))

        let user = try JSONDecoder().decode(CustomerInfoResponse.User.self, from: data)

        expect(user.identities).to(haveCount(2))

        let first = user.identities[0]
        expect(first.id) == "user-123"
        expect(first.method) == "email"
        expect(first.rawData["provider_id"] as? String) == "email-1"

        let second = user.identities[1]
        expect(second.id).to(beNil())
        expect(second.method) == "anonymous"
        expect(second.rawData["session_id"] as? String) == "sess-1"

        // Each identity's extra keys must not leak into any other identity's `rawData`.
        expect(first.rawData["session_id"]).to(beNil())
        expect(second.rawData["provider_id"]).to(beNil())
    }

}
