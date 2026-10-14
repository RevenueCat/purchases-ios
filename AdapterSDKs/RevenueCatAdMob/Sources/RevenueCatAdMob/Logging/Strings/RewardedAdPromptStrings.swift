//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptStrings.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@_spi(Internal) import RevenueCat

// swiftlint:disable identifier_name
@available(iOS 15.0, *)
enum RewardedAdPromptStrings: LogMessage {

    case purchases_not_configured
    case configured_rewards_unavailable(adUnitID: String)

    var description: String {
        switch self {
        case .purchases_not_configured:
            return "RevenueCat is not configured. The rewarded ad prompt cannot be displayed."
        case let .configured_rewards_unavailable(adUnitID):
            return "Reward configuration is unavailable for ad unit \(adUnitID). " +
                "The prompt can display without metadata."
        }
    }

    var category: String { return "rewardedadprompt" }

}
#endif
