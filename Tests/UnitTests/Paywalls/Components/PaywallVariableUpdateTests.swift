//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallVariableUpdateTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class PaywallVariableUpdateCodableTests: TestCase {

    // MARK: - VariableUpdate decoding

    func testDecodeSetWithStringLiteral() throws {
        let json = """
        { "set": "selectedPlan", "to": "annual" }
        """

        let update = try JSONDecoder.default.decode(
            PaywallComponent.VariableUpdate.self,
            from: Data(json.utf8)
        )

        guard case let .set(key, .literal(value)) = update else {
            XCTFail("Expected .set with literal value, got \(update)")
            return
        }
        XCTAssertEqual(key, "selectedPlan")
        XCTAssertEqual(value, .string("annual"))
    }

    func testDecodeSetWithBoolLiteral() throws {
        let json = """
        { "set": "comparisonOpen", "to": true }
        """

        let update = try JSONDecoder.default.decode(
            PaywallComponent.VariableUpdate.self,
            from: Data(json.utf8)
        )

        guard case let .set(key, .literal(value)) = update else {
            XCTFail("Expected .set with literal value, got \(update)")
            return
        }
        XCTAssertEqual(key, "comparisonOpen")
        XCTAssertEqual(value, .bool(true))
    }

    func testDecodeSetWithIntLiteral() throws {
        let json = """
        { "set": "count", "to": 7 }
        """

        let update = try JSONDecoder.default.decode(
            PaywallComponent.VariableUpdate.self,
            from: Data(json.utf8)
        )

        guard case let .set(_, .literal(value)) = update else {
            XCTFail("Expected .set with literal value, got \(update)")
            return
        }
        XCTAssertEqual(value, .int(7))
    }

    func testDecodeSetWithDoubleLiteral() throws {
        let json = """
        { "set": "ratio", "to": 1.5 }
        """

        let update = try JSONDecoder.default.decode(
            PaywallComponent.VariableUpdate.self,
            from: Data(json.utf8)
        )

        guard case let .set(_, .literal(value)) = update else {
            XCTFail("Expected .set with literal value, got \(update)")
            return
        }
        XCTAssertEqual(value, .double(1.5))
    }

    func testDecodeSetWithPayloadReference() throws {
        let json = """
        { "set": "activeTab", "to": "$value" }
        """

        let update = try JSONDecoder.default.decode(
            PaywallComponent.VariableUpdate.self,
            from: Data(json.utf8)
        )

        guard case let .set(key, .payloadReference) = update else {
            XCTFail("Expected .set with payloadReference, got \(update)")
            return
        }
        XCTAssertEqual(key, "activeTab")
    }

    func testDecodeUnknownShapeFallsBackToUnsupported() throws {
        // Future operation this SDK version doesn't understand — should decode as .unsupported
        // rather than failing so newer JSON stays safe on older SDKs.
        let json = """
        { "increment": "counter", "by": 1 }
        """

        let update = try JSONDecoder.default.decode(
            PaywallComponent.VariableUpdate.self,
            from: Data(json.utf8)
        )

        guard case .unsupported = update else {
            XCTFail("Expected .unsupported, got \(update)")
            return
        }
    }

    // MARK: - VariableUpdate encoding round-trip

    func testEncodeDecodeSetWithLiteralRoundTrips() throws {
        let original: PaywallComponent.VariableUpdate = .set(key: "k", value: .literal(.string("v")))

        let data = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(PaywallComponent.VariableUpdate.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testEncodeDecodePayloadReferenceRoundTrips() throws {
        let original: PaywallComponent.VariableUpdate = .set(key: "k", value: .payloadReference)

        let data = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(PaywallComponent.VariableUpdate.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testEncodePayloadReferenceUsesDollarValueToken() throws {
        let update: PaywallComponent.VariableUpdate = .set(key: "k", value: .payloadReference)

        let data = try JSONEncoder.default.encode(update)
        let jsonString = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(jsonString.contains("\"$value\""),
                      "Expected encoded JSON to contain the $value token, got: \(jsonString)")
    }

}

#endif
