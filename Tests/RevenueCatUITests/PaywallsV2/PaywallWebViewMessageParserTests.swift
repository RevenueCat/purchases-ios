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

    private func envelope(
        kind: String = WebViewEnvelope.kindMessage,
        type: String,
        payload: [String: Any]? = nil,
        id: String? = nil,
        componentID: String = componentID
    ) -> [String: Any] {
        var dictionary: [String: Any] = [
            WebViewEnvelope.Field.channel: WebViewEnvelope.channel,
            WebViewEnvelope.Field.protocolVersion: 1,
            WebViewEnvelope.Field.kind: kind,
            WebViewEnvelope.Field.componentID: componentID,
            WebViewEnvelope.Field.type: type
        ]
        if let payload {
            dictionary[WebViewEnvelope.Field.payload] = payload
        }
        if let id {
            dictionary[WebViewEnvelope.Field.id] = id
        }
        return dictionary
    }

    // MARK: - Envelope parsing

    func testParsesStepLoaded() throws {
        let result = self.parser().parseEnvelope(self.envelope(type: PaywallWebViewMessageType.stepLoaded))

        let message = try result.get().message
        XCTAssertEqual(message.type, "rc:step-loaded")
        XCTAssertEqual(message.componentID, Self.componentID)
    }

    func testParsesStepCompleteWithResponsesInPayload() throws {
        let result = self.parser().parseEnvelope(self.envelope(
            type: PaywallWebViewMessageType.stepComplete,
            payload: [
                WebViewEnvelope.Field.responses: [
                    "selected_plan": "annual",
                    "accepted_terms": true
                ]
            ]
        ))

        let message = try result.get().message
        XCTAssertEqual(message.responses?["selected_plan"], .string("annual"))
        XCTAssertEqual(message.responses?["accepted_terms"], .bool(true))
    }

    func testParsesStepCompleteWithFlatPayload() throws {
        let result = self.parser().parseEnvelope(self.envelope(
            type: PaywallWebViewMessageType.stepComplete,
            payload: ["selected_plan": "annual"]
        ))

        XCTAssertEqual(try result.get().message.responses?["selected_plan"], .string("annual"))
    }

    func testParsesRequestVariablesAsTransportRequest() throws {
        let result = self.parser().parseEnvelope(self.envelope(
            kind: WebViewEnvelope.kindRequest,
            type: PaywallWebViewMessageType.requestVariables,
            id: "req-1"
        ))

        let parsed = try result.get()
        XCTAssertEqual(parsed.message.type, "rc:request-variables")
        XCTAssertEqual(parsed.requestID, "req-1")
    }

    func testParsesErrorFromPayload() throws {
        let result = self.parser().parseEnvelope(self.envelope(
            type: PaywallWebViewMessageType.error,
            payload: [WebViewEnvelope.Field.error: "Something went wrong"]
        ))

        XCTAssertEqual(try result.get().message.error, "Something went wrong")
    }

    func testRejectsWrongChannel() {
        var body = self.envelope(type: PaywallWebViewMessageType.stepLoaded)
        body[WebViewEnvelope.Field.channel] = "wrong"
        XCTAssertEqual(self.parser().parseEnvelope(body).failure, .invalidEnvelope)
    }

    func testRejectsMissingKind() {
        var body = self.envelope(type: PaywallWebViewMessageType.stepLoaded)
        body.removeValue(forKey: WebViewEnvelope.Field.kind)
        XCTAssertEqual(self.parser().parseEnvelope(body).failure, .invalidEnvelope)
    }

    func testRejectsMismatchedComponentID() {
        let result = self.parser().parseEnvelope(self.envelope(
            type: PaywallWebViewMessageType.stepLoaded,
            componentID: "other"
        ))
        XCTAssertEqual(
            result.failure,
            .componentIDMismatch(expected: Self.componentID, received: "other")
        )
    }

    func testRejectsTransportRequestWithoutID() {
        let result = self.parser().parseEnvelope(self.envelope(
            kind: WebViewEnvelope.kindRequest,
            type: PaywallWebViewMessageType.requestVariables
        ))
        XCTAssertEqual(result.failure, .missingRequestID)
    }

    func testDropsUnknownType() {
        let result = self.parser().parseEnvelope(self.envelope(type: "rc:totally-unknown"))
        XCTAssertEqual(result.failure, .unsupportedType("rc:totally-unknown"))
    }

    func testRejectsOversizedPayload() {
        let huge = String(repeating: "a", count: PaywallWebViewMessageParser.maxPayloadBytes + 1)
        let result = self.parser().parseEnvelope(self.envelope(
            type: PaywallWebViewMessageType.stepComplete,
            payload: [WebViewEnvelope.Field.responses: ["blob": huge]]
        ))

        guard case .oversizedPayload = result.failure else {
            return XCTFail("Expected .oversizedPayload, got \(String(describing: result.failure))")
        }
    }

    func testRejectsExcessivelyNestedResponses() {
        var nested: Any = "leaf"
        for _ in 0...(PaywallWebViewValue.maxDepth + 2) {
            nested = [nested]
        }
        let result = self.parser().parseEnvelope(self.envelope(
            type: PaywallWebViewMessageType.stepComplete,
            payload: [WebViewEnvelope.Field.responses: ["deep": nested]]
        ))
        XCTAssertEqual(result.failure, .invalidResponses)
    }

    func testParsesJSONStringBody() throws {
        let data = try JSONSerialization.data(withJSONObject: self.envelope(type: PaywallWebViewMessageType.stepLoaded))
        let json = String(data: data, encoding: .utf8)!
        let result = self.parser().parseEnvelope(json)
        XCTAssertEqual(try result.get().message.type, "rc:step-loaded")
    }

    func testMessageTypeConstantsMatchProtocol() {
        XCTAssertEqual(PaywallWebViewMessageType.stepLoaded, "rc:step-loaded")
        XCTAssertEqual(PaywallWebViewMessageType.stepComplete, "rc:step-complete")
        XCTAssertEqual(PaywallWebViewMessageType.requestVariables, "rc:request-variables")
        XCTAssertEqual(PaywallWebViewMessageType.error, "rc:error")
        XCTAssertEqual(PaywallWebViewMessageType.variables, "rc:variables")
        XCTAssertEqual(PaywallWebViewMessageType.resize, "resize")
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
