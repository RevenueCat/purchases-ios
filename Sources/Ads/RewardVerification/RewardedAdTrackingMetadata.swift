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
