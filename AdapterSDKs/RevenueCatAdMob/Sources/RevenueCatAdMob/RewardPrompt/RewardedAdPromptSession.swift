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

    /// Creates a rewarded-ad prompt tracking session.
    public init() {}

}

#endif
