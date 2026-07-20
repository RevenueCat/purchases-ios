//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewEnvelopeTests: TestCase {

    func testDecodesValidConnectFrame() throws {
        let envelope = WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "connect",
            "component_id": ""
        ]))

        XCTAssertEqual(envelope?.kind, .connect)
        XCTAssertEqual(envelope?.protocolVersion, 1)
        XCTAssertEqual(envelope?.componentID, "")
    }

    func testRejectsMalformedFrames() throws {
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": "wrong",
            "protocol_version": 1,
            "kind": "connect",
            "component_id": ""
        ])))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "unknown",
            "component_id": ""
        ])))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
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

    func testDoesNotEnforceClientSideByteLimit() throws {
        let payload = String(repeating: "x", count: 65_537)
        let frame = Self.frame(payload: ["value": payload])

        XCTAssertNotNil(WebViewEnvelope.decode(rawMessage: try Self.json(frame)))
    }

    func testDoesNotEnforceClientSideDepthLimit() throws {
        XCTAssertNotNil(
            WebViewEnvelope.decode(rawMessage: try Self.json(Self.frame(payload: Self.nestedObject(depth: 16))))
        )
    }

    func testEncodedFrameUsesSnakeCaseKeysAndOmitsNilFields() throws {
        let envelope = WebViewEnvelope.Envelope(kind: .connect, componentID: "web")

        let data = try JSONEncoder().encode(envelope)
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(Set(object.keys), ["channel", "protocol_version", "kind", "component_id"])
        XCTAssertEqual(object["channel"] as? String, WebViewEnvelope.channel)
        XCTAssertEqual(object["protocol_version"] as? Int, 1)
        XCTAssertEqual(object["kind"] as? String, "connect")
        XCTAssertEqual(object["component_id"] as? String, "web")
    }

    func testDecodesFullMessageFrameWithRichPayload() throws {
        let envelope = try XCTUnwrap(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "response",
            "component_id": "web",
            "type": "rc:variables",
            "id": "req-1",
            "payload": [
                "string": "value",
                "number": 1.25,
                "bool": true,
                "nested": ["inner": false],
                "list": [1, 2, 3],
                "nothing": NSNull()
            ]
        ])))

        XCTAssertEqual(envelope.kind, .response)
        XCTAssertEqual(envelope.componentID, "web")
        XCTAssertEqual(envelope.type, "rc:variables")
        XCTAssertEqual(envelope.id, "req-1")

        let payload = try XCTUnwrap(envelope.payload)
        XCTAssertEqual(payload["string"]?.stringValue, "value")
        XCTAssertEqual(payload["number"]?.numberValue, 1.25)
        XCTAssertEqual(payload["bool"]?.boolValue, true)
        XCTAssertEqual(payload["nested"]?.objectValue?["inner"]?.boolValue, false)
        XCTAssertEqual(payload["list"]?.arrayValue?.count, 3)
        XCTAssertTrue(payload["nothing"]?.isNull == true)
    }

    func testRejectsInvalidProtocolVersion() throws {
        // Missing protocol_version.
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "kind": "message",
            "component_id": "web"
        ])))
        // Fractional protocol_version (integral only).
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1.5,
            "kind": "message",
            "component_id": "web"
        ])))
        // Non-numeric protocol_version.
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": "1",
            "kind": "message",
            "component_id": "web"
        ])))
    }

    func testRejectsNonStringFieldsAndNonObjectPayload() throws {
        // Non-string type.
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "message",
            "component_id": "web",
            "type": 123
        ])))
        // Non-string id.
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "response",
            "component_id": "web",
            "id": 123
        ])))
        // Non-string error.
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "error",
            "component_id": "web",
            "error": 123
        ])))
        // Non-object payload.
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: try Self.json([
            "channel": WebViewEnvelope.channel,
            "protocol_version": 1,
            "kind": "message",
            "component_id": "web",
            "payload": [1, 2, 3]
        ])))
    }

    func testRejectsValidJSONThatIsNotAnObject() {
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: "[1,2,3]"))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: "\"hello\""))
        XCTAssertNil(WebViewEnvelope.decode(rawMessage: "5"))
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

    static func json(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    static func decodeEnvelope(fromScript script: String) throws -> WebViewEnvelope.Envelope {
        let start = try XCTUnwrap(script.range(of: "var m=")?.upperBound)
        let end = try XCTUnwrap(script.range(of: ";if", range: start..<script.endIndex)?.lowerBound)
        let json = String(script[start..<end])
        return try JSONDecoder().decode(WebViewEnvelope.Envelope.self, from: Data(json.utf8))
    }

}

#endif
