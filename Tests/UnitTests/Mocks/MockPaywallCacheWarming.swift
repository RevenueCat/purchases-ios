//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPaywallCacheWarming.swift
//
//  Created by Nacho Soto on 8/7/23.

import Foundation
@_spi(Internal) @testable import RevenueCat

private final class MockPaywallPromoOfferCacheType: RevenueCat.PaywallPromoOfferCacheType {

}

final class MockPaywallCacheWarming: PaywallCacheWarmingType {

    private let _invokedWarmUpEligibilityCache: Atomic<Bool> = false
    private let _invokedWarmUpEligibilityCacheOfferings: Atomic<Offerings?> = nil

    let promoOfferCache: PaywallPromoOfferCacheType = MockPaywallPromoOfferCacheType()

    var invokedWarmUpEligibilityCache: Bool {
        get { return self._invokedWarmUpEligibilityCache.value }
        set { self._invokedWarmUpEligibilityCache.value = newValue }
    }
    var invokedWarmUpEligibilityCacheOfferings: Offerings? {
        get { return self._invokedWarmUpEligibilityCacheOfferings.value }
        set { self._invokedWarmUpEligibilityCacheOfferings.value = newValue }
    }

    func warmUpEligibilityCache(offerings: Offerings) {
        self.invokedWarmUpEligibilityCache = true
        self.invokedWarmUpEligibilityCacheOfferings = offerings
    }

    // MARK: -

    private let _invokedWarmUpPaywallImagesCache: Atomic<Bool> = false
    private let _invokedWarmUpPaywallImagesCacheOfferings: Atomic<Offerings?> = nil

    var invokedWarmUpPaywallImagesCache: Bool {
        get { return self._invokedWarmUpPaywallImagesCache.value }
        set { self._invokedWarmUpPaywallImagesCache.value = newValue }
    }
    var invokedWarmUpPaywallImagesCacheOfferings: Offerings? {
        get { return self._invokedWarmUpPaywallImagesCacheOfferings.value }
        set { self._invokedWarmUpPaywallImagesCacheOfferings.value = newValue }
    }

    func warmUpPaywallImagesCache(offerings: Offerings) {
        self.invokedWarmUpPaywallImagesCache = true
        self.invokedWarmUpPaywallImagesCacheOfferings = offerings
    }

    // MARK: -

    private let _invokedWarmUpPaywallFontsCache: Atomic<Bool> = false
    private let _invokedWarmUpPaywallFontsCacheOfferings: Atomic<Offerings?> = nil

    var invokedWarmUpPaywallFontsCache: Bool {
        get { return self._invokedWarmUpPaywallFontsCache.value }
        set { self._invokedWarmUpPaywallFontsCache.value = newValue }
    }
    var invokedWarmUpPaywallFontsCacheOfferings: Offerings? {
        get { return self._invokedWarmUpPaywallFontsCacheOfferings.value }
        set { self._invokedWarmUpPaywallFontsCacheOfferings.value = newValue }
    }

    func warmUpPaywallFontsCache(offerings: Offerings) {
        self.invokedWarmUpPaywallFontsCache = true
        self.invokedWarmUpPaywallFontsCacheOfferings = offerings
    }

#if !os(macOS) && !os(tvOS)

    private let _invokedTriggerFontDownloadIfNeeded: Atomic<Bool> = false
    private let _invokedTriggerFontDownloadIfNeededFontsConfig: Atomic<UIConfig.FontsConfig?> = nil

    var invokedTriggerFontDownloadIfNeeded: Bool {
        get { return self._invokedTriggerFontDownloadIfNeeded.value }
        set { self._invokedTriggerFontDownloadIfNeeded.value = newValue }
    }
    var invokedTriggerFontDownloadIfNeededFontsConfig: UIConfig.FontsConfig? {
        get { return self._invokedTriggerFontDownloadIfNeededFontsConfig.value }
        set { self._invokedTriggerFontDownloadIfNeededFontsConfig.value = newValue }
    }

    func triggerFontDownloadIfNeeded(fontsConfig: UIConfig.FontsConfig) async {
        self.invokedWarmUpEligibilityCache = true
        self.invokedTriggerFontDownloadIfNeededFontsConfig = fontsConfig
    }

#endif
}
