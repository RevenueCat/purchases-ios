//
//  RewardedAdPromptSession.swift
//
//  Created by RevenueCat.
//

import Foundation

#if ENABLE_CONFIGURED_AD_REWARDS && os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)

/// Defines the logical lifetime of a rewarded-ad prompt for impression tracking.
///
/// Reuse the same session when a prompt can be rendered repeatedly without each rendering representing
/// a new prompt impression. Accepting the prompt resets the session so its next appearance can be tracked.
@available(iOS 15.0, *)
@MainActor
public final class RewardedAdPromptSession {

    private var hasTrackedPromptShown = false

    /// Creates a rewarded-ad prompt tracking session.
    public init() {}

    /// Returns whether the current appearance should produce a prompt-shown event.
    ///
    func consumePromptShown() -> Bool {
        guard !self.hasTrackedPromptShown else { return false }

        self.hasTrackedPromptShown = true
        return true
    }

    /// Allows the next appearance to represent a new prompt after the current prompt is accepted.
    func resetAfterAcceptance() {
        self.hasTrackedPromptShown = false
    }

}

#endif
