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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct OfferEligibilityLoading: OptionSet {

    let rawValue: Int

    static let intro = Self(rawValue: 1 << 0)
    static let promo = Self(rawValue: 1 << 1)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(intro: Bool, promo: Bool) {
        var loading: Self = []
        if intro {
            loading.insert(.intro)
        }
        if promo {
            loading.insert(.promo)
        }
        self = loading
    }

}

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OfferEligibilityLoadingKey: EnvironmentKey {
    static let defaultValue: OfferEligibilityLoading = []
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var offerEligibilityLoading: OfferEligibilityLoading {
        get { self[OfferEligibilityLoadingKey.self] }
        set { self[OfferEligibilityLoadingKey.self] = newValue }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OfferEligibilityLoadingOverrideKey: EnvironmentKey {
    static let defaultValue: OfferEligibilityLoading? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// Overrides eligibility loading from outside `PaywallsV2View` for preview and test contexts.
    var offerEligibilityLoadingOverride: OfferEligibilityLoading? {
        get { self[OfferEligibilityLoadingOverrideKey.self] }
        set { self[OfferEligibilityLoadingOverrideKey.self] = newValue }
    }

}

#endif

#endif
