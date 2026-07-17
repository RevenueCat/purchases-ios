//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest
// swiftlint:disable force_try

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewEnvelopeTests: TestCase {

    func testDecodesValidConnectFrame() throws {
        let envelope = WebViewEnvelope.decode(rawMessage: Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "connect",
            "component_id": ""
        ]))

        XCTAssertEqual(envelope?.kind, .connect)
        XCTAssertEqual(envelope?.protocolVersion, 1)
        XCTAssertEqual(envelope?.componentID, "")
    }

    func testRejectsMalformedFrames() {
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: Self.json([
            "channel": "wrong",
            "protocol_version": 1,
            "kind": "connect",
            "component_id": ""
        ])))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "unknown",
            "component_id": ""
        ])))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "message"
        ])))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: "{not json"))
    }

    func testRejectsNonStringFrames() {
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: Self.frame(payload: ["value": "valid JSON"])))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: 1))
    }

    func testDoesNotEnforceClientSideByteLimit() {
        let payload = String(repeating: "x", count: 65_537)
        let frame = Self.frame(payload: ["value": payload])

        XCTAssertNotNil(WebViewEnvelope.decode(rawMessage: Self.json(frame)))
    }

    func testDoesNotEnforceClientSideDepthLimit() {
        XCTAssertNotNil(
            WebViewEnvelope.decode(rawMessage: Self.json(Self.frame(payload: Self.nestedObject(depth: 16))))
        )
    }

    func testEncodeDecodeRoundTripAndEscaping() throws {
        let hostile = "annual\" }); alert('xss'); //\n</script>\\ end\u{2028}\u{2029}"
        let envelope = WebViewEnvelope.Envelope(
            kind: .message,
            componentID: "web",
            type: "rc:variables",
            payload: ["value": .string(hostile)]
        )

        let script = try XCTUnwrap(WebViewEnvelope.receiveScript(for: envelope))
        XCTAssertFalse(script.contains("\u{2028}"))
        XCTAssertFalse(script.contains("\u{2029}"))

        let decoded = try Self.decodeEnvelope(fromScript: script)
        XCTAssertEqual(decoded, envelope)
        XCTAssertEqual(decoded.payload?["value"]?.stringValue, hostile)
    }

    func testKindCodableRoundTrip() throws {
        let kinds: [WebViewEnvelope.Kind] = [
            .connect,
            .`init`,
            .reject,
            .message,
            .request,
            .response,
            .error
        ]

        for kind in kinds {
            let data = try JSONEncoder().encode(kind)
            XCTAssertEqual(try JSONDecoder().decode(WebViewEnvelope.Kind.self, from: data), kind)
        }
    }

    func testReservedPayloadKeysMatchWireProtocol() {
        XCTAssertEqual(
            WebViewEnvelope.reservedPayloadKeys,
            ["channel", "protocol_version", "kind", "type", "component_id", "id", "error", "variables"]
        )
    }

    private static func frame(payload: [String: Any]) -> [String: Any] {
        [
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "message",
            "component_id": "web",
            "type": "rc:step-loaded",
            "payload": payload
        ]
    }

    private static func nestedObject(depth: Int) -> [String: Any] {
        var value: [String: Any] = ["leaf": true]
        for _ in 0..<depth {
            value = ["child": value]
        }
        return value
    }

    static func json(_ object: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: object)
        return String(data: data, encoding: .utf8)!
    }

    static func decodeEnvelope(fromScript script: String) throws -> WebViewEnvelope.Envelope {
        let start = try XCTUnwrap(script.range(of: "var m=")?.upperBound)
        let end = try XCTUnwrap(script.range(of: ";if", range: start..<script.endIndex)?.lowerBound)
        let json = String(script[start..<end])
        return try JSONDecoder().decode(WebViewEnvelope.Envelope.self, from: Data(json.utf8))
    }

}

#endif
