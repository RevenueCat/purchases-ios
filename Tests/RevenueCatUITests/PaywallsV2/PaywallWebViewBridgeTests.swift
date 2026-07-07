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
    private static let expectedURL = URL(string: "https://assets.example.com/promo/index.html")!

    // MARK: - Envelope model

    func testEnvelopeParseRejectsWrongChannel() {
        let parsed = WebViewEnvelope.parse([
            WebViewEnvelope.Field.channel: "wrong",
            WebViewEnvelope.Field.protocolVersion: 1,
            WebViewEnvelope.Field.kind: WebViewEnvelope.kindConnect,
            WebViewEnvelope.Field.componentID: ""
        ])
        XCTAssertNil(parsed)
    }

    func testEnvelopeParseAcceptsConnect() {
        let parsed = WebViewEnvelope.parse([
            WebViewEnvelope.Field.channel: WebViewEnvelope.channel,
            WebViewEnvelope.Field.protocolVersion: 1,
            WebViewEnvelope.Field.kind: WebViewEnvelope.kindConnect,
            WebViewEnvelope.Field.componentID: ""
        ])
        XCTAssertEqual(parsed?.kind, WebViewEnvelope.kindConnect)
    }

    // MARK: - SDK-managed variables

    func testBaseVariablesIncludeLocale() {
        let variables = PaywallWebViewVariables.base(locale: Locale(identifier: "en_US"))
        XCTAssertEqual(variables["locale"], .string("en-US"))
    }

    // MARK: - Controller outbound JS

    func testReceiveEnvelopeScriptUsesCanonicalReceiveFunction() throws {
        let envelope = WebViewEnvelope.build(
            kind: WebViewEnvelope.kindMessage,
            protocolVersion: 1,
            componentID: Self.componentID,
            type: PaywallWebViewMessageType.variables,
            payload: [
                "locale": .string("en-US"),
                "custom": .object(["plan": .string("annual")])
            ]
        )

        let script = try XCTUnwrap(PaywallWebViewController.receiveEnvelopeScript(envelope: envelope))

        XCTAssertTrue(script.contains("window.__rcWebComponentsReceive"))
        XCTAssertTrue(script.contains("typeof window.__rcWebComponentsReceive==='function'"))

        let json = try XCTUnwrap(self.embeddedJSON(in: script))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        XCTAssertEqual(object[WebViewEnvelope.Field.channel] as? String, WebViewEnvelope.channel)
        XCTAssertEqual(object[WebViewEnvelope.Field.kind] as? String, WebViewEnvelope.kindMessage)
        XCTAssertEqual(object[WebViewEnvelope.Field.type] as? String, "rc:variables")
        let payload = try XCTUnwrap(object[WebViewEnvelope.Field.payload] as? [String: Any])
        XCTAssertEqual(payload["locale"] as? String, "en-US")
        XCTAssertNil(payload["variables"])
    }

    func testPostVariablesStripsReservedLocaleKey() throws {
        let sanitized = PaywallWebViewController.sanitizeAppProvidedVariables([
            "locale": .string("zz-ZZ"),
            "custom": .object(["k": .string("v")])
        ])

        XCTAssertNil(sanitized["locale"])
        XCTAssertEqual(sanitized["custom"], .object(["k": .string("v")]))
    }

    func testReceiveEnvelopeScriptEscapesHostileStringValues() throws {
        let hostile = "annual\" }); alert('xss'); //\n</script>\\ end\u{2028}\u{2029}"
        let envelope = WebViewEnvelope.build(
            kind: WebViewEnvelope.kindMessage,
            protocolVersion: 1,
            componentID: Self.componentID,
            type: PaywallWebViewMessageType.variables,
            payload: ["custom": .object(["evil": .string(hostile)])]
        )

        let script = try XCTUnwrap(PaywallWebViewController.receiveEnvelopeScript(envelope: envelope))
        let json = try XCTUnwrap(self.embeddedJSON(in: script))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let payload = try XCTUnwrap(object[WebViewEnvelope.Field.payload] as? [String: Any])
        let custom = try XCTUnwrap(payload["custom"] as? [String: Any])
        XCTAssertEqual(custom["evil"] as? String, hostile)
        XCTAssertFalse(json.contains("\n"))
    }

    // MARK: - Dispatcher

    func testDispatcherHandlesResizeBeforeAppHandler() {
        var reportedHeight: CGFloat?
        var handled = false

        let envelope = WebViewEnvelope.Parsed(
            kind: WebViewEnvelope.kindMessage,
            protocolVersion: 1,
            componentID: Self.componentID,
            type: PaywallWebViewMessageType.resize,
            id: nil,
            payload: ["height": .number(240)],
            error: nil
        )

        PaywallWebViewMessageDispatcher.handle(
            envelope: envelope,
            componentID: Self.componentID,
            protocolVersion: 1,
            controller: self.makeController(channelOpen: true),
            bridge: self.bridge(
                onContentResize: { _, height in reportedHeight = height },
                messageAction: { _, _ in handled = true }
            )
        )

        XCTAssertEqual(reportedHeight, 240)
        XCTAssertFalse(handled)
    }

    func testDispatcherHandlesResizeRequestWithoutForwardingToAppHandler() {
        var handled = false
        let envelope = WebViewEnvelope.Parsed(
            kind: WebViewEnvelope.kindRequest,
            protocolVersion: 1,
            componentID: Self.componentID,
            type: PaywallWebViewMessageType.resize,
            id: "resize-req",
            payload: ["height": .number(180)],
            error: nil
        )

        PaywallWebViewMessageDispatcher.handle(
            envelope: envelope,
            componentID: Self.componentID,
            protocolVersion: 1,
            controller: self.makeController(channelOpen: true),
            bridge: self.bridge(messageAction: { _, _ in handled = true })
        )

        XCTAssertFalse(handled)
    }

    func testDispatcherAutoRepliesToRequestVariablesMessageForm() {
        var delivered: [[String: PaywallWebViewValue]] = []
        let controller = self.makeController(channelOpen: true) { delivered.append($0) }

        PaywallWebViewMessageDispatcher.handle(
            envelope: WebViewEnvelope.Parsed(
                kind: WebViewEnvelope.kindMessage,
                protocolVersion: 1,
                componentID: Self.componentID,
                type: PaywallWebViewMessageType.requestVariables,
                id: nil,
                payload: nil,
                error: nil
            ),
            componentID: Self.componentID,
            protocolVersion: 1,
            controller: controller,
            bridge: self.bridge(baseVariables: ["locale": .string("en-US")])
        )

        XCTAssertEqual(delivered.count, 1)
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.kind], .string(WebViewEnvelope.kindMessage))
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.type], .string(PaywallWebViewMessageType.variables))
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.payload]?.objectValue?["locale"], .string("en-US"))
    }

    func testDispatcherAutoRepliesToRequestVariablesRequestForm() {
        var delivered: [[String: PaywallWebViewValue]] = []
        let controller = self.makeController(channelOpen: true) { delivered.append($0) }

        PaywallWebViewMessageDispatcher.handle(
            envelope: WebViewEnvelope.Parsed(
                kind: WebViewEnvelope.kindRequest,
                protocolVersion: 1,
                componentID: Self.componentID,
                type: PaywallWebViewMessageType.requestVariables,
                id: "req-1",
                payload: nil,
                error: nil
            ),
            componentID: Self.componentID,
            protocolVersion: 1,
            controller: controller,
            bridge: self.bridge(baseVariables: ["locale": .string("fr-FR")])
        )

        XCTAssertEqual(delivered.count, 1)
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.kind], .string(WebViewEnvelope.kindResponse))
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.id], .string("req-1"))
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.type], .string(PaywallWebViewMessageType.requestVariables))
        XCTAssertEqual(delivered[0][WebViewEnvelope.Field.payload]?.objectValue?["locale"], .string("fr-FR"))
    }

    func testFitEnvelopeDeclaresHostManagedAxes() throws {
        let envelope = try XCTUnwrap(WebViewMessageBridge.fitEnvelope(
            protocolVersion: 1,
            componentID: Self.componentID,
            size: .init(width: .fill, height: .fit)
        ))

        XCTAssertEqual(envelope[WebViewEnvelope.Field.type], .string(PaywallWebViewMessageType.fit))
        XCTAssertEqual(envelope[WebViewEnvelope.Field.payload]?.objectValue?["height"], .bool(true))
        XCTAssertNil(envelope[WebViewEnvelope.Field.payload]?.objectValue?["width"])
    }

    func testRejectEnvelopeFormatForUnsupportedProtocolVersion() throws {
        let envelope = WebViewEnvelope.build(
            kind: WebViewEnvelope.kindReject,
            protocolVersion: 1,
            componentID: "",
            error: "Unsupported protocol_version 2; native host supports 1"
        )

        let script = try XCTUnwrap(PaywallWebViewController.receiveEnvelopeScript(envelope: envelope))
        XCTAssertTrue(script.contains("\"kind\":\"reject\""))
        XCTAssertTrue(script.contains("Unsupported protocol_version 2"))
    }

    // MARK: - Origin gating

    func testOriginMatchesDefaultHTTPSPort() {
        XCTAssertTrue(WebViewOrigin.matches(
            currentURL: URL(string: "https://assets.example.com:443/promo/step-two.html"),
            expectedURL: Self.expectedURL,
            allowBeforeNavigation: false
        ))
    }

    func testOriginRejectsCrossOriginNavigation() {
        XCTAssertFalse(WebViewOrigin.matches(
            currentURL: URL(string: "https://evil.example.org/phish.html"),
            expectedURL: Self.expectedURL,
            allowBeforeNavigation: false
        ))
    }

    func testOriginAllowsHandshakeBeforeNavigation() {
        XCTAssertTrue(WebViewOrigin.matches(
            currentURL: nil,
            expectedURL: Self.expectedURL,
            allowBeforeNavigation: true
        ))
    }

    func testOriginComparisonIsCaseInsensitiveForHost() {
        XCTAssertTrue(WebViewOrigin.matches(
            currentURL: URL(string: "https://ASSETS.EXAMPLE.COM/promo/index.html"),
            expectedURL: Self.expectedURL,
            allowBeforeNavigation: false
        ))
    }

#if canImport(WebKit)

    func testWebContentMessageReachesAppHandlerAfterHandshake() {
        var received: PaywallWebViewMessage?
        let host = TestWebViewBridgeHost(expectedURL: Self.expectedURL)
        host.currentURL = Self.expectedURL
        host.bridge = self.bridge { message, _ in received = message }
        let messageBridge = WebViewMessageBridge(host: host)

        let config = WKWebViewConfiguration()
        let webView = self.loadedWebView(html: "<html><body>hi</body></html>", configuration: config)
        messageBridge.registerIfNeeded(on: webView)

        webView.evaluateJavaScript(
            """
            window.webkit.messageHandlers.\(WebViewEnvelope.messageHandlerName).postMessage(
            '{"channel":"rc-web-components","protocol_version":1,"kind":"connect","component_id":""}'
            ); true
            """
        )

        webView.evaluateJavaScript(
            """
            window.webkit.messageHandlers.\(WebViewEnvelope.messageHandlerName).postMessage(
            '{"channel":"rc-web-components","protocol_version":1,"kind":"message",\
            "component_id":"\(Self.componentID)","type":"rc:step-loaded"}'
            ); true
            """
        )

        let delivered = self.expectation(description: "message delivered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if received != nil { delivered.fulfill() }
        }
        self.wait(for: [delivered], timeout: 2)

        XCTAssertEqual(received?.type, "rc:step-loaded")
        messageBridge.unregister(from: webView)
    }

#endif

    // MARK: - Helpers

    private func bridge(
        baseVariables: [String: PaywallWebViewValue] = [:],
        onContentResize: @escaping (CGFloat?, CGFloat?) -> Void = { _, _ in },
        messageAction: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void = { _, _ in }
    ) -> WebViewBridgeConfiguration {
        WebViewBridgeConfiguration(
            componentID: Self.componentID,
            protocolVersion: 1,
            expectedURL: Self.expectedURL,
            messageAction: PaywallWebViewMessageAction(messageAction),
            baseVariables: baseVariables,
            size: .init(width: .fill, height: .fit),
            onContentResize: onContentResize
        )
    }

    private func makeController(
        channelOpen: Bool,
        onDeliverEnvelope: (([String: PaywallWebViewValue]) -> Void)? = nil
    ) -> PaywallWebViewController {
        #if canImport(WebKit)
        let controller = PaywallWebViewController(
            webView: nil,
            componentID: Self.componentID,
            expectedLoadedURL: Self.expectedURL,
            protocolVersion: 1,
            channelOpen: { channelOpen }
        )
        #else
        let controller = PaywallWebViewController(
            componentID: Self.componentID,
            expectedLoadedURL: Self.expectedURL,
            protocolVersion: 1,
            channelOpen: { channelOpen }
        )
        #endif
        controller.envelopeDeliveryHandler = onDeliverEnvelope
        return controller
    }

    private func embeddedJSON(in script: String) -> String? {
        guard let start = script.range(of: "var m="),
              let end = script.range(of: ";if(typeof") else {
            return nil
        }
        return String(script[start.upperBound..<end.lowerBound])
    }

#if canImport(WebKit)

    private var retainedDelegates: [AnyObject] = []

    private func loadedWebView(
        html: String,
        configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    ) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)

        let loaded = self.expectation(description: "web view finished loading")
        let delegate = TestNavigationDelegate { loaded.fulfill() }
        self.retainedDelegates.append(delegate)
        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: Self.expectedURL)
        self.wait(for: [loaded], timeout: 10)

        return webView
    }

#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
private final class TestWebViewBridgeHost: WebViewBridgeHost {
    var bridge: WebViewBridgeConfiguration?
    var currentURL: URL?

    let expectedURL: URL

    init(expectedURL: URL) {
        self.expectedURL = expectedURL
    }

    func resetMeasuredContentSize() {}
}

#if canImport(WebKit)

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

#endif
