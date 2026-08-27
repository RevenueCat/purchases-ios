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
    var networkName: String? { get }
    var impressionId: String { get }
}

/// Identifies the mechanism that emitted an ad event. The SDK only ever emits these two values;
/// pre-feature versions send nothing, which the backend treats as `unknown`.
@_spi(Internal) public enum AdEventCaptureMethod: String, Codable, Sendable {

    /// Auto-captured by an official RevenueCat ad-network adapter.
    case adapter

    /// Reported via the public `trackAd*` tracking API.
    case manual

}

/// Type representing an ad mediation network name.
///
/// Use the predefined static properties for common mediators, or create custom values
/// for other mediation networks.
@objc(RCMediatorName) public final class MediatorName: NSObject, Codable, @unchecked Sendable {

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
@objc(RCAdFormat) public final class AdFormat: NSObject, Codable, @unchecked Sendable {

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
@objc(RCAdFailedToLoad) public final class AdFailedToLoad: NSObject,
                                                           AdEventData,
                                                           Codable,
                                                           @unchecked Sendable {

    /// The mediation network that reported the load failure.
    @objc public let mediatorName: MediatorName

    /// The format of the ad that failed to load.
    @objc public let adFormat: AdFormat

    /// The developer-defined placement where the ad was requested, if provided.
    @objc public let placement: String?

    /// The ad unit identifier of the ad that failed to load.
    @objc public let adUnitId: String

    private let mediatorErrorCodeRawValue: Int?

    /// The error code reported by the mediation SDK for the failure, if it provided one.
    @objc public var mediatorErrorCode: NSNumber? {
        return self.mediatorErrorCodeRawValue.map(NSNumber.init(value:))
    }

    /// The error code reported by the mediation SDK for the failure, as an `Int?`, if it provided one.
    public var mediatorErrorCodeValue: Int? {
        return self.mediatorErrorCodeRawValue
    }

    // swiftlint:disable missing_docs
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
@objc(RCAdLoaded) public final class AdLoaded: NSObject,
                                               AdImpressionEventData,
                                               Codable,
                                               @unchecked Sendable {

    /// The ad network that served the ad, as reported by the mediator, if available.
    @objc public let networkName: String?

    /// The mediation network that brokered the ad.
    @objc public let mediatorName: MediatorName

    /// The format of the ad (for example, banner, interstitial, or rewarded).
    @objc public let adFormat: AdFormat

    /// The developer-defined placement where the ad was shown, if provided.
    @objc public let placement: String?

    /// The ad unit identifier for the ad.
    @objc public let adUnitId: String

    /// Identifier that correlates this event with other events for the same ad impression.
    @objc public let impressionId: String

    // swiftlint:disable missing_docs
    @objc public init(
        networkName: String?,
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
        networkName: String?,
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
@objc(RCAdDisplayed) public final class AdDisplayed: NSObject,
                                                     AdImpressionEventData,
                                                     Codable,
                                                     @unchecked Sendable {

    /// The ad network that served the ad, as reported by the mediator, if available.
    @objc public let networkName: String?

    /// The mediation network that brokered the ad.
    @objc public let mediatorName: MediatorName

    /// The format of the ad (for example, banner, interstitial, or rewarded).
    @objc public let adFormat: AdFormat

    /// The developer-defined placement where the ad was shown, if provided.
    @objc public let placement: String?

    /// The ad unit identifier for the ad.
    @objc public let adUnitId: String

    /// Identifier that correlates this event with other events for the same ad impression.
    @objc public let impressionId: String

    // swiftlint:disable missing_docs
    @objc public init(
        networkName: String?,
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
        networkName: String?,
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
@objc(RCAdOpened) public final class AdOpened: NSObject,
                                               AdImpressionEventData,
                                               Codable,
                                               @unchecked Sendable {

    /// The ad network that served the ad, as reported by the mediator, if available.
    @objc public let networkName: String?

    /// The mediation network that brokered the ad.
    @objc public let mediatorName: MediatorName

    /// The format of the ad (for example, banner, interstitial, or rewarded).
    @objc public let adFormat: AdFormat

    /// The developer-defined placement where the ad was shown, if provided.
    @objc public let placement: String?

    /// The ad unit identifier for the ad.
    @objc public let adUnitId: String

    /// Identifier that correlates this event with other events for the same ad impression.
    @objc public let impressionId: String

    // swiftlint:disable missing_docs
    @objc public init(
        networkName: String?,
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
        networkName: String?,
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
@objc(RCAdRevenue) public final class AdRevenue: NSObject,
                                                 AdImpressionEventData,
                                                 Codable,
                                                 @unchecked Sendable {

    /// The ad network that served the ad, as reported by the mediator, if available.
    @objc public let networkName: String?

    /// The mediation network that brokered the ad.
    @objc public let mediatorName: MediatorName

    /// The format of the ad (for example, banner, interstitial, or rewarded).
    @objc public let adFormat: AdFormat

    /// The developer-defined placement where the ad was shown, if provided.
    @objc public let placement: String?

    /// The ad unit identifier for the ad.
    @objc public let adUnitId: String

    /// Identifier that correlates this event with other events for the same ad impression.
    @objc public let impressionId: String

    /// The estimated ad revenue, expressed in micros (millionths) of ``currency``.
    @objc public let revenueMicros: Int

    /// The ISO 4217 currency code for ``revenueMicros``.
    @objc public let currency: String

    /// The accuracy level of the reported ``revenueMicros``.
    @objc public let precision: Precision

    // swiftlint:disable missing_docs
    @objc public init(
        networkName: String?,
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
        networkName: String?,
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
    @objc(RCAdRevenuePrecision) public final class Precision: NSObject, Codable {

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

    /// An ad SDK reported a user-earned reward, prior to server-side verification.
    case rewardEarnedUnverified(CreationData, AdRewardEarnedUnverified)

    /// Server-side verification confirmed the reward delivered by the ad SDK.
    case rewardVerified(CreationData, AdRewardVerified)

    /// Server-side verification terminally failed.
    case rewardFailedToVerify(CreationData, AdRewardFailedToVerify)

    /// A single reward was granted following successful verification.
    case rewardGranted(CreationData, AdRewardGranted)

}

extension AdEvent {

    /// Internal creation metadata that is automatically generated by the SDK.
    internal struct CreationData: Equatable, Codable, Sendable {

        internal var id: ID
        internal var date: Date
        internal var captureMethod: AdEventCaptureMethod?

        internal init(
            id: ID = .init(),
            date: Date = .init(),
            captureMethod: AdEventCaptureMethod
        ) {
            self.id = id
            self.date = date
            self.captureMethod = captureMethod
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
        case let .rewardEarnedUnverified(creationData, _): return creationData
        case let .rewardVerified(creationData, _): return creationData
        case let .rewardFailedToVerify(creationData, _): return creationData
        case let .rewardGranted(creationData, _): return creationData
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
        case let .rewardEarnedUnverified(_, unverified):
            return unverified
        case let .rewardVerified(_, verified):
            return verified
        case let .rewardFailedToVerify(_, failedToVerify):
            return failedToVerify
        case let .rewardGranted(_, granted):
            return granted
        }
    }

    /// - Returns: the underlying ``AdRevenue`` for revenue events.
    internal var revenueData: AdRevenue? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened,
             .rewardEarnedUnverified, .rewardVerified, .rewardFailedToVerify, .rewardGranted:
            return nil
        case let .revenue(_, revenueData):
            return revenueData
        }
    }

    /// - Returns: the underlying ``AdRewardEarnedUnverified`` for unverified reward events.
    internal var rewardEarnedUnverifiedData: AdRewardEarnedUnverified? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardVerified, .rewardFailedToVerify, .rewardGranted:
            return nil
        case let .rewardEarnedUnverified(_, data):
            return data
        }
    }

    /// - Returns: the underlying ``AdRewardVerified`` for verified reward events.
    internal var rewardVerifiedData: AdRewardVerified? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardEarnedUnverified, .rewardFailedToVerify, .rewardGranted:
            return nil
        case let .rewardVerified(_, data):
            return data
        }
    }

    /// - Returns: the underlying ``AdRewardFailedToVerify`` for failed-to-verify reward events.
    internal var rewardFailedToVerifyData: AdRewardFailedToVerify? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardEarnedUnverified, .rewardVerified, .rewardGranted:
            return nil
        case let .rewardFailedToVerify(_, data):
            return data
        }
    }

    internal var rewardGrantedData: AdRewardGranted? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardEarnedUnverified, .rewardVerified, .rewardFailedToVerify:
            return nil
        case let .rewardGranted(_, data):
            return data
        }
    }

    /// - Returns: the network name for impression and reward events, nil for failed to load events.
    internal var networkName: String? {
        (self.eventData as? AdImpressionEventData)?.networkName
    }

    /// - Returns: the impression identifier for events that include it.
    internal var impressionIdentifier: String? {
        (self.eventData as? AdImpressionEventData)?.impressionId
    }

    /// - Returns: the mediator error code for failed to load events.
    internal var mediatorErrorCode: Int? {
        switch self {
        case let .failedToLoad(_, data):
            return data.mediatorErrorCode?.intValue
        case .loaded, .displayed, .opened, .revenue,
             .rewardEarnedUnverified, .rewardVerified, .rewardFailedToVerify, .rewardGranted:
            return nil
        }
    }

}
