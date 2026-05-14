//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

#if !os(tvOS)

// swiftlint:disable missing_docs

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateEdgeInsets: Hashable, Sendable {

    @_spi(Internal) public let top: Double
    @_spi(Internal) public let leading: Double
    @_spi(Internal) public let bottom: Double
    @_spi(Internal) public let trailing: Double

    @_spi(Internal)
    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateJSONValue: Hashable, Sendable {

    private enum Storage: Hashable, Sendable {
        case null
        case string(String)
        case number(Double)
        case bool(Bool)
        case object([String: PaywallStateJSONValue])
        case array([PaywallStateJSONValue])
    }

    private let storage: Storage

    private init(_ storage: Storage) {
        self.storage = storage
    }

    @_spi(Internal) public static let null = PaywallStateJSONValue(.null)

    @_spi(Internal) public static func string(_ value: String) -> PaywallStateJSONValue {
        .init(.string(value))
    }

    @_spi(Internal) public static func number(_ value: Double) -> PaywallStateJSONValue {
        .init(.number(value))
    }

    @_spi(Internal) public static func bool(_ value: Bool) -> PaywallStateJSONValue {
        .init(.bool(value))
    }

    @_spi(Internal) public static func object(_ value: [String: PaywallStateJSONValue]) -> PaywallStateJSONValue {
        .init(.object(value))
    }

    @_spi(Internal) public static func array(_ value: [PaywallStateJSONValue]) -> PaywallStateJSONValue {
        .init(.array(value))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateValue: Hashable, Sendable {

    enum Kind {
        case string
        case number
        case bool
        case packageID
        case json
        case edgeInsets
    }

    private enum Storage: Hashable, Sendable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case packageID(String?)
        case json(PaywallStateJSONValue)
        case edgeInsets(PaywallStateEdgeInsets)
    }

    private let storage: Storage

    private init(_ storage: Storage) {
        self.storage = storage
    }

    @_spi(Internal) public static func string(_ value: String) -> PaywallStateValue {
        .init(.string(value))
    }

    @_spi(Internal) public static func number(_ value: Double) -> PaywallStateValue {
        .init(.number(value))
    }

    @_spi(Internal) public static func bool(_ value: Bool) -> PaywallStateValue {
        .init(.bool(value))
    }

    @_spi(Internal) public static func packageID(_ value: String?) -> PaywallStateValue {
        .init(.packageID(value))
    }

    @_spi(Internal) public static func json(_ value: PaywallStateJSONValue) -> PaywallStateValue {
        .init(.json(value))
    }

    @_spi(Internal) public static func edgeInsets(_ value: PaywallStateEdgeInsets) -> PaywallStateValue {
        .init(.edgeInsets(value))
    }

    @_spi(Internal) public var packageID: String? {
        guard case .packageID(let value) = self.storage else { return nil }
        return value
    }

    @_spi(Internal) public var boolValue: Bool? {
        guard case .bool(let value) = self.storage else { return nil }
        return value
    }

    @_spi(Internal) public var stringValue: String? {
        guard case .string(let value) = self.storage else { return nil }
        return value
    }

    var kind: Kind {
        switch self.storage {
        case .string:
            return .string
        case .number:
            return .number
        case .bool:
            return .bool
        case .packageID:
            return .packageID
        case .json:
            return .json
        case .edgeInsets:
            return .edgeInsets
        }
    }

    var numberValue: Double? {
        guard case .number(let value) = self.storage else { return nil }
        return value
    }

    var jsonValue: PaywallStateJSONValue? {
        guard case .json(let value) = self.storage else { return nil }
        return value
    }

}

// swiftlint:enable missing_docs

#endif
