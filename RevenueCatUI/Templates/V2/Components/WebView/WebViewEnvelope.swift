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
    static let messageTypeContext = "context"
    static let messageTypeOpenURL = "open_url"

    static let maxOpenURLLength = 2048
    static let openURLMinimumInterval: TimeInterval = 1

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

/// A validated `open_url` request payload (`{ url, method? }`) from the `web_view` content.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WebViewOpenURLRequest: Equatable {

    typealias Method = PaywallComponent.ButtonComponent.URLMethod

    let url: URL
    let method: Method

    // `deep_link` takes app schemes, but never ones that run code, read local data, or build Android
    // intents. `http` is refused everywhere: universal links are `https`.
    private static let blockedDeepLinkSchemes: Set<String> = [
        "http", "javascript", "vbscript", "data", "file", "blob", "about", "content", "intent"
    ]

    /// Returns `nil` when the request must be refused: `external_browser` and `in_app_browser` take
    /// `https` only, `deep_link` any scheme except the blocked ones, and URLs are capped at
    /// ``WebViewEnvelope/maxOpenURLLength`` characters. `method` defaults to `external_browser`.
    init?(payload: [String: PaywallWebViewValue]?) {
        guard let urlString = payload?["url"]?.stringValue,
              !urlString.isEmpty,
              urlString.count <= WebViewEnvelope.maxOpenURLLength,
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased() else {
            return nil
        }

        let method: Method
        if let rawMethod = payload?["method"] {
            guard let parsed = rawMethod.stringValue.flatMap(Method.init(rawValue:)),
                  parsed != .unknown else {
                return nil
            }
            method = parsed
        } else {
            method = .externalBrowser
        }

        switch method {
        case .externalBrowser, .inAppBrowser:
            guard scheme == "https" else { return nil }
        case .deepLink:
            guard !Self.blockedDeepLinkSchemes.contains(scheme) else { return nil }
        case .unknown:
            return nil
        }

        if scheme == "https" {
            // Embedded credentials can disguise the real host (`https://trusted.com@evil.com`).
            guard url.host?.isEmpty == false,
                  url.user == nil,
                  url.password == nil else {
                return nil
            }
        }

        self.url = url
        self.method = method
    }

}

#endif
