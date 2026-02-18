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

    /// Whether this event should be stored and sent to the backend.
    /// WIP: Some PaywallEvents are not yet supported by the backend.
    /// We should implement support for these events in the backend first
    /// and then we can remove this `shouldStoreEvent` (as it will be always `true`)
    var shouldStoreEvent: Bool { get }

}

@_spi(Internal) public extension FeatureEvent {

    /// By default, all events should be stored.
    var shouldStoreEvent: Bool { true }

}
