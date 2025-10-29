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

// swiftlint:disable file_length

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

// MARK: - Public Types

// MARK: - Internal Protocol

/// Internal protocol to ensure all ad event types have consistent ad event fields.
internal protocol AdEventData {
    var networkName: String { get }
    var mediatorName: MediatorName { get }
    var placement: String? { get }
    var adUnitId: String { get }
    var adInstanceId: String { get }
}

/// Type representing an ad mediation network name.
///
/// Use the predefined static properties for common mediators, or create custom values
/// for other mediation networks.
@_spi(Experimental) @objc(RCMediatorName) public final class MediatorName: NSObject, Codable {

    /// The raw string value of the mediator name
    @objc public let rawValue: String

    /// Creates a mediator name with the specified raw value
    @objc public init(rawValue: String) {
        self.rawValue = rawValue
        super.init()
    }

    /// Google AdMob mediation network
    @objc public static let adMob = MediatorName(rawValue: "AdMob")

    /// AppLovin MAX mediation network
    @objc public static let appLovin = MediatorName(rawValue: "AppLovin")

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MediatorName else { return false }
        return self.rawValue == other.rawValue
    }

    public override var hash: Int {
        return self.rawValue.hash
    }

}

/// Data for ad displayed events.
@_spi(Experimental) @objc(RCAdDisplayed) public final class AdDisplayed: NSObject, AdEventData {

    // swiftlint:disable missing_docs
    @objc public var networkName: String
    @objc public var mediatorName: MediatorName
    @objc public var placement: String?
    @objc public var adUnitId: String
    @objc public var adInstanceId: String

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        placement: String?,
        adUnitId: String,
        adInstanceId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.placement = placement
        self.adUnitId = adUnitId
        self.adInstanceId = adInstanceId
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adUnitId: String,
        adInstanceId: String
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            placement: nil,
            adUnitId: adUnitId,
            adInstanceId: adInstanceId
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdDisplayed else { return false }
        return self.networkName == other.networkName &&
               self.mediatorName == other.mediatorName &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.adInstanceId == other.adInstanceId
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(adInstanceId)
        return hasher.finalize()
    }

}

/// Data for ad opened/clicked events.
@_spi(Experimental) @objc(RCAdOpened) public final class AdOpened: NSObject, AdEventData {

    // swiftlint:disable missing_docs
    @objc public var networkName: String
    @objc public var mediatorName: MediatorName
    @objc public var placement: String?
    @objc public var adUnitId: String
    @objc public var adInstanceId: String

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        placement: String?,
        adUnitId: String,
        adInstanceId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.placement = placement
        self.adUnitId = adUnitId
        self.adInstanceId = adInstanceId
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adUnitId: String,
        adInstanceId: String
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            placement: nil,
            adUnitId: adUnitId,
            adInstanceId: adInstanceId
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdOpened else { return false }
        return self.networkName == other.networkName &&
               self.mediatorName == other.mediatorName &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.adInstanceId == other.adInstanceId
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(adInstanceId)
        return hasher.finalize()
    }

}

/// Data for ad revenue events.
@_spi(Experimental) @objc(RCAdRevenue) public final class AdRevenue: NSObject, AdEventData {

    // swiftlint:disable missing_docs
    @objc public var networkName: String
    @objc public var mediatorName: MediatorName
    @objc public var placement: String?
    @objc public var adUnitId: String
    @objc public var adInstanceId: String
    @objc public var revenueMicros: Int
    @objc public var currency: String
    @objc public var precision: Precision

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        placement: String?,
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
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adUnitId: String,
        adInstanceId: String,
        revenueMicros: Int,
        currency: String,
        precision: Precision
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            placement: nil,
            adUnitId: adUnitId,
            adInstanceId: adInstanceId,
            revenueMicros: revenueMicros,
            currency: currency,
            precision: precision
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdRevenue else { return false }
        return self.networkName == other.networkName &&
               self.mediatorName == other.mediatorName &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.adInstanceId == other.adInstanceId &&
               self.revenueMicros == other.revenueMicros &&
               self.currency == other.currency &&
               self.precision == other.precision
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(adInstanceId)
        hasher.combine(revenueMicros)
        hasher.combine(currency)
        hasher.combine(precision)
        return hasher.finalize()
    }

}

extension AdRevenue {

    /// Type representing the level of accuracy for reported revenue values.
    @_spi(Experimental) @objc(RCAdRevenuePrecision) public final class Precision: NSObject, Codable {

        /// The raw string value of the precision type
        @objc public let rawValue: String

        /// Creates a precision value with the specified raw value
        @objc public init(rawValue: String) {
            self.rawValue = rawValue
            super.init()
        }

        /// Revenue value is exact and confirmed
        @objc public static let exact = Precision(rawValue: "exact")

        /// Revenue value is defined by the publisher
        @objc public static let publisherDefined = Precision(rawValue: "publisher_defined")

        /// Revenue value is an estimate
        @objc public static let estimated = Precision(rawValue: "estimated")

        /// Revenue value accuracy cannot be determined
        @objc public static let unknown = Precision(rawValue: "unknown")

        // MARK: - NSObject overrides for equality

        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? Precision else { return false }
            return self.rawValue == other.rawValue
        }

        public override var hash: Int {
            return self.rawValue.hash
        }

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

extension AdDisplayed: Codable {}
extension AdOpened: Codable {}
extension AdRevenue: Codable {}
extension AdEvent.CreationData: Equatable, Codable, Sendable {}
extension AdEvent: Equatable, Codable, Sendable {}

#endif
