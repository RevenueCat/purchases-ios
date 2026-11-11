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

    private let onPrewarmWorkflowAssets: (@Sendable (String) -> Void)?
    private let workflowAssetPrewarmingHandler: (@Sendable (String) async -> Void)?

    init(
        workflowAssetPrewarmingHandler: (@Sendable (String) async -> Void)? = nil,
        onPrewarmWorkflowAssets: (@Sendable (String) -> Void)? = nil
    ) {
        self.workflowAssetPrewarmingHandler = workflowAssetPrewarmingHandler
        self.onPrewarmWorkflowAssets = onPrewarmWorkflowAssets
    }

    let eligibilityWarmupPriority: Atomic<TaskPriority?> = .init(nil)
    let assetsWarmupPriority: Atomic<TaskPriority?> = .init(nil)
    let fontsWarmupPriority: Atomic<TaskPriority?> = .init(nil)

    private let _invokedPrewarmEligibilityCache: Atomic<Bool> = false
    private let _invokedPrewarmEligibilityCacheOfferings: Atomic<Offerings?> = nil

    var invokedPrewarmEligibilityCache: Bool {
        get { return self._invokedPrewarmEligibilityCache.value }
        set { self._invokedPrewarmEligibilityCache.value = newValue }
    }
    var invokedPrewarmEligibilityCacheOfferings: Offerings? {
        get { return self._invokedPrewarmEligibilityCacheOfferings.value }
        set { self._invokedPrewarmEligibilityCacheOfferings.value = newValue }
    }

    func prewarmEligibilityCache(offerings: Offerings) {
        self.eligibilityWarmupPriority.value = Task.currentPriority
        self.invokedPrewarmEligibilityCache = true
        self.invokedPrewarmEligibilityCacheOfferings = offerings
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

    private let _invokedPrewarmPaywallAssetsCache: Atomic<Bool> = false
    private let _invokedPrewarmPaywallAssetsCacheOfferings: Atomic<Offerings?> = nil

    var invokedPrewarmPaywallAssetsCache: Bool {
        get { return self._invokedPrewarmPaywallAssetsCache.value }
        set { self._invokedPrewarmPaywallAssetsCache.value = newValue }
    }
    var invokedPrewarmPaywallAssetsCacheOfferings: Offerings? {
        get { return self._invokedPrewarmPaywallAssetsCacheOfferings.value }
        set { self._invokedPrewarmPaywallAssetsCacheOfferings.value = newValue }
    }

    func prewarmPaywallAssetsCache(offerings: Offerings) async {
        self.assetsWarmupPriority.value = Task.currentPriority
        self.invokedPrewarmPaywallAssetsCache = true
        self.invokedPrewarmPaywallAssetsCacheOfferings = offerings
    }

    // MARK: -

    private let _invokedPrewarmPaywallFontsCache: Atomic<Bool> = false
    private let _invokedPrewarmPaywallFontsCacheOfferings: Atomic<Offerings?> = nil

    var invokedPrewarmPaywallFontsCache: Bool {
        get { return self._invokedPrewarmPaywallFontsCache.value }
        set { self._invokedPrewarmPaywallFontsCache.value = newValue }
    }
    var invokedPrewarmPaywallFontsCacheOfferings: Offerings? {
        get { return self._invokedPrewarmPaywallFontsCacheOfferings.value }
        set { self._invokedPrewarmPaywallFontsCacheOfferings.value = newValue }
    }

    func prewarmPaywallFontsCache(offerings: Offerings) {
        self.fontsWarmupPriority.value = Task.currentPriority
        self.invokedPrewarmPaywallFontsCache = true
        self.invokedPrewarmPaywallFontsCacheOfferings = offerings
    }

    // MARK: -

    private let _invokedPrewarmWorkflowAssets: Atomic<Bool> = false
    private let _invokedPrewarmWorkflowAssetsCount: Atomic<Int> = .init(0)
    private let _invokedPrewarmWorkflowAssetIDs: Atomic<[String]> = .init([])
    private let _invokedPrewarmWorkflowAssetsWorkflow: Atomic<PublishedWorkflow?> = nil
    private let _invokedPrewarmWorkflowAssetsUiConfig: Atomic<UIConfig?> = nil
    private let _preparedWorkflowAssetIDs: Atomic<Set<String>> = .init([])

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

    func startPrewarmingWorkflowAssets(
        workflow: PublishedWorkflow,
        uiConfig: UIConfig
    ) async -> Task<Void, Never>? {
        guard self._preparedWorkflowAssetIDs.modify({ $0.insert(workflow.id).inserted }) else { return nil }
        self.invokedPrewarmWorkflowAssetsWorkflow = workflow
        self.invokedPrewarmWorkflowAssetsUiConfig = uiConfig
        self.onPrewarmWorkflowAssets?(workflow.id)
        self.invokedPrewarmWorkflowAssets = true
        self._invokedPrewarmWorkflowAssetsCount.modify { $0 += 1 }
        self._invokedPrewarmWorkflowAssetIDs.modify { $0.append(workflow.id) }
        let handler = self.workflowAssetPrewarmingHandler
        return Task {
            _ = await handler?(workflow.id)
        }
    }

    func hasStartedPrewarmingWorkflowAssets(for workflowID: String) async -> Bool {
        return self._preparedWorkflowAssetIDs.value.contains(workflowID)
            || self.invokedPrewarmWorkflowAssetIDs.contains(workflowID)
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
        self.invokedPrewarmEligibilityCache = true
        self.invokedTriggerFontDownloadIfNeededFontsConfig = fontsConfig
    }

#endif
}
