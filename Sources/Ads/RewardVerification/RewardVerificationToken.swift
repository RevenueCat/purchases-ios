//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationToken.swift
//

import Foundation

/// Ties a loaded rewarded ad to its server-side reward verification
@_spi(Experimental) public struct RewardVerificationToken: Sendable, Equatable {

    /// Set as the ad network's server-side verification custom data.
    public let customData: String

    /// Correlates the ad with its verification
    public let clientTransactionID: String

    /// The app user the reward is attributed to; set as the ad network's SSV user identifier.
    public let appUserID: String

    /// Creates a token for reward verification
    @_spi(Internal) public init(
        customData: String,
        clientTransactionID: String,
        appUserID: String
    ) {
        self.customData = customData
        self.clientTransactionID = clientTransactionID
        self.appUserID = appUserID
    }
}
