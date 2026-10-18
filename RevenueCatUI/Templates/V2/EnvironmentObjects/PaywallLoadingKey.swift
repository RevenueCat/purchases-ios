//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallLoadingKey.swift
//
//  Created by RevenueCat on 5/12/26.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct IntroOfferEligibilityLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PromoOfferEligibilityLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var isPaywallLoading: Bool {
        get { self[PaywallLoadingKey.self] }
        set { self[PaywallLoadingKey.self] = newValue }
    }

    var isIntroOfferEligibilityLoading: Bool {
        get { self[IntroOfferEligibilityLoadingKey.self] }
        set { self[IntroOfferEligibilityLoadingKey.self] = newValue }
    }

    var isPromoOfferEligibilityLoading: Bool {
        get { self[PromoOfferEligibilityLoadingKey.self] }
        set { self[PromoOfferEligibilityLoadingKey.self] = newValue }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func redactedWhileOfferEligibilityLoads(
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        isVisible: @escaping (Bool, Bool) -> Bool
    ) -> some View {
        self.modifier(OfferEligibilityRedactionModifier(
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            isVisible: isVisible
        ))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OfferEligibilityRedactionModifier: ViewModifier {

    @Environment(\.isIntroOfferEligibilityLoading)
    private var isIntroOfferEligibilityLoading

    @Environment(\.isPromoOfferEligibilityLoading)
    private var isPromoOfferEligibilityLoading

    @Environment(\.redactionReasons)
    private var redactionReasons

    let isEligibleForIntroOffer: Bool
    let isEligibleForPromoOffer: Bool
    let isVisible: (Bool, Bool) -> Bool

    func body(content: Content) -> some View {
        let offerEligibility = OfferEligibilityState(
            isEligibleForIntroOffer: self.isEligibleForIntroOffer,
            isEligibleForPromoOffer: self.isEligibleForPromoOffer,
            isIntroOfferEligibilityLoading: self.isIntroOfferEligibilityLoading,
            isPromoOfferEligibilityLoading: self.isPromoOfferEligibilityLoading
        )
        let possibleVisibilities = offerEligibility.unresolvedOutcomes(variesWithEligibility: true).map {
            self.isVisible($0.isEligibleForIntroOffer, $0.isEligibleForPromoOffer)
        }
        let shouldRedact = offerEligibility.isLoading && Set(possibleVisibilities).count > 1
        content.redacted(reason: shouldRedact ? self.redactionReasons.union(.placeholder) : self.redactionReasons)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallLoadingOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// Overrides paywall and eligibility loading from outside `PaywallsV2View` for preview and test contexts.
    var paywallLoadingOverride: Bool? {
        get { self[PaywallLoadingOverrideKey.self] }
        set { self[PaywallLoadingOverrideKey.self] = newValue }
    }

}

#endif

#endif
