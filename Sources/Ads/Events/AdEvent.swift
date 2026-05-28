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

/// Type representing an ad mediation network name.
///
/// Use the predefined static properties for common mediators, or create custom values
/// for other mediation networks.
@_spi(Experimental) @objc(RCMediatorName) public final class MediatorName: NSObject, Codable, @unchecked Sendable {

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
@_spi(Experimental) @objc(RCAdFormat) public final class AdFormat: NSObject, Codable, @unchecked Sendable {

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

/// Type representing the reason a rewarded-ad verification failed.
@_spi(Internal) public enum AdRewardFailureReason: String, Codable, Sendable {

    /// Verification did not complete within the allowed polling window.
    case timeout

    /// Verification failed due to a network-level error.
    case networkError = "network_error"

    /// The backend explicitly declined to verify the reward.
    case backendError = "backend_error"

    /// Verification failed for an unspecified reason.
    case unknown

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
    @objc public private(set) var networkName: String?
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String

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
@_spi(Experimental) @objc(RCAdDisplayed) public final class AdDisplayed: NSObject,
                                                                          AdImpressionEventData,
                                                                          Codable,
                                                                          @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String?
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String

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
@_spi(Experimental) @objc(RCAdOpened) public final class AdOpened: NSObject,
                                                                    AdImpressionEventData,
                                                                    Codable,
                                                                    @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String?
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String

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
@_spi(Experimental) @objc(RCAdRevenue) public final class AdRevenue: NSObject,
                                                                      AdImpressionEventData,
                                                                      Codable,
                                                                      @unchecked Sendable {

    // swiftlint:disable missing_docs
    @objc public private(set) var networkName: String?
    @objc public private(set) var mediatorName: MediatorName
    @objc public private(set) var adFormat: AdFormat
    @objc public private(set) var placement: String?
    @objc public private(set) var adUnitId: String
    @objc public private(set) var impressionId: String
    @objc public private(set) var revenueMicros: Int
    @objc public private(set) var currency: String
    @objc public private(set) var precision: Precision

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

/// Data for the moment the ad SDK reports a user-earned reward, prior to backend verification.
@_spi(Internal) public struct AdRewardEarnedUnverified: AdImpressionEventData, Codable, Equatable, Sendable {

    // swiftlint:disable missing_docs
    public let networkName: String?
    public let mediatorName: MediatorName
    public let adFormat: AdFormat
    public let placement: String?
    public let adUnitId: String
    public let impressionId: String
    public let rewardVerificationEnabled: Bool
    public let rewardItem: String?
    public let rewardAmount: Int?

    public init(
        networkName: String?,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String,
        rewardVerificationEnabled: Bool,
        rewardItem: String?,
        rewardAmount: Int?
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        self.rewardVerificationEnabled = rewardVerificationEnabled
        self.rewardItem = rewardItem
        self.rewardAmount = rewardAmount
    }
    // swiftlint:enable missing_docs

}

/// Data for the moment backend verification confirms the reward delivered by the ad SDK.
@_spi(Internal) public struct AdRewardVerified: AdImpressionEventData, Equatable, Sendable {

    // swiftlint:disable missing_docs
    public let networkName: String?
    public let mediatorName: MediatorName
    public let adFormat: AdFormat
    public let placement: String?
    public let adUnitId: String
    public let impressionId: String

    /// The verified reward payload.
    public let reward: AdReward

    public init(
        networkName: String?,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String,
        reward: AdReward
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        self.reward = reward
    }
    // swiftlint:enable missing_docs

    /// Decoder-input path: log + fallback to `.unsupportedReward`. Backend wire data that
    /// doesn't match the schema must not trigger `assertionFailure` — malformed data is not
    /// a programming bug — but a warning helps catch backend/SDK schema drift in production.
    private static func makeReward(
        kindRawValue: String,
        virtualCurrencyCode: String?,
        virtualCurrencyAmount: Int?
    ) -> AdReward {
        switch kindRawValue {
        case AdReward.Kind.virtualCurrency:
            if let code = virtualCurrencyCode, let amount = virtualCurrencyAmount, amount > 0 {
                return .virtualCurrency(VirtualCurrencyReward(code: code, amount: amount))
            }
            Logger.warn(AdsStrings.invalid_virtual_currency_payload(
                code: virtualCurrencyCode,
                amount: virtualCurrencyAmount
            ))
            return .unsupportedReward
        case AdReward.Kind.noReward:
            return .noReward
        case AdReward.Kind.unsupportedReward:
            return .unsupportedReward
        default:
            Logger.warn(AdsStrings.unknown_reward_kind(rawValue: kindRawValue))
            return .unsupportedReward
        }
    }

}

extension AdRewardVerified: Codable {

    /// Wire-format keys. ``reward`` is encoded as flat `rewardType` / `rewardCurrencyCode` /
    /// `rewardCurrencyAmount` fields so the backend schema remains unchanged.
    private enum CodingKeys: String, CodingKey {
        case networkName
        case mediatorName
        case adFormat
        case placement
        case adUnitId
        case impressionId
        case rewardType
        case rewardCurrencyCode
        case rewardCurrencyAmount
    }

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.networkName, forKey: .networkName)
        try container.encode(self.mediatorName, forKey: .mediatorName)
        try container.encode(self.adFormat, forKey: .adFormat)
        try container.encodeIfPresent(self.placement, forKey: .placement)
        try container.encode(self.adUnitId, forKey: .adUnitId)
        try container.encode(self.impressionId, forKey: .impressionId)
        try container.encode(self.reward.kindRawValue, forKey: .rewardType)
        try container.encodeIfPresent(self.reward.virtualCurrency?.code, forKey: .rewardCurrencyCode)
        try container.encodeIfPresent(self.reward.virtualCurrency?.amount, forKey: .rewardCurrencyAmount)
    }

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rewardKind = try container.decode(String.self, forKey: .rewardType)
        let code = try container.decodeIfPresent(String.self, forKey: .rewardCurrencyCode)
        let amount = try container.decodeIfPresent(Int.self, forKey: .rewardCurrencyAmount)
        self.init(
            networkName: try container.decodeIfPresent(String.self, forKey: .networkName),
            mediatorName: try container.decode(MediatorName.self, forKey: .mediatorName),
            adFormat: try container.decode(AdFormat.self, forKey: .adFormat),
            placement: try container.decodeIfPresent(String.self, forKey: .placement),
            adUnitId: try container.decode(String.self, forKey: .adUnitId),
            impressionId: try container.decode(String.self, forKey: .impressionId),
            reward: Self.makeReward(
                kindRawValue: rewardKind,
                virtualCurrencyCode: code,
                virtualCurrencyAmount: amount
            )
        )
    }

}

/// Data for the moment backend reward verification terminally fails.
@_spi(Internal) public struct AdRewardFailedToVerify: AdImpressionEventData, Codable, Equatable, Sendable {

    // swiftlint:disable missing_docs
    public let networkName: String?
    public let mediatorName: MediatorName
    public let adFormat: AdFormat
    public let placement: String?
    public let adUnitId: String
    public let impressionId: String
    public let failureReason: AdRewardFailureReason

    public init(
        networkName: String?,
        mediatorName: MediatorName,
        adFormat: AdFormat,
        placement: String?,
        adUnitId: String,
        impressionId: String,
        failureReason: AdRewardFailureReason
    ) {
        self.networkName = networkName
        self.mediatorName = mediatorName
        self.adFormat = adFormat
        self.placement = placement
        self.adUnitId = adUnitId
        self.impressionId = impressionId
        self.failureReason = failureReason
    }
    // swiftlint:enable missing_docs

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
        case let .rewardEarnedUnverified(creationData, _): return creationData
        case let .rewardVerified(creationData, _): return creationData
        case let .rewardFailedToVerify(creationData, _): return creationData
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
        }
    }

    /// - Returns: the underlying ``AdRevenue`` for revenue events.
    internal var revenueData: AdRevenue? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened,
             .rewardEarnedUnverified, .rewardVerified, .rewardFailedToVerify:
            return nil
        case let .revenue(_, revenueData):
            return revenueData
        }
    }

    /// - Returns: the underlying ``AdRewardEarnedUnverified`` for unverified reward events.
    internal var rewardEarnedUnverifiedData: AdRewardEarnedUnverified? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardVerified, .rewardFailedToVerify:
            return nil
        case let .rewardEarnedUnverified(_, data):
            return data
        }
    }

    /// - Returns: the underlying ``AdRewardVerified`` for verified reward events.
    internal var rewardVerifiedData: AdRewardVerified? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardEarnedUnverified, .rewardFailedToVerify:
            return nil
        case let .rewardVerified(_, data):
            return data
        }
    }

    /// - Returns: the underlying ``AdRewardFailedToVerify`` for failed-to-verify reward events.
    internal var rewardFailedToVerifyData: AdRewardFailedToVerify? {
        switch self {
        case .failedToLoad, .loaded, .displayed, .opened, .revenue,
             .rewardEarnedUnverified, .rewardVerified:
            return nil
        case let .rewardFailedToVerify(_, data):
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
             .rewardEarnedUnverified, .rewardVerified, .rewardFailedToVerify:
            return nil
        }
    }

}
