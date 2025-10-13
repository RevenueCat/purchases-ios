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

#if ENABLE_AD_EVENTS_TRACKING

/// Type representing an ad mediation network name.
///
/// Use the predefined static properties for common mediators, or create custom values
/// for other mediation networks.
public struct MediatorName: RawRepresentable, Equatable, Hashable, Codable, Sendable {

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

#endif

#if ENABLE_AD_EVENTS_TRACKING

/// Data for ad displayed events.
public struct AdDisplayed: AdEventData {

    // swiftlint:disable missing_docs
    public var networkName: String
    public var mediatorName: MediatorName
    public var placement: String?
    public var adUnitId: String
    public var adInstanceId: String

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
    // swiftlint:enable missing_docs

}

/// Data for ad opened/clicked events.
public struct AdOpened: AdEventData {

    // swiftlint:disable missing_docs
    public var networkName: String
    public var mediatorName: MediatorName
    public var placement: String?
    public var adUnitId: String
    public var adInstanceId: String

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
    // swiftlint:enable missing_docs

}

/// Data for ad revenue events.
public struct AdRevenue: AdEventData {

    // swiftlint:disable missing_docs
    public var networkName: String
    public var mediatorName: MediatorName
    public var placement: String?
    public var adUnitId: String
    public var adInstanceId: String
    public var revenueMicros: Int
    public var currency: String
    public var precision: Precision

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
    // swiftlint:enable missing_docs

}

extension AdRevenue {

    /// Type representing the level of accuracy for reported revenue values.
    public struct Precision: RawRepresentable, Equatable, Hashable, Codable, Sendable {

        /// The raw string value of the precision type
        public let rawValue: String

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
