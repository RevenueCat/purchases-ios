//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEvent.swift
//
//  Created by Cesar de la Vega on 6/11/24.

/// An internal event emitted by SDK features that can be stored/sent and also logged for debugging.
@_spi(Internal) public protocol FeatureEvent: Encodable, Sendable {

    /// Feature that emitted this event.
    var feature: Feature { get }

    /// Optional discriminator used to route/store events (e.g. subtypes within a feature).
    var eventDiscriminator: String? { get }

    /// A stable, human-readable name suitable for logging.
    var eventName: String { get }

    /// Stringified key-value parameters suitable for logging.
    var parameters: [String: String] { get }

}

@_spi(Internal) public extension FeatureEvent {

    /// Default: fully-qualified type name.
    var eventName: String {
        return String(reflecting: type(of: self))
    }

    /// Default: includes `feature` and `event_discriminator` (if any).
    var parameters: [String: String] {
        var result: [String: String] = [
            "feature": self.feature.rawValue
        ]

        if let discriminator = self.eventDiscriminator {
            result["event_discriminator"] = discriminator
        }

        return result
    }

}
