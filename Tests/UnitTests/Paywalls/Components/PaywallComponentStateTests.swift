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

        let state = try XCTUnwrap(data.state)
        expect(state).to(haveCount(4))
        expect(state["planComparisonOpen"]?.defaultValue).to(equal(.bool(false)))
        expect(state["activeSlide"]?.defaultValue).to(equal(.int(0)))
        expect(state["discountMultiplier"]?.defaultValue).to(equal(.double(0.5)))
        expect(state["selectedFeatureTab"]?.defaultValue).to(equal(.string("billing")))
    }

    func testDecodePaywallComponentsDataWithoutStateMap() throws {
        let data = try decodeComponentsData(state: nil)

        expect(data.state).to(beNil())
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

        let state = try XCTUnwrap(data.state)
        expect(state).to(haveCount(1))
        expect(state["valid"]?.defaultValue).to(equal(.bool(true)))
        expect(data.errorInfo).to(beNil())
    }

    func testMalformedStateMapIsIgnoredWithoutFailingThePaywall() throws {
        let data = try decodeComponentsData(state: """
        "not_an_object"
        """)

        expect(data.state).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testEmptyStateMapIsNormalizedToNil() throws {
        let data = try decodeComponentsData(state: "{}")

        expect(data.state).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testStateMapWhoseEntriesAllFailIsNormalizedToNil() throws {
        let data = try decodeComponentsData(state: """
        {
            "missingDefault": {"type": "boolean"},
            "invalidDefault": {"type": "string", "default": [1, 2]}
        }
        """)

        expect(data.state).to(beNil())
        expect(data.errorInfo).to(beNil())
    }

    func testPaywallComponentsDataStateRoundTrip() throws {
        let original = try decodeComponentsData(state: """
        {"selectedFeatureTab": {"type": "string", "default": "billing"}}
        """)

        let encoded = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(PaywallComponentsData.self, from: encoded)

        expect(decoded.state).to(equal(original.state))
    }

    // MARK: Helpers

    private func decodeDeclaration(_ json: String) throws -> PaywallComponent.StateDeclaration {
        return try JSONDecoder.default.decode(
            PaywallComponent.StateDeclaration.self,
            from: json.data(using: .utf8)!
        )
    }

    private func decodeComponentsData(state: String?) throws -> PaywallComponentsData {
        let stateField = state.map { ",\n\"state\": \($0)" } ?? ""
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

#endif
