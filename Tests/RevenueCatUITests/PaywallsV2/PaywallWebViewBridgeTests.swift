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
#if canImport(WebKit)
import WebKit
#endif

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

    // MARK: - Protocol message-type constants

    func testMessageTypeConstantsMatchProtocol() {
        XCTAssertEqual(PaywallWebViewMessageType.stepLoaded, "rc:step-loaded")
        XCTAssertEqual(PaywallWebViewMessageType.stepComplete, "rc:step-complete")
        XCTAssertEqual(PaywallWebViewMessageType.requestVariables, "rc:request-variables")
        XCTAssertEqual(PaywallWebViewMessageType.error, "rc:error")
        XCTAssertEqual(PaywallWebViewMessageType.variables, "rc:variables")
    }

    // MARK: - Outbound JS escaping (security)

    func testReceiveMessageScriptEscapesHostileStringValues() throws {
        // Quotes, backslashes, newlines, and a literal closing-script sequence must all be confined
        // to the JSON payload and survive a round-trip exactly — never breaking out of the call.
        let hostile = "annual\" }); alert('xss'); //\n</script>\\ end\u{2028}\u{2029}"
        let script = try XCTUnwrap(PaywallWebViewController.receiveMessageScript(
            componentID: Self.componentID,
            type: "rc:variables",
            variables: ["custom": .object(["evil": .string(hostile)])]
        ))

        let json = try XCTUnwrap(self.embeddedJSON(in: script))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let variables = try XCTUnwrap(object["variables"] as? [String: Any])
        let custom = try XCTUnwrap(variables["custom"] as? [String: Any])
        XCTAssertEqual(custom["evil"] as? String, hostile)

        // A raw newline would make the `var m=...` statement a syntax error; it must be escaped.
        XCTAssertFalse(json.contains("\n"))
    }

    func testReceiveMessageScriptSerializesAllValueTypes() throws {
        let script = try XCTUnwrap(PaywallWebViewController.receiveMessageScript(
            componentID: Self.componentID,
            type: "rc:variables",
            variables: [
                "string": .string("s"),
                "number": .number(3.5),
                "bool": .bool(false),
                "null": .null,
                "array": .array([.number(1), .string("two")]),
                "object": .object(["nested": .bool(true)])
            ]
        ))

        let json = try XCTUnwrap(self.embeddedJSON(in: script))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let variables = try XCTUnwrap(object["variables"] as? [String: Any])
        XCTAssertEqual(variables["string"] as? String, "s")
        XCTAssertEqual(variables["number"] as? Double, 3.5)
        XCTAssertEqual(variables["bool"] as? Bool, false)
        XCTAssertTrue(variables["null"] is NSNull)
        let array = try XCTUnwrap(variables["array"] as? [Any])
        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(array.first as? Double, 1)
        XCTAssertEqual(array.last as? String, "two")
        XCTAssertEqual((variables["object"] as? [String: Any])?["nested"] as? Bool, true)
    }

    // MARK: - PaywallWebViewValue: accessors, round-trip, depth, hashing

    func testValueAccessorsReturnNilForMismatchedTypes() {
        XCTAssertNil(PaywallWebViewValue.string("x").numberValue)
        XCTAssertNil(PaywallWebViewValue.string("x").boolValue)
        XCTAssertNil(PaywallWebViewValue.number(1).stringValue)
        XCTAssertNil(PaywallWebViewValue.bool(true).numberValue)
        XCTAssertNil(PaywallWebViewValue.string("x").arrayValue)
        XCTAssertNil(PaywallWebViewValue.string("x").objectValue)
        XCTAssertFalse(PaywallWebViewValue.string("x").isNull)
        XCTAssertTrue(PaywallWebViewValue.null.isNull)
    }

    func testValueNullBridgesToNSNull() {
        XCTAssertTrue(PaywallWebViewValue.null.jsonObject is NSNull)
    }

    func testValueRoundTripsThroughJSONSerialization() throws {
        let original: PaywallWebViewValue = .object([
            "s": .string("hello"),
            "n": .number(42),
            "b": .bool(true),
            "null": .null,
            "arr": .array([.number(1), .object(["deep": .string("v")])])
        ])

        let data = try JSONSerialization.data(withJSONObject: original.jsonObject)
        let decoded = try XCTUnwrap(PaywallWebViewValue(jsonObject: JSONSerialization.jsonObject(with: data)))

        XCTAssertEqual(decoded, original)
    }

    func testValueConvertsNestedContainers() {
        let value = PaywallWebViewValue(jsonObject: [
            "list": [["k": 1], ["k": 2]]
        ])

        XCTAssertEqual(value, .object([
            "list": .array([.object(["k": .number(1)]), .object(["k": .number(2)])])
        ]))
    }

    func testValueConvertsAtMaxDepth() {
        XCTAssertNotNil(PaywallWebViewValue(jsonObject: Self.nested(depth: PaywallWebViewValue.maxDepth)))
    }

    func testValueRejectsBeyondMaxDepth() {
        XCTAssertNil(PaywallWebViewValue(jsonObject: Self.nested(depth: PaywallWebViewValue.maxDepth + 1)))
    }

    func testValueIsHashableAndEquatable() {
        let lhs: PaywallWebViewValue = .object(["a": .array([.number(1), .null])])
        let rhs: PaywallWebViewValue = .object(["a": .array([.number(1), .null])])
        let other: PaywallWebViewValue = .object(["a": .array([.number(2), .null])])

        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
        XCTAssertNotEqual(lhs, other)
        XCTAssertEqual(Set([lhs, rhs, other]).count, 2)
    }

    // MARK: - Parser: size limit & richer responses

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

    // MARK: - Variables: locale formatting & value types

    func testBaseVariablesFormatsLanguageOnlyLocale() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "fr"),
            colorScheme: .light,
            customVariables: [:]
        )

        XCTAssertEqual(variables["locale"], .string("fr"))
    }

    func testBaseVariablesFormatsScriptAndRegionLocaleAsBCP47() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "zh_Hans_CN"),
            colorScheme: .light,
            customVariables: [:]
        )

        // Must use hyphen separators (BCP-47), never the underscore form.
        let locale = variables["locale"]?.stringValue
        XCTAssertEqual(locale?.contains("_"), false)
        XCTAssertEqual(locale?.contains("zh"), true)
    }

    func testBaseVariablesPreserveCustomNumberAndBoolTypes() {
        let variables = PaywallWebViewVariables.base(
            locale: Locale(identifier: "en_US"),
            colorScheme: .light,
            customVariables: ["count": .number(7), "flag": .bool(false), "name": .string("x")]
        )

        // Custom numbers/bools must not be stringified.
        XCTAssertEqual(variables["custom"]?.objectValue?["count"], .number(7))
        XCTAssertEqual(variables["custom"]?.objectValue?["flag"], .bool(false))
        XCTAssertEqual(variables["custom"]?.objectValue?["name"], .string("x"))
    }

#if canImport(WebKit)

    // MARK: - WebKit round-trip integration

    func testWebContentPostMessageReachesNativeHandler() {
        let handlerCalled = self.expectation(description: "native handler invoked")
        var receivedBody: Any?
        let handler = TestScriptMessageHandler { message in
            receivedBody = message.body
            handlerCalled.fulfill()
        }

        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(PaywallWebViewScripts.messageBridgeUserScript)
        config.userContentController.add(handler, name: PaywallWebViewScripts.messageHandlerName)

        let webView = self.loadedWebView(html: "<html><body>hi</body></html>", configuration: config)

        webView.evaluateJavaScript(
            "window.RevenueCatWebView.postMessage("
            + "{type:'rc:step-complete',component_id:'\(Self.componentID)',responses:{selected_plan:'annual'}}); true"
        )

        self.wait(for: [handlerCalled], timeout: 10)
        config.userContentController.removeScriptMessageHandler(forName: PaywallWebViewScripts.messageHandlerName)

        let body = receivedBody as? [String: Any]
        XCTAssertEqual(body?["type"] as? String, "rc:step-complete")
        XCTAssertEqual(body?["component_id"] as? String, Self.componentID)
        XCTAssertEqual((body?["responses"] as? [String: Any])?["selected_plan"] as? String, "annual")
    }

    func testControllerDeliversVariablesToWebContentIntact() throws {
        let webView = self.loadedWebView(html: Self.receiverHTML)

        let controller = PaywallWebViewController(
            webView: webView,
            componentID: Self.componentID,
            expectedLoadedURL: webView.url
        )

        // Include hostile characters to prove escaping survives the real evaluateJavaScript path.
        let hostile = "annual\" }); //\n</script>\\ end"
        controller.postVariables(
            componentID: Self.componentID,
            variables: ["locale": .string("en-US"), "custom": .object(["plan": .string(hostile)])]
        )

        let received = try XCTUnwrap(self.pollString(in: webView, script: "window.__rcReceived"))
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(received.utf8)) as? [String: Any]
        )
        XCTAssertEqual(object["type"] as? String, "rc:variables")
        XCTAssertEqual(object["component_id"] as? String, Self.componentID)
        let variables = try XCTUnwrap(object["variables"] as? [String: Any])
        XCTAssertEqual(variables["locale"] as? String, "en-US")
        XCTAssertEqual((variables["custom"] as? [String: Any])?["plan"] as? String, hostile)
    }

    func testControllerSkipsDeliveryWhenURLMismatches() throws {
        let webView = self.loadedWebView(html: Self.receiverHTML)

        let controller = PaywallWebViewController(
            webView: webView,
            componentID: Self.componentID,
            expectedLoadedURL: URL(string: "https://different.example.com/elsewhere")!
        )
        controller.postVariables(componentID: Self.componentID, variables: ["locale": .string("en-US")])

        // The receive hook must never fire for a mismatched expected URL.
        let state = try XCTUnwrap(self.pollString(
            in: webView,
            script: "window.__rcReceived === null ? 'NULL' : 'GOT'"
        ))
        XCTAssertEqual(state, "NULL")
    }

#endif

    // MARK: - Helpers

    /// Builds an `Any` JSON value made of `depth` nested arrays around a leaf string. The leaf is
    /// processed at recursion depth `depth`, exercising ``PaywallWebViewValue/maxDepth``.
    private static func nested(depth: Int) -> Any {
        var value: Any = "leaf"
        for _ in 0..<depth {
            value = [value]
        }
        return value
    }

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

#if canImport(WebKit)

    /// HTML whose receive hook stores the last message it gets as a JSON string on `window.__rcReceived`.
    private static let receiverHTML = """
    <html><body><script>
    window.__rcReceived = null;
    window.__revenueCatReceiveMessage = function(m) { window.__rcReceived = JSON.stringify(m); };
    </script></body></html>
    """

    /// Keeps navigation delegates alive for the duration of a test (`WKWebView.navigationDelegate` is weak).
    private var retainedDelegates: [AnyObject] = []

    private func loadedWebView(
        html: String,
        configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    ) -> WKWebView {
        if configuration.userContentController.userScripts.isEmpty {
            configuration.userContentController.addUserScript(PaywallWebViewScripts.messageBridgeUserScript)
        }
        let webView = WKWebView(frame: .zero, configuration: configuration)

        let loaded = self.expectation(description: "web view finished loading")
        let delegate = TestNavigationDelegate { loaded.fulfill() }
        self.retainedDelegates.append(delegate)
        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: URL(string: "https://example.com"))
        self.wait(for: [loaded], timeout: 10)

        return webView
    }

    /// Repeatedly evaluates `script` until it returns a non-nil string or the timeout elapses.
    private func pollString(in webView: WKWebView, script: String, timeout: TimeInterval = 5) -> String? {
        let deadline = Date().addingTimeInterval(timeout)
        var result: String?

        while result == nil && Date() < deadline {
            let evaluated = self.expectation(description: "evaluate \(script)")
            webView.evaluateJavaScript(script) { value, _ in
                result = value as? String
                evaluated.fulfill()
            }
            self.wait(for: [evaluated], timeout: 2)

            if result == nil {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }

        return result
    }

#endif

}

#if canImport(WebKit)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class TestScriptMessageHandler: NSObject, WKScriptMessageHandler {

    private let onMessage: (WKScriptMessage) -> Void

    init(onMessage: @escaping (WKScriptMessage) -> Void) {
        self.onMessage = onMessage
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        self.onMessage(message)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class TestNavigationDelegate: NSObject, WKNavigationDelegate {

    private let onFinish: () -> Void
    private var finished = false

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !self.finished else { return }
        self.finished = true
        self.onFinish()
    }

}

#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension Result {

    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }

}

#endif
