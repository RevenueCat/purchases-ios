//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AudienceTests.swift
//
//  Created by Facundo Menzella.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

/// Decoding tests for an audience payload, run through `JSONDecoder.default` so the key strategy the topic
/// manager uses is exercised for real.
final class AudienceTests: TestCase {

    // MARK: - Wire contract

    func testDecodesTheDocumentedExamplePayload() throws {
        let audience = try Self.decode("""
        {
          "id": "aud_1",
          "rules": {
            "in": [
              { "var": "last_seen.country" },
              ["US", "CA"]
            ]
          }
        }
        """)

        expect(audience.id) == "aud_1"
        expect(audience.rules) == #"{"in":[{"var":"last_seen.country"},["US","CA"]]}"#
    }

    func testDecodesEmptyRules() throws {
        expect(try Self.decode(#"{ "id": "aud_1", "rules": {} }"#).rules) == "{}"
    }

    func testIgnoresUnknownFields() throws {
        let audience = try Self.decode("""
        { "id": "aud_1", "created_via": "dashboard", "rules": { "==": [1, 1] } }
        """)

        expect(audience.id) == "aud_1"
        expect(audience.rules) == #"{"==":[1,1]}"#
    }

    /// `JSONDecoder.default` converts keys from snake case, which would rewrite JSON Logic operators like
    /// `missing_some` and quietly change what the predicate means.
    func testPreservesSnakeCaseKeysInsideRules() throws {
        let audience = try Self.decode("""
        { "id": "aud_1", "rules": { "missing_some": [1, ["last_seen.country"]] } }
        """)

        expect(audience.rules) == #"{"missing_some":[1,["last_seen.country"]]}"#
    }

    /// Swift dictionaries have no insertion order, so the keys are sorted to keep the output stable.
    func testEmitsRuleKeysInASortedOrder() throws {
        let audience = try Self.decode("""
        { "id": "aud_1", "rules": { "b": 2, "a": 1, "c": 3 } }
        """)

        expect(audience.rules) == #"{"a":1,"b":2,"c":3}"#
    }

    // MARK: - Suitability for the rules engine

    /// The whole point of keeping `rules` as a string is handing it to the engine, so it has to survive the
    /// engine's own parser with its value types intact. Booleans in particular must not arrive as `1`.
    func testRulesRemainParseableByTheRulesEngine() throws {
        let rules = #"{"and":[true,1,1.5,null,"s",{"var":"last_seen.country"}]}"#
        let audience = try Self.decode(#"{ "id": "aud_1", "rules": \#(rules) }"#)

        expect(try RulesEngine.Value.fromJSONString(audience.rules))
            == (try RulesEngine.Value.fromJSONString(rules))
    }

    // MARK: - Malformed payloads

    func testThrowsForAPayloadThatIsntAJSONObject() {
        expect { try Self.decode("not-json") }.to(throwError())
        expect { try Self.decode(#"["an", "array"]"#) }.to(throwError())
    }

    func testThrowsForAMissingOrNonStringId() {
        expect { try Self.decode(#"{ "rules": {} }"#) }.to(throwError())
        expect { try Self.decode(#"{ "id": 1, "rules": {} }"#) }.to(throwError())
    }

    /// A predicate is always served as a JSON object, so anything else is a payload the SDK can't evaluate
    /// and is better rejected at ingest than passed on to the engine.
    func testThrowsForRulesThatArentAJSONObject() {
        expect { try Self.decode(#"{ "id": "aud_1" }"#) }.to(throwError())

        for rules in ["null", "[]", #""rule""#, "1", "true"] {
            expect { try Self.decode(#"{ "id": "aud_1", "rules": \#(rules) }"#) }.to(throwError())
        }
    }

    // MARK: - Helpers

    private static func decode(_ json: String) throws -> Audience {
        return try JSONDecoder.default.decode(Audience.self, from: Data(json.utf8))
    }

}
