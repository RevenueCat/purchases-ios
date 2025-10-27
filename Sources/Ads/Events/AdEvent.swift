//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEvent.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

// MARK: - Internal Protocol

/// Internal protocol to ensure all ad event types have consistent ad event fields.
internal protocol AdEventData {
    var networkName: String { get }
    var mediatorName: MediatorName { get }
    var placement: String? { get }
    var adUnitId: String { get }
    var adInstanceId: String { get }
}

// MARK: - Public Types

/// Type representing an ad mediation network name.
///
/// Use the predefined static properties for common mediators, or create custom values
/// for other mediation networks.
@_spi(Experimental) public struct MediatorName: RawRepresentable, Equatable, Hashable, Codable, Sendable {

    /// The raw string value of the mediator name
    public let rawValue: String

    /// Creates a mediator name with the specified raw value
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Google AdMob mediation network
    public static let adMob = MediatorName(rawValue: "AdMob")

    /// AppLovin MAX mediation network
    public static let appLovin = MediatorName(rawValue: "AppLovin")

}

/// Data for ad displayed events.
@_spi(Experimental) public struct AdDisplayed: AdEventData {

    /// The name of the ad network that served the ad.
    public var networkName: String

    /// The mediation network used to serve the ad.
    public var mediatorName: MediatorName

    /// Optional placement identifier for the ad.
    public var placement: String?

    /// The ad unit identifier.
    public var adUnitId: String

    /// The ad instance identifier.
    public var adInstanceId: String

    /// Creates ad displayed event data.
    /// - Parameters:
    ///   - networkName: The name of the ad network that served the ad.
    ///   - mediatorName: The mediation network used to serve the ad.
    ///   - placement: Optional placement identifier for the ad.
    ///   - adUnitId: The ad unit identifier.
    ///   - adInstanceId: The ad instance identifier.
    public init(
        networkName: String,
        mediatorName: MediatorName,
        placement: String? = nil,
        adUnitId: String,
        adInstanceId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.placement = placement
        self.adUnitId = adUnitId
        self.adInstanceId = adInstanceId
    }

}

/// Data for ad opened/clicked events.
@_spi(Experimental) public struct AdOpened: AdEventData {

    /// The name of the ad network that served the ad.
    public var networkName: String

    /// The mediation network used to serve the ad.
    public var mediatorName: MediatorName

    /// Optional placement identifier for the ad.
    public var placement: String?

    /// The ad unit identifier.
    public var adUnitId: String

    /// The ad instance identifier.
    public var adInstanceId: String

    /// Creates ad opened/clicked event data.
    /// - Parameters:
    ///   - networkName: The name of the ad network that served the ad.
    ///   - mediatorName: The mediation network used to serve the ad.
    ///   - placement: Optional placement identifier for the ad.
    ///   - adUnitId: The ad unit identifier.
    ///   - adInstanceId: The ad instance identifier.
    public init(
        networkName: String,
        mediatorName: MediatorName,
        placement: String? = nil,
        adUnitId: String,
        adInstanceId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.placement = placement
        self.adUnitId = adUnitId
        self.adInstanceId = adInstanceId
    }

}

/// Data for ad revenue events.
@_spi(Experimental) public struct AdRevenue: AdEventData {

    /// The name of the ad network that served the ad.
    public var networkName: String

    /// The mediation network used to serve the ad.
    public var mediatorName: MediatorName

    /// Optional placement identifier for the ad.
    public var placement: String?

    /// The ad unit identifier.
    public var adUnitId: String

    /// The ad instance identifier.
    public var adInstanceId: String

    /// The revenue amount in micros (1/1,000,000 of the currency unit).
    public var revenueMicros: Int

    /// The ISO 4217 currency code (e.g., "USD", "EUR").
    public var currency: String

    /// The precision level of the revenue value.
    public var precision: Precision

    /// Creates ad revenue event data.
    /// - Parameters:
    ///   - networkName: The name of the ad network that served the ad.
    ///   - mediatorName: The mediation network used to serve the ad.
    ///   - placement: Optional placement identifier for the ad.
    ///   - adUnitId: The ad unit identifier.
    ///   - adInstanceId: The ad instance identifier.
    ///   - revenueMicros: The revenue amount in micros.
    ///   - currency: The ISO 4217 currency code.
    ///   - precision: The precision level of the revenue value.
    public init(
        networkName: String,
        mediatorName: MediatorName,
        placement: String? = nil,
        adUnitId: String,
        adInstanceId: String,
        revenueMicros: Int,
        currency: String,
        precision: Precision
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.placement = placement
        self.adUnitId = adUnitId
        self.adInstanceId = adInstanceId
        self.revenueMicros = revenueMicros
        self.currency = currency
        self.precision = precision
    }

}

extension AdRevenue {

    /// Type representing the level of accuracy for reported revenue values.
    @_spi(Experimental) public struct Precision: Equatable, Hashable, Codable, Sendable {

        /// The raw string value of the precision type
        internal let rawValue: String

        internal init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Revenue value is exact and confirmed
        public static let exact = Precision(rawValue: "exact")

        /// Revenue value is defined by the publisher
        public static let publisherDefined = Precision(rawValue: "publisher_defined")

        /// Revenue value is an estimate
        public static let estimated = Precision(rawValue: "estimated")

        /// Revenue value accuracy cannot be determined
        public static let unknown = Precision(rawValue: "unknown")

    }

}

// MARK: - Internal Event Enum

/// Internal event enum for type-safe routing through the events system.
internal enum AdEvent: FeatureEvent {

    // swiftlint:disable type_name

    /// An identifier that represents an ad event.
    internal typealias ID = UUID

    // swiftlint:enable type_name

    var feature: Feature {
        return .ads
    }

    var eventDiscriminator: String? {
        return nil
    }

    /// An ad impression was displayed.
    case displayed(CreationData, AdDisplayed)

    /// An ad was opened/clicked.
    case opened(CreationData, AdOpened)

    /// An ad impression generated revenue.
    case revenue(CreationData, AdRevenue)

}

extension AdEvent {

    /// Internal creation metadata that is automatically generated by the SDK.
    internal struct CreationData {

        internal var id: ID
        internal var date: Date

        internal init(
            id: ID = .init(),
            date: Date = .init()
        ) {
            self.id = id
            self.date = date
        }

    }

}

extension AdEvent {

    /// - Returns: the underlying ``AdEvent/CreationData-swift.struct`` for this event.
    internal var creationData: CreationData {
        switch self {
        case let .displayed(creationData, _): return creationData
        case let .opened(creationData, _): return creationData
        case let .revenue(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ad event data for this event.
    internal var eventData: AdEventData {
        switch self {
        case let .displayed(_, displayed):
            return displayed
        case let .opened(_, opened):
            return opened
        case let .revenue(_, revenue):
            return revenue
        }
    }

    /// - Returns: the underlying ``AdRevenue`` for revenue events.
    internal var revenueData: AdRevenue? {
        switch self {
        case .displayed, .opened:
            return nil
        case let .revenue(_, revenueData):
            return revenueData
        }
    }

}

// MARK: - Protocol Conformances

extension AdDisplayed: Equatable, Codable, Sendable {}
extension AdOpened: Equatable, Codable, Sendable {}
extension AdRevenue: Equatable, Codable, Sendable {}
extension AdEvent.CreationData: Equatable, Codable, Sendable {}
extension AdEvent: Equatable, Codable, Sendable {}

#endif
