//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest
// swiftlint:disable force_try

#if canImport(WebKit)
import WebKit
#endif

#if !os(tvOS) && canImport(WebKit)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewSessionTests: TestCase {

    func testConnectV1SendsInitAndFit() throws {
        let harness = Harness(size: (width: false, height: true))

        harness.handle(.init(kind: .connect, componentID: "", protocolVersion: 1))

        XCTAssertTrue(harness.session.channelOpen)
        let envelopes = try harness.outboundEnvelopes()
        XCTAssertEqual(envelopes.map(\.kind), [.`init`, .message])
        XCTAssertEqual(envelopes[0].componentID, "web")
        XCTAssertEqual(envelopes[1].type, WebViewEnvelope.messageTypeFit)
        XCTAssertNil(envelopes[1].payload?["width"])
        XCTAssertEqual(envelopes[1].payload?["height"]?.boolValue, true)
    }

    func testConnectV2Rejects() throws {
        let harness = Harness()

        harness.handle(.init(kind: .connect, componentID: "", protocolVersion: 2))

        XCTAssertFalse(harness.session.channelOpen)
        let envelope = try XCTUnwrap(harness.outboundEnvelopes().first)
        XCTAssertEqual(envelope.kind, .reject)
        XCTAssertEqual(envelope.componentID, "")
        XCTAssertEqual(envelope.error, "Unsupported protocol_version 2; native host supports 1")
    }

    func testDropsBeforeConnectDuplicateConnectAndNonMainFrame() throws {
        let harness = Harness()

        harness.handle(.init(kind: .message, componentID: "web", type: WebViewEnvelope.messageTypeStepLoaded))
        XCTAssertTrue(harness.capturedScripts.isEmpty)

        harness.handle(.init(kind: .connect, componentID: ""))
        harness.handle(.init(kind: .connect, componentID: ""))
        XCTAssertEqual(try harness.outboundEnvelopes().filter { $0.kind == .`init` }.count, 1)

        harness.handle(
            .init(kind: .message, componentID: "web", type: WebViewEnvelope.messageTypeStepLoaded),
            isMainFrame: false
        )
        XCTAssertTrue(harness.messages.isEmpty)
    }

    func testFitMessageDeclaresExactlyTheFitAxes() throws {
        let widthOnly = Harness(size: (width: true, height: false))
        widthOnly.handle(.init(kind: .connect, componentID: ""))
        let widthFit = try XCTUnwrap(widthOnly.outboundEnvelopes().last)
        XCTAssertEqual(widthFit.type, WebViewEnvelope.messageTypeFit)
        XCTAssertEqual(widthFit.payload?["width"]?.boolValue, true)
        XCTAssertNil(widthFit.payload?["height"])

        let both = Harness(size: (width: true, height: true))
        both.handle(.init(kind: .connect, componentID: ""))
        let bothFit = try XCTUnwrap(both.outboundEnvelopes().last)
        XCTAssertEqual(bothFit.type, WebViewEnvelope.messageTypeFit)
        XCTAssertEqual(bothFit.payload?["width"]?.boolValue, true)
        XCTAssertEqual(bothFit.payload?["height"]?.boolValue, true)

        let neither = Harness(size: (width: false, height: false))
        neither.handle(.init(kind: .connect, componentID: ""))
        XCTAssertEqual(try neither.outboundEnvelopes().map(\.kind), [.`init`])
    }

    func testDropsAppFramesWithNonAppKinds() {
        let harness = Harness()
        harness.connect()

        for kind: WebViewEnvelope.Kind in [.`init`, .reject, .response, .error] {
            harness.handle(.init(
                kind: kind,
                componentID: "web",
                type: WebViewEnvelope.messageTypeStepLoaded,
                id: "id-1"
            ))
        }

        XCTAssertTrue(harness.messages.isEmpty)
        XCTAssertTrue(harness.capturedScripts.isEmpty)
    }

    func testDropsAnyRequestWithoutID() {
        let harness = Harness()
        harness.connect()

        harness.handle(.init(kind: .request, componentID: "web", type: WebViewEnvelope.messageTypeStepLoaded))
        harness.handle(.init(kind: .request, componentID: "web", type: WebViewEnvelope.messageTypeRequestVariables))

        XCTAssertTrue(harness.messages.isEmpty)
        XCTAssertTrue(harness.capturedScripts.isEmpty)
    }

    func testStepLoadedStepCompleteAndErrorReachHandler() {
        let harness = Harness()
        harness.connect()

        harness.handle(.init(kind: .message, componentID: "web", type: WebViewEnvelope.messageTypeStepLoaded))
        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeStepComplete,
            payload: ["responses": .object(["choice": .string("annual")])]
        ))
        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeError,
            payload: ["error": .string("boom")]
        ))

        XCTAssertEqual(harness.messages.map(\.type), [
            WebViewEnvelope.messageTypeStepLoaded,
            WebViewEnvelope.messageTypeStepComplete,
            WebViewEnvelope.messageTypeError
        ])
        XCTAssertEqual(harness.messages[1].responses?["choice"]?.stringValue, "annual")
        XCTAssertEqual(harness.messages[2].error, "boom")
    }

    func testStepCompleteFlatPayloadAndReservedKeyPolicy() {
        let harness = Harness()
        harness.connect()

        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeStepComplete,
            payload: ["choice": .string("annual")]
        ))
        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeStepComplete,
            payload: ["variables": .object([:])]
        ))

        XCTAssertEqual(harness.messages.count, 1)
        XCTAssertEqual(harness.messages[0].responses?["choice"]?.stringValue, "annual")
    }

    func testRequestVariablesAutoRepliesAndForwards() throws {
        let localeIdentifier = "zh_Hans_CN"
        let harness = Harness(localeIdentifier: localeIdentifier)
        harness.connect()
        harness.capturedScripts.removeAll()

        harness.handle(.init(
            kind: .request,
            componentID: "web",
            type: WebViewEnvelope.messageTypeRequestVariables,
            id: "req-1"
        ))

        let response = try XCTUnwrap(harness.outboundEnvelopes().first)
        XCTAssertEqual(response.kind, .response)
        XCTAssertEqual(response.id, "req-1")
        // Compare against the same helper the session uses — BCP-47 canonical forms
        // vary by OS (e.g. `zh-CN` vs `zh-Hans-CN`).
        XCTAssertEqual(
            response.payload?["locale"]?.stringValue,
            WebViewSession.bcp47Tag(fromLocaleIdentifier: localeIdentifier)
        )
        XCTAssertNil(response.payload?["variables"])
        XCTAssertEqual(harness.messages.last?.type, WebViewEnvelope.messageTypeRequestVariables)
    }

    func testRequestVariablesMessageAutoRepliesWithNoHandler() throws {
        let harness = Harness()
        harness.session.messageHandler = nil
        harness.connect()
        harness.capturedScripts.removeAll()

        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeRequestVariables
        ))

        let response = try XCTUnwrap(harness.outboundEnvelopes().first)
        XCTAssertEqual(response.kind, .message)
        XCTAssertEqual(response.type, WebViewEnvelope.messageTypeVariables)
        XCTAssertEqual(response.payload?["locale"]?.stringValue, "en-US")
        XCTAssertTrue(harness.messages.isEmpty)
    }

    func testOutboundGatingOriginAndLocaleSanitizing() throws {
        let harness = Harness()
        harness.session.postVariables(componentID: "web", variables: ["x": .bool(true)])
        XCTAssertTrue(harness.capturedScripts.isEmpty)

        harness.connect()
        harness.capturedScripts.removeAll()
        harness.session.postVariables(componentID: "web", variables: [
            "locale": .string("app"),
            "segment": .string("pro")
        ])

        var outbound = try XCTUnwrap(harness.outboundEnvelopes().first)
        XCTAssertEqual(outbound.type, WebViewEnvelope.messageTypeVariables)
        XCTAssertNil(outbound.payload?["locale"])
        XCTAssertEqual(outbound.payload?["segment"]?.stringValue, "pro")

        harness.capturedScripts.removeAll()
        harness.currentURL = URL(string: "https://evil.example/path")!
        harness.session.post(componentID: "web", type: "custom", variables: ["ok": .bool(true)])
        XCTAssertTrue(harness.capturedScripts.isEmpty)

        harness.currentURL = URL(string: "https://EXAMPLE.com:443/next")!
        harness.session.post(componentID: "web", type: "custom", variables: ["ok": .bool(true)])
        outbound = try XCTUnwrap(harness.outboundEnvelopes().first)
        XCTAssertEqual(outbound.payload?["ok"]?.boolValue, true)
    }

    func testResizeAppliesOnlyFitAxesAndThreshold() {
        let harness = Harness(size: (width: true, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["width": .number(200), "height": .number(99_999)]
        ))
        harness.handle(.init(
            kind: .request,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            id: "resize-1",
            payload: ["width": .number(200.5), "height": .number(10_000.5)]
        ))
        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["width": .number(201), "height": .number(-1)]
        ))

        XCTAssertEqual(resizes.count, 2)
        XCTAssertEqual(resizes[0].0, 200)
        XCTAssertEqual(resizes[0].1, 10_000)
        XCTAssertEqual(resizes[1].0, 201)
        XCTAssertNil(resizes[1].1)
        XCTAssertTrue(harness.messages.isEmpty)
    }

    func testResizeIgnoresWidthWhenWidthIsNotFit() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["width": .number(400), "height": .number(500)]
        ))

        XCTAssertEqual(resizes.count, 1)
        XCTAssertNil(resizes[0].0)
        XCTAssertEqual(resizes[0].1, 500)
    }


    func testReconnectAfterDocumentReset() throws {
        let harness = Harness()
        harness.connect()
        XCTAssertTrue(harness.session.channelOpen)

        harness.session.resetForNewDocument()
        XCTAssertFalse(harness.session.channelOpen)

        harness.handle(.init(kind: .message, componentID: "web", type: WebViewEnvelope.messageTypeStepLoaded))
        XCTAssertTrue(harness.messages.isEmpty)

        harness.capturedScripts.removeAll()
        harness.handle(.init(kind: .connect, componentID: ""))
        XCTAssertTrue(harness.session.channelOpen)
        XCTAssertEqual(try harness.outboundEnvelopes().filter { $0.kind == .`init` }.count, 1)
    }

    func testDocumentResetClearsResizeThresholds() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["height": .number(200)]
        ))
        XCTAssertEqual(resizes.count, 1)
        XCTAssertEqual(resizes[0].1, 200)

        harness.session.resetForNewDocument()
        harness.connect()
        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["height": .number(200)]
        ))

        XCTAssertEqual(resizes.count, 2)
        XCTAssertEqual(resizes[1].1, 200)
    }

    func testDocumentResetInvokesOnDocumentReset() {
        let harness = Harness()
        var resets = 0
        harness.session.onDocumentReset = { resets += 1 }
        harness.connect()
        harness.session.resetForNewDocument()
        XCTAssertEqual(resets, 1)
        XCTAssertFalse(harness.session.channelOpen)
    }

    // MARK: - Round trip through a real WKWebView

    func testRoundTripThroughRealWebView() throws {
        let expectedURL = URL(string: "https://example.com/index.html")!
        var received: [PaywallWebViewMessage] = []
        let session = WebViewSession(
            componentID: "web",
            protocolVersion: 1,
            expectedOrigin: "https://example.com",
            localeIdentifier: "en_US",
            fitAxes: (width: false, height: false),
            messageHandler: PaywallWebViewMessageAction { message, _ in received.append(message) }
        )

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(
            WeakScriptMessageHandler(session),
            name: WebViewEnvelope.messageHandlerName
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        session.evaluateJavaScript = { [weak webView] script in
            webView?.evaluateJavaScript(script)
        }
        session.currentURL = { [weak webView] in
            webView?.url
        }

        let loaded = self.expectation(description: "web view finished loading")
        let delegate = RoundTripNavigationDelegate { loaded.fulfill() }
        webView.navigationDelegate = delegate
        webView.loadHTMLString("<html><body>hi</body></html>", baseURL: expectedURL)
        self.wait(for: [loaded], timeout: 10)

        webView.evaluateJavaScript(
            """
            window.webkit.messageHandlers.\(WebViewEnvelope.messageHandlerName).postMessage(
            '{"channel":"rc-web-components","protocol_version":1,"kind":"connect","component_id":""}'
            );
            window.webkit.messageHandlers.\(WebViewEnvelope.messageHandlerName).postMessage(
            '{"channel":"rc-web-components","protocol_version":1,"kind":"message",\
            "component_id":"web","type":"rc:step-loaded"}'
            ); true
            """
        )

        let delivered = self.expectation(description: "message delivered to the app handler")
        func poll() {
            if received.contains(where: { $0.type == WebViewEnvelope.messageTypeStepLoaded }) {
                delivered.fulfill()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { poll() }
            }
        }
        poll()
        self.wait(for: [delivered], timeout: 10)

        XCTAssertTrue(session.channelOpen)
        XCTAssertEqual(received.last?.type, WebViewEnvelope.messageTypeStepLoaded)
        withExtendedLifetime(delegate) {}
        configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewEnvelope.messageHandlerName
        )
    }

    func testRenderOnlyWebViewExposesNoBridgeSurface() throws {
        // Render-only mode (`componentID == nil`) registers NO script message handler, so page
        // JavaScript must see no native bridge surface at all.
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

        let loaded = self.expectation(description: "web view finished loading")
        loaded.assertForOverFulfill = false
        let delegate = RoundTripNavigationDelegate(
            onFinish: { loaded.fulfill() },
            onFail: { loaded.fulfill() }
        )
        webView.navigationDelegate = delegate
        // about:blank avoids network/ATS flakiness seen with https base URLs in CI.
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        self.wait(for: [loaded], timeout: 10)

        let probed = self.expectation(description: "probed bridge surface")
        var bridgeExposed: Bool?
        webView.evaluateJavaScript(
            """
            (typeof window.webkit !== 'undefined' \
            && typeof window.webkit.messageHandlers !== 'undefined' \
            && typeof window.webkit.messageHandlers.\(WebViewEnvelope.messageHandlerName) !== 'undefined')
            """
        ) { result, _ in
            bridgeExposed = result as? Bool
            probed.fulfill()
        }
        self.wait(for: [probed], timeout: 10)

        XCTAssertEqual(bridgeExposed, false)
        withExtendedLifetime(delegate) {}
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class RoundTripNavigationDelegate: NSObject, WKNavigationDelegate {

    private let onFinish: () -> Void
    private let onFail: (() -> Void)?

    init(onFinish: @escaping () -> Void, onFail: (() -> Void)? = nil) {
        self.onFinish = onFinish
        self.onFail = onFail
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.onFinish()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.onFail?()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        self.onFail?()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
private final class Harness {

    let session: WebViewSession
    var capturedScripts: [String] = []
    var messages: [PaywallWebViewMessage] = []
    var currentURL = URL(string: "https://example.com/path")!

    init(
        size: (width: Bool, height: Bool) = (false, false),
        localeIdentifier: String = "en_US",
        messageHandler: PaywallWebViewMessageAction? = nil
    ) {
        self.session = WebViewSession(
            componentID: "web",
            protocolVersion: 99,
            expectedOrigin: "https://example.com",
            localeIdentifier: localeIdentifier,
            fitAxes: size,
            messageHandler: nil
        )
        self.session.messageHandler = messageHandler ?? PaywallWebViewMessageAction { [weak self] message, _ in
            self?.messages.append(message)
        }
        self.session.evaluateJavaScript = { [weak self] script in
            self?.capturedScripts.append(script)
        }
        self.session.currentURL = { [weak self] in
            self?.currentURL
        }
    }

    func connect() {
        self.handle(.init(kind: .connect, componentID: ""))
        self.capturedScripts.removeAll()
    }

    func handle(_ envelope: WebViewEnvelope.Envelope, isMainFrame: Bool = true) {
        let data = try! JSONEncoder().encode(envelope)
        self.session.handle(
            rawMessage: String(data: data, encoding: .utf8)!,
            isMainFrame: isMainFrame,
            currentURL: self.currentURL
        )
    }

    func outboundEnvelopes() throws -> [WebViewEnvelope.Envelope] {
        try self.capturedScripts.map {
            try WebViewEnvelopeTests.decodeEnvelope(fromScript: $0)
        }
    }

}

#endif
