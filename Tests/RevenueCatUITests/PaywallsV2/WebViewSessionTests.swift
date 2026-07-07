//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest
// swiftlint:disable force_try

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
        let harness = Harness(localeIdentifier: "zh_Hans_CN")
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
        XCTAssertEqual(response.payload?["locale"]?.stringValue, "zh-Hans-CN")
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
