//
//  RewardVerification.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

/// Namespace for the AdMob adapter's reward-verification (SSV) subsystem.
@available(iOS 15.0, *)
internal enum RewardVerification {

    /// Shared side effects triggered by reward-verification outcomes.
    enum SideEffects {

        /// Invalidates virtual-currency cache if the SDK is configured.
        ///
        /// This is test-injected in `RevenueCatAdMobTests` and should remain simple.
        static var invalidateVirtualCurrenciesCache: () -> Void = {
            guard Purchases.isConfigured else { return }
            Purchases.shared.invalidateVirtualCurrenciesCache()
        }
    }
}

#endif
