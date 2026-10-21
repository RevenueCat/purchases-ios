//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptContext.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat

/// Information and actions provided to a ``RewardedAdPrompt`` content builder.
@available(iOS 15.0, *)
@MainActor
public struct RewardedAdPromptContext {

    /// Rewards configured for RevenueCat to grant after successful server-side verification,
    /// or `nil` when the configuration is unavailable.
    /// A non-`nil` container with no primary or additional rewards means configuration is available,
    /// but no rewards were configured. Neither state prevents accepting the prompt or enables verification.
    public let rewardConfiguration: ConfiguredAdRewards?

    /// Accepts the prompt, tracks the acceptance, and presents the loaded rewarded ad.
    ///
    /// Only the first call for a rendered prompt has an effect.
    /// If no attached presentation controller is available, `onResult` reports `.notPresented`
    /// asynchronously after this method returns.
    public func accept() {
        fatalError("Implemented in the next stacked PR.")
    }

}

#endif
