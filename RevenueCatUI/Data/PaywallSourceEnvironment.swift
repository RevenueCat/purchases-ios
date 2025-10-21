//
//  PaywallSourceEnvironment.swift
//
//
//  Created by RevenueCat on 2/26/25.
//

#if canImport(SwiftUI)

import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
/// Identifies where a paywall was presented from so that backend analytics can classify the event.
@_spi(Internal) public struct PaywallSource: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {

    public let rawValue: String

    public typealias StringLiteralType = String

    /// Creates a typed paywall source from a raw string.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Allows initializing from string literals (e.g. `PaywallSource("foo")`).
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public extension PaywallSource {

    /// Source identifier used when the paywall originated from Customer Center.
    static let customerCenter: PaywallSource = "presented_from_customer_center"

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallSourceKey: EnvironmentKey {

    static let defaultValue: PaywallSource? = nil

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// The optional paywall source available in the current environment.
    @_spi(Internal) public var paywallSource: PaywallSource? {
        get { self[PaywallSourceKey.self] }
        set { self[PaywallSourceKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Associates the provided paywall source with this view hierarchy so downstream paywall presentations can read it.
    @_spi(Internal) public func paywallSource(_ source: PaywallSource?) -> some View {
        self.environment(\.paywallSource, source)
    }

}

#endif

#endif
