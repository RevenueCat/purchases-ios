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

final class MockPaywallCacheWarming: PaywallCacheWarmingType {

    private let _invokedWarmUpEligibilityCache: Atomic<Bool> = false
    private let _invokedWarmUpEligibilityCacheOfferings: Atomic<Offerings?> = nil

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

    private let _invokedClearEligibilityCache: Atomic<Bool> = false
    private let _invokedClearEligibilityCacheCount: Atomic<Int> = .init(0)

    var invokedClearEligibilityCache: Bool {
        get { return self._invokedClearEligibilityCache.value }
        set { self._invokedClearEligibilityCache.value = newValue }
    }
    var invokedClearEligibilityCacheCount: Int {
        get { return self._invokedClearEligibilityCacheCount.value }
        set { self._invokedClearEligibilityCacheCount.value = newValue }
    }

    func clearEligibilityCache() {
        self.invokedClearEligibilityCache = true
        self._invokedClearEligibilityCacheCount.modify { $0 += 1 }
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

    private let _invokedWarmUpPaywallVideosCache: Atomic<Bool> = false
    private let _invokedWarmUpPaywallVideosCacheOfferings: Atomic<Offerings?> = nil

    var invokedWarmUpPaywallVideosCache: Bool {
        get { return self._invokedWarmUpPaywallVideosCache.value }
        set { self._invokedWarmUpPaywallVideosCache.value = newValue }
    }
    var invokedWarmUpPaywallVideosCacheOfferings: Offerings? {
        get { return self._invokedWarmUpPaywallVideosCacheOfferings.value }
        set { self._invokedWarmUpPaywallVideosCacheOfferings.value = newValue }
    }

    func warmUpPaywallVideosCache(offerings: Offerings) async {
        self.invokedWarmUpPaywallVideosCache = true
        self.invokedWarmUpPaywallVideosCacheOfferings = offerings
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

    // MARK: -

    private let _invokedPrewarmWorkflowAssets: Atomic<Bool> = false
    private let _invokedPrewarmWorkflowAssetsCount: Atomic<Int> = .init(0)
    private let _invokedPrewarmWorkflowAssetIDs: Atomic<[String]> = .init([])
    private let _invokedPrewarmWorkflowAssetsWorkflow: Atomic<PublishedWorkflow?> = nil
    private let _invokedPrewarmWorkflowAssetsUiConfig: Atomic<UIConfig?> = nil

    var invokedPrewarmWorkflowAssets: Bool {
        get { return self._invokedPrewarmWorkflowAssets.value }
        set { self._invokedPrewarmWorkflowAssets.value = newValue }
    }
    var invokedPrewarmWorkflowAssetsCount: Int {
        get { return self._invokedPrewarmWorkflowAssetsCount.value }
        set { self._invokedPrewarmWorkflowAssetsCount.value = newValue }
    }
    var invokedPrewarmWorkflowAssetIDs: [String] {
        return self._invokedPrewarmWorkflowAssetIDs.value
    }
    var invokedPrewarmWorkflowAssetsWorkflow: PublishedWorkflow? {
        get { return self._invokedPrewarmWorkflowAssetsWorkflow.value }
        set { self._invokedPrewarmWorkflowAssetsWorkflow.value = newValue }
    }
    var invokedPrewarmWorkflowAssetsUiConfig: UIConfig? {
        get { return self._invokedPrewarmWorkflowAssetsUiConfig.value }
        set { self._invokedPrewarmWorkflowAssetsUiConfig.value = newValue }
    }

    func prewarmWorkflowAssets(workflow: PublishedWorkflow, uiConfig: UIConfig) async {
        self.invokedPrewarmWorkflowAssets = true
        self._invokedPrewarmWorkflowAssetsCount.modify { $0 += 1 }
        self._invokedPrewarmWorkflowAssetIDs.modify { $0.append(workflow.id) }
        self.invokedPrewarmWorkflowAssetsWorkflow = workflow
        self.invokedPrewarmWorkflowAssetsUiConfig = uiConfig
    }

#if !os(tvOS)

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
