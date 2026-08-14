//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdRewardEvents.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

/// Type representing the reason a rewarded-ad verification failed.
@_spi(Internal) public enum AdRewardFailureReason: Codable, Hashable, Sendable {

    /// Verification did not complete within the allowed polling window.
    case timeout

    /// Verification failed due to a network-level error.
    case networkError

    /// The backend declined to verify the reward. `reason` is the backend's own decline code
    /// when it reported one, and is what gets sent for this case.
    case backendError(reason: String?)

    /// Polling was cancelled before the backend reached an outcome.
    case cancelled

    /// Verification failed for an unspecified reason.
    case unknown

    // swiftlint:disable missing_docs
    public var rawValue: String {
        switch self {
        case .timeout: return "timeout"
        case .networkError: return "network_error"
        case .backendError(let reason): return reason ?? "backend_error"
        case .cancelled: return "cancelled"
        case .unknown: return "unknown"
        }
    }

    public init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "timeout": self = .timeout
        case "network_error": self = .networkError
        case "cancelled": self = .cancelled
        case "unknown": self = .unknown
        case "backend_error": self = .backendError(reason: nil)
        case let reason: self = .backendError(reason: reason)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    // swiftlint:enable missing_docs

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

/// Data for the moment backend verification confirms the reward earned from an ad.
@_spi(Internal) public struct AdRewardVerified: AdImpressionEventData, Codable, Equatable, Sendable {

    // swiftlint:disable missing_docs
    public let networkName: String?
    public let mediatorName: MediatorName
    public let adFormat: AdFormat
    public let placement: String?
    public let adUnitId: String
    public let impressionId: String

    public init(
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
    }
    // swiftlint:enable missing_docs

}

/// Data for a single reward grant resulting from a verified rewarded ad.
@_spi(Internal) public struct AdRewardGranted: AdImpressionEventData, Equatable, Sendable {

    // swiftlint:disable missing_docs
    public let networkName: String?
    public let mediatorName: MediatorName
    public let adFormat: AdFormat
    public let placement: String?
    public let adUnitId: String
    public let impressionId: String

    /// The granted reward payload. Never ``AdReward/noReward``.
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

}

extension AdRewardGranted: Codable {

    /// ``reward`` is encoded as flat `rewardType` / `rewardVirtualCurrencyCode` / `rewardVirtualCurrencyAmount` /
    /// `rewardEntitlementId` fields, matching ``AdRewardVerified``'s wire shape.
    ///
    /// `rewardEntitlementExpiresAt` is local round-trip only — never forward it to the backend request.
    private enum CodingKeys: String, CodingKey {
        case networkName
        case mediatorName
        case adFormat
        case placement
        case adUnitId
        case impressionId
        case rewardType
        case rewardVirtualCurrencyCode
        case rewardVirtualCurrencyAmount
        case rewardEntitlementId
        case rewardEntitlementExpiresAt
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
        try self.reward.encode(
            into: &container,
            typeKey: .rewardType,
            codeKey: .rewardVirtualCurrencyCode,
            amountKey: .rewardVirtualCurrencyAmount,
            entitlementIdKey: .rewardEntitlementId,
            entitlementExpiresAtKey: .rewardEntitlementExpiresAt
        )
    }

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            networkName: try container.decodeIfPresent(String.self, forKey: .networkName),
            mediatorName: try container.decode(MediatorName.self, forKey: .mediatorName),
            adFormat: try container.decode(AdFormat.self, forKey: .adFormat),
            placement: try container.decodeIfPresent(String.self, forKey: .placement),
            adUnitId: try container.decode(String.self, forKey: .adUnitId),
            impressionId: try container.decode(String.self, forKey: .impressionId),
            reward: try AdReward.decode(
                from: container,
                typeKey: .rewardType,
                codeKey: .rewardVirtualCurrencyCode,
                amountKey: .rewardVirtualCurrencyAmount,
                entitlementIdKey: .rewardEntitlementId,
                entitlementExpiresAtKey: .rewardEntitlementExpiresAt
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
