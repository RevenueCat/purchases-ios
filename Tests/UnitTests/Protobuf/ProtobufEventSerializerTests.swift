import XCTest

@testable import RevenueCat

final class ProtobufEventSerializerTests: XCTestCase {

    func testSerializeAndDeserializeRoundTrip() throws {
        let events: [[String: Any]] = [
            [
                "id": "evt_001",
                "type": "purchase",
                "app_user_id": "user_123",
                "timestamp_millis": Int64(1_700_000_000_000),
                "properties": ["product_id": "com.app.monthly", "price": "9.99"]
            ],
            [
                "id": "evt_002",
                "type": "renewal",
                "app_user_id": "user_456",
                "timestamp_millis": Int64(1_700_000_060_000),
                "properties": ["product_id": "com.app.annual"]
            ]
        ]

        let data = try ProtobufEventSerializer.serialize(events: events)
        XCTAssertFalse(data.isEmpty)

        let decoded = try ProtobufEventSerializer.deserialize(data: data)
        XCTAssertEqual(decoded.events.count, 2)

        let first = decoded.events[0]
        XCTAssertEqual(first.id, "evt_001")
        XCTAssertEqual(first.type, "purchase")
        XCTAssertEqual(first.appUserID, "user_123")
        XCTAssertEqual(first.timestampMillis, 1_700_000_000_000)
        XCTAssertEqual(first.properties["product_id"], "com.app.monthly")
        XCTAssertEqual(first.properties["price"], "9.99")

        let second = decoded.events[1]
        XCTAssertEqual(second.id, "evt_002")
        XCTAssertEqual(second.type, "renewal")
        XCTAssertEqual(second.appUserID, "user_456")
        XCTAssertEqual(second.timestampMillis, 1_700_000_060_000)
        XCTAssertEqual(second.properties["product_id"], "com.app.annual")
    }

    func testSerializeEmptyEvents() throws {
        let data = try ProtobufEventSerializer.serialize(events: [])
        let decoded = try ProtobufEventSerializer.deserialize(data: data)
        XCTAssertTrue(decoded.events.isEmpty)
    }

    func testDeserializeResponse() throws {
        var response = RCEventResponse()
        response.success = true
        response.message = "Events received"

        let data = try response.serializedData()
        let decoded = try ProtobufEventSerializer.deserializeResponse(data: data)

        XCTAssertTrue(decoded.success)
        XCTAssertEqual(decoded.message, "Events received")
    }

    func testProtobufIsSmallerThanJSON() throws {
        let events: [[String: Any]] = (0..<100).map { i in
            [
                "id": "evt_\(i)",
                "type": "purchase",
                "app_user_id": "user_\(i)",
                "timestamp_millis": Int64(1_700_000_000_000 + Int64(i) * 1000),
                "properties": ["product_id": "com.app.monthly", "source": "organic"]
            ]
        }

        let protobufData = try ProtobufEventSerializer.serialize(events: events)
        let jsonData = try JSONSerialization.data(withJSONObject: ["events": events])

        XCTAssertLessThan(
            protobufData.count,
            jsonData.count,
            "Protobuf (\(protobufData.count) bytes) should be smaller than JSON (\(jsonData.count) bytes)"
        )
    }

    func testSerializeWithMissingOptionalFields() throws {
        let events: [[String: Any]] = [
            ["id": "evt_minimal"]
        ]

        let data = try ProtobufEventSerializer.serialize(events: events)
        let decoded = try ProtobufEventSerializer.deserialize(data: data)

        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].id, "evt_minimal")
        XCTAssertEqual(decoded.events[0].type, "")
        XCTAssertEqual(decoded.events[0].appUserID, "")
        XCTAssertEqual(decoded.events[0].timestampMillis, 0)
        XCTAssertTrue(decoded.events[0].properties.isEmpty)
    }

}
