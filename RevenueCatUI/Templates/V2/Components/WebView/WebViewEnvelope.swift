//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WebViewEnvelope {

    static let channel = "rc-web-components"
    static let messageHandlerName = "rcWebComponents"
    /// Name of the JS function injected into the web view that receives host-to-content frames.
    static let receiveFunction = "__rcWebComponentsReceive"
    static let defaultProtocolVersion = PaywallComponent.WebViewComponent.supportedProtocolVersion

    static let messageTypeResize = "resize"
    static let messageTypeFit = "fit"

    static let maxResizePoints: CGFloat = 10_000
    static let resizeThreshold: CGFloat = 1
    static let fallbackFitHeight: CGFloat = 100
    static let fallbackFitWidth: CGFloat = 300

    // swiftlint:disable nesting
    enum Kind: String, Codable {
        case connect
        case `init`
        case reject
        case message
        case request
        case response
        case error
    }

    /// One JSON message exchanged with the `web_view` content. Fields used vary by ``kind``.
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
    // swiftlint:enable nesting

    static func decode(rawMessage: Any) -> Envelope? {
        // `workflow-web-components-sdk` sends frames with `postMessage(JSON.stringify(frame))`.
        guard let string = rawMessage as? String,
              let data = string.data(using: .utf8) else {
            return nil
        }

        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.channel == Self.channel else {
            return nil
        }

        return envelope
    }

}

#endif
