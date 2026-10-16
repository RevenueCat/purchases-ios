//
//  RewardedAdPromptSession.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)

/// Defines the logical lifetime of a rewarded-ad prompt for impression tracking.
///
/// Reuse the same session when a prompt can be rendered repeatedly without each rendering representing
/// a new prompt impression. Accepting the prompt resets the session so its next appearance can be tracked.
/// A replacement session takes effect on the next appearance, without emitting an event when it is supplied.
/// The placement recorded when the offer appears is retained for its acceptance event.
@available(iOS 15.0, *)
@MainActor
public final class RewardedAdPromptSession {

    private var hasTrackedPromptShown = false
    private var shownPlacement: String?

    /// Creates a rewarded-ad prompt tracking session.
    public init() {}

    /// Returns whether the current appearance should produce a prompt-shown event.
    ///
    func consumePromptShown(placement: String? = nil) -> Bool {
        guard !self.hasTrackedPromptShown else { return false }

        self.hasTrackedPromptShown = true
        self.shownPlacement = placement
        return true
    }

    func placementForAcceptance(fallback: String?) -> String? {
        return self.hasTrackedPromptShown ? self.shownPlacement : fallback
    }

    /// Allows the next appearance to represent a new prompt after the current prompt is accepted.
    func resetAfterAcceptance() {
        self.hasTrackedPromptShown = false
        self.shownPlacement = nil
    }

}

#endif
