//
//  StateStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Holds the per-ad ``RewardVerification/State`` for a vendor ad object.
    ///
    /// Implemented as a `Tracking.AssociatedObjectStore<State>` so retention semantics, key
    /// management, and main-actor invariants match every other associated-object store in the
    /// adapter (`Tracking.FullScreenDelegateStore`, `Tracking.BannerDelegateStore`, etc.).
    typealias StateStore = Tracking.AssociatedObjectStore<State>

    /// Process-wide singleton store for per-ad ``RewardVerification/State``.
    ///
    /// The stash uses `OBJC_ASSOCIATION_RETAIN_NONATOMIC` (the default), so concurrent access
    /// from multiple threads is unsafe. By convention all calls happen on the main actor:
    /// ``RewardVerification/Setup/install(on:apiKey:appUserID:)`` is `@MainActor`, and the
    /// present-time wiring in PR4 will only read the stashed state from `RewardedAd.present`,
    /// which GMA already invokes on the main thread.
    static let stateStore = StateStore()
}

#endif
