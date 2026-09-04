//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdTrackingMetadata.swift
//

import Foundation

/// Ad metadata for a rewarded ad events while polling reward verification.
///
/// Pass this to ``pollRewardVerification(clientTransactionID:trackingMetadata:)`` to have the
/// SDK automatically track those events.
public struct RewardedAdTrackingMetadata: Sendable {

    /// The ad network that served the rewarded ad, as reported by the mediator, if available.
    public let networkName: String?

    /// The mediation network that brokered the rewarded ad.
    public let mediatorName: MediatorName

    /// The format of the rewarded ad.
    public let adFormat: AdFormat

    /// The developer-defined placement where the rewarded ad was shown, if provided.
    public let placement: String?

    /// The ad unit identifier for the rewarded ad.
    public let adUnitId: String

    /// Identifier that correlates the tracked reward events with the same ad impression.
    public let impressionId: String

    // swiftlint:disable missing_docs
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
