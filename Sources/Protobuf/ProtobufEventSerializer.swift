#if ENABLE_PROTOBUF
import Foundation
import SwiftProtobuf

/// Serializes and deserializes event data using Protocol Buffers.
enum ProtobufEventSerializer {

    /// Serializes an array of event dictionaries into a protobuf binary payload.
    static func serialize(events: [[String: Any]]) throws -> Data {
        var request = RCEventRequest()
        request.events = events.map { dict in
            var event = RCEvent()
            event.id = dict["id"] as? String ?? ""
            event.type = dict["type"] as? String ?? ""
            event.appUserID = dict["app_user_id"] as? String ?? ""
            event.timestampMillis = dict["timestamp_millis"] as? Int64 ?? 0
            if let props = dict["properties"] as? [String: String] {
                event.properties = props
            }
            return event
        }
        return try request.serializedData()
    }

    /// Deserializes a protobuf binary payload into an `RCEventRequest`.
    static func deserialize(data: Data) throws -> RCEventRequest {
        return try RCEventRequest(serializedBytes: data)
    }

    /// Deserializes a protobuf binary payload into an `RCEventResponse`.
    static func deserializeResponse(data: Data) throws -> RCEventResponse {
        return try RCEventResponse(serializedBytes: data)
    }

}
#endif
