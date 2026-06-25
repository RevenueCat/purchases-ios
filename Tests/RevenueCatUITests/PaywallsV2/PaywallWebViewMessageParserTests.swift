//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewMessageParserTests.swift

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallWebViewMessageParserTests: TestCase {

    private static let componentID = "promo_web_view"

    private func parser(componentID: String = "promo_web_view") -> PaywallWebViewMessageParser {
        PaywallWebViewMessageParser(expectedComponentID: componentID)
    }

    // MARK: - Message parsing: valid

    func testParsesStepLoaded() throws {
        let result = self.parser().parse([
            "type": "rc:step-loaded",
            "component_id": Self.componentID
        ])

        let message = try result.get()
        XCTAssertEqual(message.type, "rc:step-loaded")
        XCTAssertEqual(message.componentID, Self.componentID)
        XCTAssertNil(message.responses)
        XCTAssertNil(message.error)
    }

    func testParsesStepCompleteWithResponses() throws {
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": [
                "selected_plan": "annual",
                "accepted_terms": true
            ]
        ])

        let message = try result.get()
        XCTAssertEqual(message.type, "rc:step-complete")
        XCTAssertEqual(message.responses?["selected_plan"], .string("annual"))
        XCTAssertEqual(message.responses?["accepted_terms"], .bool(true))
    }

    func testParsesStepCompleteWithoutResponses() throws {
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID
        ])

        let message = try result.get()
        XCTAssertNil(message.responses)
    }

    func testParsesRequestVariables() throws {
        let result = self.parser().parse([
            "type": "rc:request-variables",
            "component_id": Self.componentID
        ])

        XCTAssertEqual(try result.get().type, "rc:request-variables")
    }

    func testParsesError() throws {
        let result = self.parser().parse([
            "type": "rc:error",
            "component_id": Self.componentID,
            "error": "Something went wrong"
        ])

        let message = try result.get()
        XCTAssertEqual(message.type, "rc:error")
        XCTAssertEqual(message.error, "Something went wrong")
    }

    // MARK: - Message parsing: invalid

    func testRejectsNonObjectBody() {
        XCTAssertEqual(self.parser().parse("not an object").failure, .notAnObject)
    }

    func testRejectsMissingType() {
        let result = self.parser().parse(["component_id": Self.componentID])
        XCTAssertEqual(result.failure, .missingType)
    }

    func testRejectsMissingComponentID() {
        let result = self.parser().parse(["type": "rc:step-loaded"])
        XCTAssertEqual(result.failure, .missingComponentID)
    }

    func testRejectsMismatchedComponentID() {
        let result = self.parser().parse([
            "type": "rc:step-loaded",
            "component_id": "a_different_component"
        ])
        XCTAssertEqual(
            result.failure,
            .componentIDMismatch(expected: Self.componentID, received: "a_different_component")
        )
    }

    func testRejectsInvalidResponsesShape() {
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": "not an object"
        ])
        XCTAssertEqual(result.failure, .invalidResponses)
    }

    func testRejectsErrorWithoutErrorField() {
        let result = self.parser().parse([
            "type": "rc:error",
            "component_id": Self.componentID
        ])
        XCTAssertEqual(result.failure, .missingError)
    }

    func testDropsUnknownType() {
        let result = self.parser().parse([
            "type": "rc:totally-unknown",
            "component_id": Self.componentID
        ])
        XCTAssertEqual(result.failure, .unsupportedType("rc:totally-unknown"))
    }

    func testRejectsOversizedPayload() {
        let huge = String(repeating: "a", count: PaywallWebViewMessageParser.maxPayloadBytes + 1)
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": ["blob": huge]
        ])

        guard case .oversizedPayload = result.failure else {
            return XCTFail("Expected .oversizedPayload, got \(String(describing: result.failure))")
        }
    }

    func testRejectsExcessivelyNestedResponses() {
        // Build an array nested deeper than the allowed depth.
        var nested: Any = "leaf"
        for _ in 0...(PaywallWebViewValue.maxDepth + 2) {
            nested = [nested]
        }
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": ["deep": nested]
        ])
        XCTAssertEqual(result.failure, .invalidResponses)
    }

    func testRejectsNonJSONValueInResponses() {
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": ["when": Date()]
        ])
        // A `Date` is not JSON-serializable, so the body fails the up-front size/JSON check.
        XCTAssertEqual(result.failure, .invalidValue)
    }

    // MARK: - Protocol message-type constants

    func testMessageTypeConstantsMatchProtocol() {
        XCTAssertEqual(PaywallWebViewMessageType.stepLoaded, "rc:step-loaded")
        XCTAssertEqual(PaywallWebViewMessageType.stepComplete, "rc:step-complete")
        XCTAssertEqual(PaywallWebViewMessageType.requestVariables, "rc:request-variables")
        XCTAssertEqual(PaywallWebViewMessageType.error, "rc:error")
        XCTAssertEqual(PaywallWebViewMessageType.variables, "rc:variables")
    }

    // MARK: - Size limit & richer responses

    func testParserAcceptsLargePayloadUnderLimit() throws {
        let blob = String(repeating: "a", count: PaywallWebViewMessageParser.maxPayloadBytes / 2)
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": ["blob": blob]
        ])

        XCTAssertEqual(try result.get().responses?["blob"], .string(blob))
    }

    func testParserAcceptsResponsesWithNestedJSONValues() throws {
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": [
                "selected_plan": "annual",
                "quantity": 3,
                "accepted_terms": true,
                "coupon": NSNull(),
                "addons": ["a", "b"],
                "meta": ["source": "onboarding"]
            ]
        ])

        let responses = try XCTUnwrap(result.get().responses)
        XCTAssertEqual(responses["selected_plan"], .string("annual"))
        XCTAssertEqual(responses["quantity"], .number(3))
        XCTAssertEqual(responses["accepted_terms"], .bool(true))
        XCTAssertEqual(responses["coupon"], .null)
        XCTAssertEqual(responses["addons"], .array([.string("a"), .string("b")]))
        XCTAssertEqual(responses["meta"], .object(["source": .string("onboarding")]))
    }

    func testParserAcceptsEmptyResponsesObject() throws {
        let result = self.parser().parse([
            "type": "rc:step-complete",
            "component_id": Self.componentID,
            "responses": [String: Any]()
        ])

        XCTAssertEqual(try result.get().responses, [:])
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension Result {

    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }

}

#endif
