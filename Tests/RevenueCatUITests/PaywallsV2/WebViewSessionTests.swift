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
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }

        // A resize before the handshake is dropped (channel closed).
        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["height": .number(200)]
        ))
        XCTAssertTrue(resizes.isEmpty)

        harness.handle(.init(kind: .connect, componentID: ""))
        harness.handle(.init(kind: .connect, componentID: ""))
        XCTAssertEqual(try harness.outboundEnvelopes().filter { $0.kind == .`init` }.count, 1)

        // A resize from a subframe is dropped even after the channel is open.
        harness.handle(
            .init(
                kind: .message,
                componentID: "web",
                type: WebViewEnvelope.messageTypeResize,
                payload: ["height": .number(200)]
            ),
            isMainFrame: false
        )
        XCTAssertTrue(resizes.isEmpty)
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
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        // Each carries a payload that would apply if the kind gate let it through.
        for kind: WebViewEnvelope.Kind in [.`init`, .reject, .response, .error] {
            harness.handle(.init(
                kind: kind,
                componentID: "web",
                type: WebViewEnvelope.messageTypeResize,
                id: "id-1",
                payload: ["height": .number(200)]
            ))
        }

        XCTAssertTrue(resizes.isEmpty)
    }

    func testDropsAnyRequestWithoutID() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(.init(
            kind: .request,
            componentID: "web",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["height": .number(200)]
        ))

        XCTAssertTrue(resizes.isEmpty)
    }

    func testDropsAppFrameFromDifferentComponent() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        // Same shape as an applied resize, but addressed to another component on the same page.
        harness.handle(.init(
            kind: .message,
            componentID: "other",
            type: WebViewEnvelope.messageTypeResize,
            payload: ["height": .number(200)]
        ))

        XCTAssertTrue(resizes.isEmpty)
    }

    func testDropsUnknownMessageType() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(.init(
            kind: .message,
            componentID: "web",
            type: "rc:not-a-real-type",
            payload: ["height": .number(200)]
        ))

        XCTAssertTrue(resizes.isEmpty)
    }

    func testDropsMessageWithoutType() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(.init(kind: .message, componentID: "web", payload: ["height": .number(200)]))

        XCTAssertTrue(resizes.isEmpty)
    }

    func testDropsEnvelopeOnUnexpectedChannel() {
        let harness = Harness()

        // Well-formed connect frame, but riding another SDK's channel: it must never open ours.
        harness.session.handle(
            rawMessage: #"{"channel":"someone-elses-channel","protocol_version":1,"kind":"connect","component_id":""}"#,
            isMainFrame: true,
            sourceOrigin: Harness.expectedOriginString
        )

        XCTAssertFalse(harness.session.channelOpen)
        XCTAssertTrue(harness.capturedScripts.isEmpty)
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

        harness.capturedScripts.removeAll()
        harness.handle(.init(kind: .message, componentID: "web", type: WebViewEnvelope.messageTypeResize))
        XCTAssertTrue(harness.capturedScripts.isEmpty)

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

    // MARK: - Origin gating

    func testDropsInboundFromUntrustedOrigin() {
        let harness = Harness(size: (width: false, height: true))
        var resizes: [(CGFloat?, CGFloat?)] = []
        harness.session.onContentResize = { resizes.append(($0, $1)) }
        harness.connect()

        harness.handle(
            .init(
                kind: .message,
                componentID: "web",
                type: WebViewEnvelope.messageTypeResize,
                payload: ["height": .number(200)]
            ),
            sourceOrigin: "https://evil.example.org"
        )

        XCTAssertTrue(resizes.isEmpty)
    }

    func testDropsConnectFromUntrustedOrigin() {
        let harness = Harness()

        harness.handle(.init(kind: .connect, componentID: ""), sourceOrigin: "https://evil.example.org")

        XCTAssertFalse(harness.session.channelOpen)
        XCTAssertTrue(harness.capturedScripts.isEmpty)
    }

    func testDropsInboundWithoutSourceOrigin() {
        let harness = Harness()

        harness.handle(.init(kind: .connect, componentID: ""), sourceOrigin: nil)

        XCTAssertFalse(harness.session.channelOpen)
        XCTAssertTrue(harness.capturedScripts.isEmpty)
    }

    func testConnectBeforeNavigationURLIsAvailable() throws {
        let harness = Harness()
        harness.currentURL = nil

        harness.handle(.init(kind: .connect, componentID: ""))

        XCTAssertTrue(harness.session.channelOpen)
        XCTAssertEqual(try harness.outboundEnvelopes().map(\.kind), [.`init`])
    }

    func testNormalizesExpectedOriginFromFullURL() {
        // Caller resolves the origin from a full URL (path, uppercase host, explicit default port).
        // It must canonicalize so trusted same-origin traffic still matches.
        let harness = Harness(expectedOrigin: WebViewOrigin(string: "https://Example.com:443/paywall/index.html")!)

        harness.handle(.init(kind: .connect, componentID: ""), sourceOrigin: "https://example.com")

        XCTAssertTrue(harness.session.channelOpen)
    }

    func testDeliversOutboundOnSameOriginDifferentPath() throws {
        let harness = Harness(size: (width: false, height: true))
        harness.currentURL = URL(string: "https://example.com/promo/step-two.html")!

        harness.handle(.init(kind: .connect, componentID: ""))

        XCTAssertEqual(try harness.outboundEnvelopes().map(\.kind), [.`init`, .message])
    }

    // An origin that cannot be resolved no longer reaches the session: `WebViewOrigin`'s failable
    // init returns `nil`, so the web view is never created (see `WebViewOriginTests` and
    // `WebViewComponentViewTests`). The session is therefore guaranteed a valid origin.

    func testDropsOutboundAfterNavigationToUnexpectedOrigin() {
        let harness = Harness()
        // Inbound source is still the trusted origin, but the top-level URL has left it: every
        // outbound frame (even `init`) must be dropped. Because `init` never reaches the page, the
        // channel must stay closed so a later `connect` can retry instead of stranding it half-open.
        harness.currentURL = URL(string: "https://evil.example.org/phish.html")!

        harness.handle(.init(kind: .connect, componentID: ""))

        XCTAssertFalse(harness.session.channelOpen)
        XCTAssertTrue(harness.capturedScripts.isEmpty)
    }

    func testConnectRetriesAfterDroppedInitFromUntrustedURL() throws {
        let harness = Harness(size: (width: false, height: true))
        // First `connect` arrives while the top-level URL is off-origin, so `init` is dropped and
        // the channel must remain closed.
        harness.currentURL = URL(string: "https://evil.example.org/phish.html")!
        harness.handle(.init(kind: .connect, componentID: ""))
        XCTAssertFalse(harness.session.channelOpen)
        XCTAssertTrue(harness.capturedScripts.isEmpty)

        // Once the top-level URL is back on the expected origin, a retried `connect` opens the
        // channel and delivers `init` (+ fit) — the bridge is not stuck from the earlier failure.
        harness.currentURL = URL(string: "https://example.com/path")!
        harness.handle(.init(kind: .connect, componentID: ""))

        XCTAssertTrue(harness.session.channelOpen)
        XCTAssertEqual(try harness.outboundEnvelopes().map(\.kind), [.`init`, .message])
    }

    func testConnectRetriesAfterInitDeliveryMiss() throws {
        let harness = Harness()
        // Simulate the backing web view being unavailable when the first `connect` arrives: the
        // `init` frame is never handed off, so the channel must stay closed.
        harness.deliverOutbound = false
        harness.handle(.init(kind: .connect, componentID: ""))
        XCTAssertFalse(harness.session.channelOpen)
        XCTAssertTrue(harness.capturedScripts.isEmpty)

        // With the web view available again, a retried `connect` opens the channel and delivers init.
        harness.deliverOutbound = true
        harness.handle(.init(kind: .connect, componentID: ""))

        XCTAssertTrue(harness.session.channelOpen)
        XCTAssertEqual(try harness.outboundEnvelopes().map(\.kind), [.`init`])
    }

    // MARK: - Round trip through a real WKWebView

    func testRoundTripThroughRealWebView() throws {
        let expectedURL = URL(string: "https://example.com/index.html")!
        let session = WebViewSession(
            componentID: "web",
            expectedOrigin: WebViewOrigin(string: "https://example.com")!,
            fitAxes: (width: false, height: false),
            evaluateJavaScript: { _ in false },
            currentURL: { nil }
        )

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(
            WeakScriptMessageHandler(session),
            name: WebViewEnvelope.messageHandlerName
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        session.evaluateJavaScript = { [weak webView] script in
            guard let webView else { return false }
            webView.evaluateJavaScript(script)
            return true
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
            ); true
            """
        )

        let connected = self.expectation(description: "handshake completed through the real web view")
        func poll() {
            if session.channelOpen {
                connected.fulfill()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { poll() }
            }
        }
        poll()
        self.wait(for: [connected], timeout: 10)

        XCTAssertTrue(session.channelOpen)
        withExtendedLifetime(delegate) {}
        configuration.userContentController.removeScriptMessageHandler(
            forName: WebViewEnvelope.messageHandlerName
        )
    }

    func testRenderOnlyWebViewExposesNoBridgeSurface() throws {
        // A web view configured without the bridge (no script message handler registered) must
        // expose no native bridge surface to page JavaScript at all.
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

    // MARK: - receiveScript

    func testReceiveScriptEscapesLineSeparatorsAndRoundTrips() throws {
        let hostile = "annual\" }); alert('xss'); //\n</script>\\ end\u{2028}\u{2029}"
        let envelope = WebViewEnvelope.Envelope(
            kind: .message,
            componentID: "web",
            type: "rc:variables",
            payload: ["value": .string(hostile)]
        )

        let script = try XCTUnwrap(WebViewSession.receiveScript(for: envelope))
        XCTAssertFalse(script.contains("\u{2028}"))
        XCTAssertFalse(script.contains("\u{2029}"))

        let decoded = try Self.decodeEnvelope(fromScript: script)
        XCTAssertEqual(decoded, envelope)
        XCTAssertEqual(decoded.payload?["value"]?.stringValue, hostile)
    }

    static func decodeEnvelope(fromScript script: String) throws -> WebViewEnvelope.Envelope {
        let start = try XCTUnwrap(script.range(of: "var m=")?.upperBound)
        let end = try XCTUnwrap(script.range(of: ";if", range: start..<script.endIndex)?.lowerBound)
        let json = String(script[start..<end])
        return try JSONDecoder().decode(WebViewEnvelope.Envelope.self, from: Data(json.utf8))
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

    nonisolated static let expectedOriginString = "https://example.com"
    nonisolated static let expectedOrigin = WebViewOrigin(string: Harness.expectedOriginString)!

    let session: WebViewSession
    var capturedScripts: [String] = []
    var currentURL: URL? = URL(string: "https://example.com/path")!
    /// Simulates a delivery miss (e.g. a released web view): when `false`, outbound frames are not
    /// captured and `evaluateJavaScript` reports failure.
    var deliverOutbound = true

    init(
        size: (width: Bool, height: Bool) = (false, false),
        expectedOrigin: WebViewOrigin = Harness.expectedOrigin
    ) {
        self.session = WebViewSession(
            componentID: "web",
            expectedOrigin: expectedOrigin,
            fitAxes: size,
            evaluateJavaScript: { _ in false },
            currentURL: { nil }
        )
        self.session.evaluateJavaScript = { [weak self] script in
            guard let self, self.deliverOutbound else {
                return false
            }
            self.capturedScripts.append(script)
            return true
        }
        self.session.currentURL = { [weak self] in
            self?.currentURL
        }
    }

    func connect() {
        self.handle(.init(kind: .connect, componentID: ""))
        self.capturedScripts.removeAll()
    }

    func handle(
        _ envelope: WebViewEnvelope.Envelope,
        isMainFrame: Bool = true,
        sourceOrigin: String? = Harness.expectedOriginString
    ) {
        let data = try! JSONEncoder().encode(envelope)
        self.session.handle(
            rawMessage: String(data: data, encoding: .utf8)!,
            isMainFrame: isMainFrame,
            sourceOrigin: sourceOrigin
        )
    }

    func outboundEnvelopes() throws -> [WebViewEnvelope.Envelope] {
        try self.capturedScripts.map {
            try WebViewSessionTests.decodeEnvelope(fromScript: $0)
        }
    }

}

#endif
