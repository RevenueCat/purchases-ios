//
//  PaywallSource.swift
//
//
//  Created by RevenueCat on 2/26/25.
//

/// Identifies where a paywall was presented from so that backend analytics can classify the event.
struct PaywallSource: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {

    let rawValue: String

    typealias StringLiteralType = String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }

}

extension PaywallSource {

    /// Source identifier used when the paywall originated from Customer Center.
    static let customerCenter: PaywallSource = "customer_center"

}
