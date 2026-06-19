//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentStateTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

private let minimalStackJSON = """
{
    "type": "stack",
    "dimension": {
        "type": "vertical",
        "alignment": "center",
        "distribution": "start"
    },
    "size": {
        "width": { "type": "fill" },
        "height": { "type": "fill" }
    },
    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
    "components": []
}
"""

// MARK: - StateDeclaration and top-level state map decoding

final class StateDeclarationDecodingTests: TestCase {

    func testDecodeBooleanStateDeclaration() throws {
        let declaration = try decodeDeclaration("""
        {"type": "boolean", "default": false}
        """)
        expect(declaration.type).to(equal(PaywallComponent.StateDeclaration.ValueType.boolean))
        expect(declaration.defaultValue).to(equal(.bool(false)))
    }

    func testDecodeIntegerStateDeclaration() throws {
        let declaration = try decodeDeclaration("""
        {"type": "integer", "default": 0}
        """)
        expect(declaration.type).to(equal(PaywallComponent.StateDeclaration.ValueType.integer))
        expect(declaration.defaultValue).to(equal(.int(0)))
    }

    func testDecodeDoubleStateDeclaration() throws {
        let declaration = try decodeDeclaration("""
        {"type": "double", "default": 0.5}
        """)
        expect(declaration.type).to(equal(PaywallComponent.StateDeclaration.ValueType.double))
        expect(declaration.defaultValue).to(equal(.double(0.5)))
    }

    func testDecodeStringStateDeclaration() throws {
        let declaration = try decodeDeclaration("""
        {"type": "string", "default": "billing"}
        """)
        expect(declaration.type).to(equal(PaywallComponent.StateDeclaration.ValueType.string))
        expect(declaration.defaultValue).to(equal(.string("billing")))
    }

    func testDecodeStateDeclarationIgnoresUnknownFields() throws {
        let declaration = try decodeDeclaration("""
        {"type": "string", "default": "billing", "future_field": 1}
        """)
        expect(declaration.defaultValue).to(equal(.string("billing")))
    }

    func testDoubleTypedDeclarationNormalizesIntegralDefault() throws {
        // A double-typed key whose default was authored as `0` decodes as an int literal.
        let declaration = try decodeDeclaration("""
        {"type": "double", "default": 1}
        """)
        expect(declaration.defaultValue).to(equal(.int(1)))
        expect(declaration.normalizedDefaultValue).to(equal(.double(1)))
    }

    // MARK: Top-level state map on PaywallComponentsData

    func testDecodePaywallComponentsDataWithStateMap() throws {
        let data = try decodeComponentsData(state: """
        {
            "planComparisonOpen": {"type": "boolean", "default": false},
            "activeSlide": {"type": "integer", "default": 0},
            "discountMultiplier": {"type": "double", "default": 0.5},
            "selectedFeatureTab": {"type": "string", "default": "billing"}
        }
        """)

        let state = try XCTUnwrap(data.stateDeclarations)
        expect(state).to(haveCount(4))
        expect(state["planComparisonOpen"]?.defaultValue).to(equal(.bool(false)))
        expect(state["activeSlide"]?.defaultValue).to(equal(.int(0)))
        expect(state["discountMultiplier"]?.defaultValue).to(equal(.double(0.5)))
        expect(state["selectedFeatureTab"]?.defaultValue).to(equal(.string("billing")))
    }

    func testDecodePaywallComponentsDataWithoutStateMap() throws {
        let data = try decodeComponentsData(state: nil)

        expect(data.stateDeclarations).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testMalformedStateEntryIsDroppedWithoutFailingThePaywall() throws {
        let data = try decodeComponentsData(state: """
        {
            "valid": {"type": "boolean", "default": true},
            "missingDefault": {"type": "boolean"},
            "invalidDefault": {"type": "string", "default": [1, 2]}
        }
        """)

        let state = try XCTUnwrap(data.stateDeclarations)
        expect(state).to(haveCount(1))
        expect(state["valid"]?.defaultValue).to(equal(.bool(true)))
        expect(data.errorInfo).to(beNil())
    }

    func testMalformedStateMapIsIgnoredWithoutFailingThePaywall() throws {
        let data = try decodeComponentsData(state: """
        "not_an_object"
        """)

        expect(data.stateDeclarations).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testEmptyStateMapIsNormalizedToNil() throws {
        let data = try decodeComponentsData(state: "{}")

        expect(data.stateDeclarations).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testStateMapWhoseEntriesAllFailIsNormalizedToNil() throws {
        let data = try decodeComponentsData(state: """
        {
            "missingDefault": {"type": "boolean"},
            "invalidDefault": {"type": "string", "default": [1, 2]}
        }
        """)

        expect(data.stateDeclarations).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testPaywallComponentsDataStateRoundTrip() throws {
        let original = try decodeComponentsData(state: """
        {"selectedFeatureTab": {"type": "string", "default": "billing"}}
        """)

        let encoded = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(PaywallComponentsData.self, from: encoded)

        expect(decoded.stateDeclarations).to(equal(original.stateDeclarations))
    }

    // MARK: Helpers

    private func decodeDeclaration(_ json: String) throws -> PaywallComponent.StateDeclaration {
        return try JSONDecoder.default.decode(
            PaywallComponent.StateDeclaration.self,
            from: json.data(using: .utf8)!
        )
    }

    private func decodeComponentsData(state: String?) throws -> PaywallComponentsData {
        let stateField = state.map { ",\n\"stateDeclarations\": \($0)" } ?? ""
        let json = """
        {
            "template_name": "components",
            "asset_base_url": "https://assets.revenuecat.com",
            "components_config": {
                "base": {
                    "stack": \(minimalStackJSON),
                    "background": {
                        "type": "color",
                        "value": { "light": { "type": "hex", "value": "#ffffff" } }
                    }
                }
            },
            "components_localizations": { "en_US": {} },
            "default_locale": "en_US",
            "revision": 1\(stateField)
        }
        """
        return try JSONDecoder.default.decode(PaywallComponentsData.self, from: json.data(using: .utf8)!)
    }

}

// MARK: - StateUpdate decoding

final class StateUpdateDecodingTests: TestCase {

    typealias StateUpdate = PaywallComponent.StateUpdate

    // MARK: set operation

    func testDecodeSetWithStringLiteral() throws {
        let update = try decodeStateUpdate("""
        {"set": "selectedFeatureTab", "to": "billing"}
        """)
        expect(update).to(equal(.set(key: "selectedFeatureTab", value: .literal(.string("billing")))))
    }

    func testDecodeSetWithIntegerLiteral() throws {
        let update = try decodeStateUpdate("""
        {"set": "activeSlide", "to": 2}
        """)
        expect(update).to(equal(.set(key: "activeSlide", value: .literal(.int(2)))))
    }

    func testDecodeSetWithDoubleLiteral() throws {
        let update = try decodeStateUpdate("""
        {"set": "discountMultiplier", "to": 0.5}
        """)
        expect(update).to(equal(.set(key: "discountMultiplier", value: .literal(.double(0.5)))))
    }

    func testDecodeSetWithBooleanLiteral() throws {
        let update = try decodeStateUpdate("""
        {"set": "planComparisonOpen", "to": true}
        """)
        expect(update).to(equal(.set(key: "planComparisonOpen", value: .literal(.bool(true)))))
    }

    func testDecodeSetWithPayloadReference() throws {
        let update = try decodeStateUpdate("""
        {"set": "activeSlide", "to": "$value"}
        """)
        expect(update).to(equal(.set(key: "activeSlide", value: .payloadReference)))
    }

    func testDecodeIgnoresUnknownFields() throws {
        let update = try decodeStateUpdate("""
        {"set": "planComparisonOpen", "to": true, "future_field": 1}
        """)
        expect(update).to(equal(.set(key: "planComparisonOpen", value: .literal(.bool(true)))))
    }

    // MARK: unsupported / resilience

    func testDecodeUnknownOperationIsUnsupported() throws {
        // A future operation (e.g. `toggle`) carries no `set`/`to` keys.
        let update = try decodeStateUpdate("""
        {"toggle": "planComparisonOpen"}
        """)
        expect(update).to(equal(.unsupported))
    }

    func testDecodeSetWithoutValueIsUnsupported() throws {
        let update = try decodeStateUpdate("""
        {"set": "planComparisonOpen"}
        """)
        expect(update).to(equal(.unsupported))
    }

    func testDecodeNonObjectEntryIsUnsupported() throws {
        // Regression: a non-object entry has no keyed container and must degrade to `.unsupported`
        // rather than throwing and failing the enclosing component's decode.
        expect(try self.decodeStateUpdate("\"not_an_object\"")).to(equal(.unsupported))
        expect(try self.decodeStateUpdate("42")).to(equal(.unsupported))
        expect(try self.decodeStateUpdate("true")).to(equal(.unsupported))
        expect(try self.decodeStateUpdate("[1, 2]")).to(equal(.unsupported))
        expect(try self.decodeStateUpdate("null")).to(equal(.unsupported))
    }

    func testDecodeArrayDegradesBadEntriesWithoutFailing() throws {
        // The reviewer's case: a malformed entry must not fail the whole `stateUpdates` array
        // (and therefore the whole button/carousel/tabs component) decode.
        let updates = try decodeStateUpdates("""
        [
            {"set": "selectedFeatureTab", "to": "billing"},
            "not_an_object",
            {"set": "activeSlide", "to": "$value"}
        ]
        """)
        expect(updates).to(haveCount(3))
        expect(updates[0]).to(equal(.set(key: "selectedFeatureTab", value: .literal(.string("billing")))))
        expect(updates[1]).to(equal(.unsupported))
        expect(updates[2]).to(equal(.set(key: "activeSlide", value: .payloadReference)))
    }

    // MARK: round-trip

    func testSetRoundTrips() throws {
        let original = StateUpdate.set(key: "activeSlide", value: .literal(.int(3)))
        let decoded = try JSONDecoder.default.decode(
            StateUpdate.self,
            from: JSONEncoder.default.encode(original)
        )
        expect(decoded).to(equal(original))
    }

    func testPayloadReferenceRoundTrips() throws {
        let original = StateUpdate.set(key: "activeSlide", value: .payloadReference)
        let decoded = try JSONDecoder.default.decode(
            StateUpdate.self,
            from: JSONEncoder.default.encode(original)
        )
        expect(decoded).to(equal(original))
    }

    // MARK: Helpers

    /// Decodes a single update by wrapping it in a one-element array, mirroring how `stateUpdates`
    /// is always decoded (`[StateUpdate]`) and keeping every fixture a valid top-level JSON document.
    private func decodeStateUpdate(_ json: String) throws -> StateUpdate {
        return try XCTUnwrap(decodeStateUpdates("[\(json)]").first)
    }

    private func decodeStateUpdates(_ json: String) throws -> [StateUpdate] {
        return try JSONDecoder.default.decode([StateUpdate].self, from: json.data(using: .utf8)!)
    }

}

#endif
