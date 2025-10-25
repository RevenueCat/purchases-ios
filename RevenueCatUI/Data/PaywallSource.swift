// swiftlint:disable missing_docs
//
//  PaywallSource.swift
//
//
//  Created by RevenueCat on 2/26/25.
//

/// Identifies where a paywall was presented from so that backend analytics can classify the event.
@_spi(Internal) public struct PaywallSource: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {

    /// Raw backend identifier describing the source.
    public let rawValue: String

    public typealias StringLiteralType = String

    /// Creates a typed paywall source from a raw backend identifier.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Allows initializing from string literals (e.g. `PaywallSource("foo")`).
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

}

@_spi(Internal) public extension PaywallSource {

    /// Source identifier used when the paywall originated from Customer Center.
    static let customerCenter: PaywallSource = "presented_from_customer_center"

}
// swiftlint:enable missing_docs
