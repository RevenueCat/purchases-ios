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

// MARK: - Public Types

// MARK: - Internal Protocol

/// Internal protocol for base ad event fields shared by all ad event types.
internal protocol AdEventData {
    var mediatorName: MediatorName { get }
    var adFormat: AdFormat { get }
    var placement: String? { get }
    var adUnitId: String { get }
}

/// Internal protocol for ad impression events that have a network name and impression ID.
internal protocol AdImpressionEventData: AdEventData {
    var networkName: String { get }
    var impressionId: String { get }
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

/// Type representing an ad format type.
///
/// Use the predefined static properties for common ad formats, or create custom values
/// for other ad format types.
@_spi(Experimental) @objc(RCAdFormat) public final class AdFormat: NSObject, Codable {

    /// The raw string value of the ad format
    @objc public let rawValue: String

    /// Creates an ad format with the specified raw value
    @objc public init(rawValue: String) {
        self.rawValue = rawValue
        super.init()
    }

    /// Ad format type not in our predefined list
    @objc public static let other = AdFormat(rawValue: "other")

    /// Standard banner ad format
    @objc public static let banner = AdFormat(rawValue: "banner")

    /// Full-screen interstitial ad format
    @objc public static let interstitial = AdFormat(rawValue: "interstitial")

    /// Rewarded video ad format
    @objc public static let rewarded = AdFormat(rawValue: "rewarded")

    /// Rewarded interstitial ad format
    @objc public static let rewardedInterstitial = AdFormat(rawValue: "rewarded_interstitial")

    /// Native ad format that matches app design
    @objc public static let native = AdFormat(rawValue: "native")

    /// App open ad format displayed at app launch
    @objc public static let appOpen = AdFormat(rawValue: "app_open")

    /// Medium rectangle ad format
    @objc public static let mrec = AdFormat(rawValue: "mrec")

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdFormat else { return false }
        return self.rawValue == other.rawValue
    }

    public override var hash: Int {
        return self.rawValue.hash
    }

}

/// Data for ad failed to load events.
@_spi(Experimental) @objc(RCAdFailedToLoad) public final class AdFailedToLoad: NSObject,
                                                                                AdEventData,
                                                                                Codable,
                                                                                @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    private let mediatorErrorCodeRawValue: Int?
    @objc public var mediatorErrorCode: NSNumber? {
        return self.mediatorErrorCodeRawValue.map(NSNumber.init(value:))
    }
    public var mediatorErrorCodeValue: Int? {
        return self.mediatorErrorCodeRawValue
    }

    @objc public init(
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        mediatorErrorCode: NSNumber?
    ) {
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.mediatorErrorCodeRawValue = mediatorErrorCode?.intValue
        super.init()
    }

    public convenience init(
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        mediatorErrorCode: Int?
    ) {
        self.init(
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: placement,
            adUnitId: adUnitId,
            mediatorErrorCode: mediatorErrorCode.map(NSNumber.init(value:))
        )
    }

    @objc public convenience init(
        mediatorName: MediatorName,
        adFormat: AdFormat,
        adUnitId: String,
        mediatorErrorCode: NSNumber? = nil
    ) {
        self.init(
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: adUnitId,
            mediatorErrorCode: mediatorErrorCode
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdFailedToLoad else { return false }
        return self.mediatorName == other.mediatorName &&
               self.adFormat == other.adFormat &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.mediatorErrorCode == other.mediatorErrorCode
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(mediatorName)
        hasher.combine(adFormat)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(mediatorErrorCode)
        return hasher.finalize()
    }

    private enum CodingKeys: String, CodingKey {
        case mediatorName
        case adFormat
        case placement
        case adUnitId
        case mediatorErrorCodeRawValue = "mediatorErrorCode"
    }

}

/// Data for ad loaded events.
@_spi(Experimental) @objc(RCAdLoaded) public final class AdLoaded: NSObject,
                                                                    AdImpressionEventData,
                                                                    Codable,
                                                                    @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        adUnitId: String,
        impressionId: String
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: adUnitId,
            impressionId: impressionId
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdLoaded else { return false }
        return self.networkName == other.networkName &&
               self.mediatorName == other.mediatorName &&
               self.adFormat == other.adFormat &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.impressionId == other.impressionId
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(adFormat)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(impressionId)
        return hasher.finalize()
    }

}

/// Data for ad displayed events.
@_spi(Experimental) @objc(RCAdDisplayed) public final class AdDisplayed: NSObject,
                                                                          AdImpressionEventData,
                                                                          Codable,
                                                                          @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        adUnitId: String,
        impressionId: String
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: adUnitId,
            impressionId: impressionId
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdDisplayed else { return false }
        return self.networkName == other.networkName &&
               self.mediatorName == other.mediatorName &&
               self.adFormat == other.adFormat &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.impressionId == other.impressionId
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(adFormat)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(impressionId)
        return hasher.finalize()
    }

}

/// Data for ad opened/clicked events.
@_spi(Experimental) @objc(RCAdOpened) public final class AdOpened: NSObject,
                                                                    AdImpressionEventData,
                                                                    Codable,
                                                                    @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        adUnitId: String,
        impressionId: String
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: adUnitId,
            impressionId: impressionId
        )
    }
    // swiftlint:enable missing_docs

    // MARK: - NSObject overrides for equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AdOpened else { return false }
        return self.networkName == other.networkName &&
               self.mediatorName == other.mediatorName &&
               self.adFormat == other.adFormat &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.impressionId == other.impressionId
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(adFormat)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(impressionId)
        return hasher.finalize()
    }

}

/// Data for ad revenue events.
@_spi(Experimental) @objc(RCAdRevenue) public final class AdRevenue: NSObject,
                                                                      AdImpressionEventData,
                                                                      Codable,
                                                                      @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String
    @objc public private(set) var revenueMicros: Int
    @objc public private(set) var currency: String
    @objc public private(set) var precision: Precision

    @objc public init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String,
        revenueMicros: Int,
        currency: String,
        precision: Precision
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        self.revenueMicros = revenueMicros
        self.currency = currency
        self.precision = precision
        super.init()
    }

    @objc public convenience init(
        networkName: String,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        adUnitId: String,
        impressionId: String,
        revenueMicros: Int,
        currency: String,
        precision: Precision
    ) {
        self.init(
            networkName: networkName,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: adUnitId,
            impressionId: impressionId,
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
               self.adFormat == other.adFormat &&
               self.placement == other.placement &&
               self.adUnitId == other.adUnitId &&
               self.impressionId == other.impressionId &&
               self.revenueMicros == other.revenueMicros &&
               self.currency == other.currency &&
               self.precision == other.precision
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(networkName)
        hasher.combine(mediatorName)
        hasher.combine(adFormat)
        hasher.combine(placement)
        hasher.combine(adUnitId)
        hasher.combine(impressionId)
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
internal enum AdEvent: Equatable, Codable, Sendable {

    // swiftlint:disable type_name

    /// An identifier that represents an ad event.
    internal typealias ID = UUID

    // swiftlint:enable type_name

    /// An ad failed to load.
    case failedToLoad(CreationData, AdFailedToLoad)

    /// An ad successfully loaded.
    case loaded(CreationData, AdLoaded)

    /// An ad impression was displayed.
    case displayed(CreationData, AdDisplayed)

    /// An ad was opened/clicked.
    case opened(CreationData, AdOpened)

    /// An ad impression generated revenue.
    case revenue(CreationData, AdRevenue)

}

extension AdEvent {

    /// Internal creation metadata that is automatically generated by the SDK.
    internal struct CreationData: Equatable, Codable, Sendable {

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
        case let .failedToLoad(creationData, _): return creationData
        case let .loaded(creationData, _): return creationData
        case let .displayed(creationData, _): return creationData
        case let .opened(creationData, _): return creationData
        case let .revenue(creationData, _): return creationData
        }
    }

    /// - Returns: the underlying ad event data for this event.
    internal var eventData: AdEventData {
        switch self {
        case let .failedToLoad(_, failed):
            return failed
        case let .loaded(_, loaded):
            return loaded
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
        case .failedToLoad, .loaded, .displayed, .opened:
            return nil
        case let .revenue(_, revenueData):
            return revenueData
        }
    }

    /// - Returns: the network name for impression events, nil for failed to load events.
    internal var networkName: String? {
        switch self {
        case .failedToLoad:
            return nil
        case let .loaded(_, data):
            return data.networkName
        case let .displayed(_, data):
            return data.networkName
        case let .opened(_, data):
            return data.networkName
        case let .revenue(_, data):
            return data.networkName
        }
    }

    /// - Returns: the impression identifier for events that include it.
    internal var impressionIdentifier: String? {
        switch self {
        case .failedToLoad:
            return nil
        case let .loaded(_, data):
            return data.impressionId
        case let .displayed(_, data):
            return data.impressionId
        case let .opened(_, data):
            return data.impressionId
        case let .revenue(_, data):
            return data.impressionId
        }
    }

    /// - Returns: the mediator error code for failed to load events.
    internal var mediatorErrorCode: Int? {
        switch self {
        case let .failedToLoad(_, data):
            return data.mediatorErrorCode?.intValue
        case .loaded, .displayed, .opened, .revenue:
            return nil
        }
    }

}
