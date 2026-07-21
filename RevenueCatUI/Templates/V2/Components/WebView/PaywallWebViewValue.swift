//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation

#if !os(tvOS) // For Paywalls V2

/// A JSON-compatible value exchanged between a Paywalls V2 `web_view` component and your app.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWebViewValue: Sendable, Equatable, Hashable, Codable {

    private enum Storage: Sendable, Equatable, Hashable {
        case string(String)
        // The web peer uses JavaScript `Number` values, so there is no integer precision to preserve.
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
    static func string(_ value: String) -> Self { Self(.string(value)) }

    /// Creates a numeric value. Non-finite values normalize to ``null`` because JSON cannot encode them.
    static func number(_ value: Double) -> Self { value.isFinite ? Self(.number(value)) : .null }

    /// Creates a boolean value.
    static func bool(_ value: Bool) -> Self { Self(.bool(value)) }

    /// Creates an array value.
    static func array(_ value: [PaywallWebViewValue]) -> Self { Self(.array(value)) }

    /// Creates an object (dictionary) value.
    static func object(_ value: [String: PaywallWebViewValue]) -> Self { Self(.object(value)) }

    /// A null value.
    static var null: Self { Self(.null) }

    var stringValue: String? {
        if case .string(let value) = self.storage { return value }
        return nil
    }

    var numberValue: Double? {
        if case .number(let value) = self.storage { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self.storage { return value }
        return nil
    }

    var arrayValue: [PaywallWebViewValue]? {
        if case .array(let value) = self.storage { return value }
        return nil
    }

    var objectValue: [String: PaywallWebViewValue]? {
        if case .object(let value) = self.storage { return value }
        return nil
    }

    var isNull: Bool {
        if case .null = self.storage { return true }
        return false
    }

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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

#endif
