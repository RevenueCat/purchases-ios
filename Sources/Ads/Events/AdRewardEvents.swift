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
        try self.reward.encode(
            into: &container,
            typeKey: .rewardType,
            codeKey: .rewardCurrencyCode,
            amountKey: .rewardCurrencyAmount
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
                codeKey: .rewardCurrencyCode,
                amountKey: .rewardCurrencyAmount
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
