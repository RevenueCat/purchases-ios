import Foundation
import SwiftUI
// swiftlint:disable missing_docs

#if !os(tvOS) // For Paywalls V2

/// A validated message sent from a Paywalls V2 `web_view` component to your app.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct PaywallWebViewMessage: Sendable, Equatable {

    /// The identifier of the `web_view` component that produced this message.
    public let componentID: String

    /// The message type, e.g. `"rc:step-complete"`.
    public let type: String

    /// The responses collected by the web flow. Only populated for `"rc:step-complete"` messages.
    public let responses: [String: PaywallWebViewValue]?

    /// The error reported by the web content. Only populated for `"rc:error"` messages.
    public let error: String?

    public init(
        componentID: String,
        type: String,
        responses: [String: PaywallWebViewValue]? = nil,
        error: String? = nil
    ) {
        self.componentID = componentID
        self.type = type
        self.responses = responses
        self.error = error
    }

}

/// A JSON-compatible value exchanged between a Paywalls V2 `web_view` component and your app.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct PaywallWebViewValue: Sendable, Equatable, Hashable, Codable {

    private indirect enum Storage: Sendable, Equatable, Hashable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case array([PaywallWebViewValue])
        case object([String: PaywallWebViewValue])
        case null
    }

    private let storage: Storage

    private init(_ storage: Storage) {
        self.storage = storage
    }

    /// Creates a string value.
    public static func string(_ value: String) -> Self { Self(.string(value)) }

    /// Creates a numeric value. Non-finite values normalize to ``null`` because JSON cannot encode them.
    public static func number(_ value: Double) -> Self { value.isFinite ? Self(.number(value)) : .null }

    /// Creates a boolean value.
    public static func bool(_ value: Bool) -> Self { Self(.bool(value)) }

    /// Creates an array value.
    public static func array(_ value: [PaywallWebViewValue]) -> Self { Self(.array(value)) }

    /// Creates an object (dictionary) value.
    public static func object(_ value: [String: PaywallWebViewValue]) -> Self { Self(.object(value)) }

    /// A null value.
    public static var null: Self { Self(.null) }

    public var stringValue: String? {
        if case .string(let value) = self.storage { return value }
        return nil
    }

    public var numberValue: Double? {
        if case .number(let value) = self.storage { return value }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self.storage { return value }
        return nil
    }

    public var arrayValue: [PaywallWebViewValue]? {
        if case .array(let value) = self.storage { return value }
        return nil
    }

    public var objectValue: [String: PaywallWebViewValue]? {
        if case .object(let value) = self.storage { return value }
        return nil
    }

    public var isNull: Bool {
        if case .null = self.storage { return true }
        return false
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([PaywallWebViewValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: PaywallWebViewValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self.storage {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct PaywallWebViewController {

    #if canImport(WebKit)
    weak var session: WebViewSession?
    #endif

    init() {}

    #if canImport(WebKit)
    init(session: WebViewSession?) {
        self.session = session
    }
    #endif

    public func postVariables(componentID: String, variables: [String: PaywallWebViewValue]) {
        #if canImport(WebKit)
        self.session?.postVariables(componentID: componentID, variables: variables)
        #endif
    }

    public func postMessage(componentID: String, type: String, variables: [String: PaywallWebViewValue]) {
        #if canImport(WebKit)
        self.session?.post(componentID: componentID, type: type, variables: variables)
        #endif
    }

}

/// A wrapper for the Paywalls V2 `web_view` message handler.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct PaywallWebViewMessageAction {

    private let action: @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void

    public init(
        _ action: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void
    ) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ message: PaywallWebViewMessage, _ controller: PaywallWebViewController) {
        self.action(message, controller)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewMessageActionKey: EnvironmentKey {
    static let defaultValue: PaywallWebViewMessageAction? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallWebViewMessageAction: PaywallWebViewMessageAction? {
        get { self[PaywallWebViewMessageActionKey.self] }
        set { self[PaywallWebViewMessageActionKey.self] = newValue }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Invokes the given closure when a Paywalls V2 `web_view` component sends a message.
    public func onPaywallWebViewMessage(
        _ action: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void
    ) -> some View {
        self.environment(\.paywallWebViewMessageAction, PaywallWebViewMessageAction(action))
    }

}

#endif
