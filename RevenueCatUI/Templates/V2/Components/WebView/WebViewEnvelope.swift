import Foundation
// swiftlint:disable nesting

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewEnvelope {

    static let channel = "rc-web-components"
    static let messageHandlerName = "rcWebComponents"
    static let receiveFunction = "__rcWebComponentsReceive"
    static let defaultProtocolVersion = 1

    static let messageTypeStepLoaded = "rc:step-loaded"
    static let messageTypeStepComplete = "rc:step-complete"
    static let messageTypeRequestVariables = "rc:request-variables"
    static let messageTypeVariables = "rc:variables"
    static let messageTypeError = "rc:error"
    static let messageTypeResize = "resize"
    static let messageTypeFit = "fit"

    static let maxInboundFrameBytes = 65_536
    static let maxJSONDepth = 16
    static let maxResizePoints: CGFloat = 10_000
    static let resizeThreshold: CGFloat = 1
    static let fallbackFitHeight: CGFloat = 100
    static let fallbackFitWidth: CGFloat = 300

    enum Kind: String, Codable {
        case connect
        case `init`
        case reject
        case message
        case request
        case response
        case error
    }

    struct Envelope: Codable, Equatable {
        let channel: String
        let protocolVersion: Int
        let kind: Kind
        let componentID: String
        let type: String?
        let id: String?
        let payload: [String: PaywallWebViewValue]?
        let error: String?

        init(
            kind: Kind,
            componentID: String,
            type: String? = nil,
            id: String? = nil,
            payload: [String: PaywallWebViewValue]? = nil,
            error: String? = nil,
            protocolVersion: Int = WebViewEnvelope.defaultProtocolVersion
        ) {
            self.channel = WebViewEnvelope.channel
            self.protocolVersion = protocolVersion
            self.kind = kind
            self.componentID = componentID
            self.type = type
            self.id = id
            self.payload = payload
            self.error = error
        }

        enum CodingKeys: String, CodingKey {
            case channel
            case protocolVersion = "protocol_version"
            case kind
            case componentID = "component_id"
            case type
            case id
            case payload
            case error
        }
    }

    static func decode(rawMessage: Any) -> Envelope? {
        let data: Data
        if let string = rawMessage as? String {
            guard string.utf8.count <= Self.maxInboundFrameBytes,
                  let stringData = string.data(using: .utf8) else {
                return nil
            }
            data = stringData
        } else if let dictionary = rawMessage as? [String: Any] {
            guard JSONSerialization.isValidJSONObject(dictionary),
                  let serialized = try? JSONSerialization.data(withJSONObject: dictionary),
                  serialized.count <= Self.maxInboundFrameBytes else {
                return nil
            }
            data = serialized
        } else {
            return nil
        }

        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.channel == Self.channel else {
            return nil
        }

        if let payload = envelope.payload,
           PaywallWebViewValue.object(payload).maximumDepth() > Self.maxJSONDepth {
            return nil
        }

        return envelope
    }

    static func receiveScript(for envelope: Envelope) -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(envelope),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        let escaped = json
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")

        return """
        (function(){var m=\(escaped);if(typeof window.\(Self.receiveFunction)==='function'){\
        window.\(Self.receiveFunction)(m);}})();
        """
    }

    static let reservedPayloadKeys: Set<String> = [
        "channel", "protocol_version", "kind", "type", "component_id", "id", "error", "variables"
    ]

}

#endif
