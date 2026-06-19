//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewBridgeTests.swift

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallWebViewBridgeTests: TestCase {

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

    // MARK: - PaywallWebViewValue conversion

    func testValueConvertsJSONTypes() {
        XCTAssertEqual(PaywallWebViewValue(jsonObject: "hi"), .string("hi"))
        XCTAssertEqual(PaywallWebViewValue(jsonObject: 42 as NSNumber)?.numberValue, 42)
        XCTAssertEqual(PaywallWebViewValue(jsonObject: true as NSNumber), .bool(true))
        XCTAssertEqual(PaywallWebViewValue(jsonObject: NSNull()), .null)
        XCTAssertEqual(
            PaywallWebViewValue(jsonObject: ["a", "b"]),
            .array([.string("a"), .string("b")])
        )
        XCTAssertEqual(
            PaywallWebViewValue(jsonObject: ["k": "v"]),
            .object(["k": .string("v")])
        )
    }

    func testValueDisambiguatesBoolFromNumber() {
        let boolValue = PaywallWebViewValue(jsonObject: true as NSNumber)
        XCTAssertEqual(boolValue?.boolValue, true)
        XCTAssertNil(boolValue?.numberValue)

        let numberValue = PaywallWebViewValue(jsonObject: 1 as NSNumber)
        XCTAssertEqual(numberValue?.numberValue, 1)
        XCTAssertNil(numberValue?.boolValue)
    }

    func testValueRejectsNonJSON() {
        XCTAssertNil(PaywallWebViewValue(jsonObject: Date()))
        XCTAssertNil(PaywallWebViewValue(jsonObject: ["ok", Date()]))
    }

    // MARK: - SDK-managed + custom variables

    func testBaseVariablesIncludeLocaleAndColorScheme() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "en_US"),
            colorScheme: .dark,
            customVariables: [:]
        )

        XCTAssertEqual(variables["locale"], .string("en-US"))
        XCTAssertEqual(variables["color_scheme"], .string("dark"))
        XCTAssertEqual(variables["custom"], .object([:]))
    }

    func testBaseVariablesLightColorScheme() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "fr_FR"),
            colorScheme: .light,
            customVariables: [:]
        )

        XCTAssertEqual(variables["color_scheme"], .string("light"))
    }

    func testBaseVariablesIncludeCustomVariablesUnderCustom() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "en_US"),
            colorScheme: .light,
            customVariables: [
                "campaign": .string("summer"),
                "level": .number(42),
                "is_premium": .bool(true)
            ]
        )

        XCTAssertEqual(variables["custom"], .object([
            "campaign": .string("summer"),
            "level": .number(42),
            "is_premium": .bool(true)
        ]))
    }

    func testBaseVariablesDoNotExposeReservedKeysToCustom() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "en_US"),
            colorScheme: .dark,
            customVariables: ["plan": .string("annual")]
        )

        // Reserved keys remain top-level and SDK-owned; custom variables only live under `custom`.
        XCTAssertEqual(variables["locale"], .string("en-US"))
        XCTAssertEqual(variables["color_scheme"], .string("dark"))
        XCTAssertEqual(variables["custom"]?.objectValue?["plan"], .string("annual"))
    }

    // MARK: - Controller envelope / outbound JS

    func testReceiveMessageScriptProducesRFCEnvelope() throws {
        let script = try XCTUnwrap(PaywallWebViewController.receiveMessageScript(
            componentID: Self.componentID,
            type: "rc:variables",
            variables: [
                "locale": .string("en-US"),
                "color_scheme": .string("dark"),
                "custom": .object(["plan": .string("annual")])
            ]
        ))

        XCTAssertTrue(script.contains("window.__revenueCatReceiveMessage"))
        XCTAssertTrue(script.contains("typeof window.__revenueCatReceiveMessage==='function'"))

        // The embedded payload must be valid JSON matching the RFC envelope.
        let json = try XCTUnwrap(self.embeddedJSON(in: script))
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
        XCTAssertEqual(object["type"] as? String, "rc:variables")
        XCTAssertEqual(object["component_id"] as? String, Self.componentID)
        let variables = try XCTUnwrap(object["variables"] as? [String: Any])
        XCTAssertEqual(variables["locale"] as? String, "en-US")
        XCTAssertEqual(variables["color_scheme"] as? String, "dark")
    }

    // MARK: - Dispatcher routing

    func testDispatcherRejectsNonMainFrameMessages() {
        var handled = false
        PaywallWebViewMessageDispatcher.handle(
            body: ["type": "rc:step-loaded", "component_id": Self.componentID],
            isMainFrame: false,
            componentID: Self.componentID,
            controller: self.makeController(),
            bridge: self.bridge { _, _ in handled = true }
        )

        XCTAssertFalse(handled, "Messages from non-main frames must be dropped")
    }

    func testDispatcherForwardsValidMessageToHandler() {
        var received: PaywallWebViewMessage?
        PaywallWebViewMessageDispatcher.handle(
            body: [
                "type": "rc:step-complete",
                "component_id": Self.componentID,
                "responses": ["selected_plan": "annual"]
            ],
            isMainFrame: true,
            componentID: Self.componentID,
            controller: self.makeController(),
            bridge: self.bridge { message, _ in received = message }
        )

        XCTAssertEqual(received?.type, "rc:step-complete")
        XCTAssertEqual(received?.componentID, Self.componentID)
        XCTAssertEqual(received?.responses?["selected_plan"], .string("annual"))
    }

    func testDispatcherDropsMismatchedComponentID() {
        var handled = false
        PaywallWebViewMessageDispatcher.handle(
            body: ["type": "rc:step-loaded", "component_id": "other"],
            isMainFrame: true,
            componentID: Self.componentID,
            controller: self.makeController(),
            bridge: self.bridge { _, _ in handled = true }
        )

        XCTAssertFalse(handled, "Messages for a different component must be rejected")
    }

    func testDispatcherStillInvokesHandlerForRequestVariables() {
        var received: PaywallWebViewMessage?
        PaywallWebViewMessageDispatcher.handle(
            body: ["type": "rc:request-variables", "component_id": Self.componentID],
            isMainFrame: true,
            componentID: Self.componentID,
            controller: self.makeController(),
            bridge: self.bridge(baseVariables: ["locale": .string("en-US")]) { message, _ in received = message }
        )

        XCTAssertEqual(received?.type, "rc:request-variables")
    }

    // MARK: - JavaScript injection

    func testBridgeScriptExposesPostMessageAndHandlerName() {
        let source = PaywallWebViewScripts.messageBridgeJavaScriptSource
        XCTAssertTrue(source.contains("window.RevenueCatWebView"))
        XCTAssertTrue(source.contains("postMessage"))
        XCTAssertTrue(source.contains("window.webkit.messageHandlers.rcWebViewMessage"))
        XCTAssertTrue(source.contains("__rcBridgeInstalled"))
    }

    func testBridgeUsesDedicatedHandlerNameSeparateFromHeight() {
        XCTAssertEqual(PaywallWebViewScripts.messageHandlerName, "rcWebViewMessage")
        XCTAssertNotEqual(PaywallWebViewScripts.messageHandlerName, "rcWebViewHeight")
    }

    // MARK: - Helpers

    private func bridge(
        baseVariables: [String: PaywallWebViewValue] = [:],
        messageAction: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void
    ) -> WebViewBridgeConfiguration {
        WebViewBridgeConfiguration(
            componentID: Self.componentID,
            messageAction: PaywallWebViewMessageAction(messageAction),
            baseVariables: baseVariables
        )
    }

    private func makeController() -> PaywallWebViewController {
        #if canImport(WebKit)
        return PaywallWebViewController(webView: nil, componentID: Self.componentID, expectedLoadedURL: nil)
        #else
        return PaywallWebViewController(componentID: Self.componentID, expectedLoadedURL: nil)
        #endif
    }

    /// Extracts the JSON object literal embedded between `var m=` and `;if(typeof` in the receive
    /// script, for assertion purposes.
    private func embeddedJSON(in script: String) -> String? {
        guard let start = script.range(of: "var m="),
              let end = script.range(of: ";if(typeof") else {
            return nil
        }
        return String(script[start.upperBound..<end.lowerBound])
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
