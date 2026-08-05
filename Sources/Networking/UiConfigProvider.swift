//
//  UiConfigProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Assembles a ``UIConfig`` from the `ui_config` topic's four blob items (`app`, `localizations`,
/// `variable_config`, `custom_variables`). Item keys are literal wire names, not camelCased: unlike
/// `ConfigItem.content`, they're raw dictionary keys and aren't run through `.convertFromSnakeCase`.
final class UiConfigProvider {

    private let manager: RemoteConfigManagerType
    private let cache = GenerationGuardedCache<RemoteConfiguration.ConfigTopic, UIConfig>()

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

#if !os(tvOS)
    /// Assembles a ``UIConfig`` from the `ui_config` topic's parts. Returns `nil` when any part is unavailable
    /// or fails to decode, so callers never render with a partially assembled configuration.
    func getUiConfig() async -> UIConfig? {
        guard let snapshot = await self.manager.topicCacheSnapshot(.uiConfig) else {
            return nil
        }

        if let cached = self.cache.value(for: snapshot) {
            return cached
        }

        guard let uiConfig = await self.assembleUiConfig() else {
            return nil
        }

        guard await self.manager.isCurrent(snapshot, for: .uiConfig) else {
            self.cache.clearIfStale(currentGeneration: self.manager.configGeneration)
            return nil
        }

        self.cache.store(uiConfig, for: snapshot)
        return uiConfig
    }

    /// Returns the in-memory config without awaiting remote-config state. This is used only to seed
    /// first-frame workflow rendering after the offerings readiness gate has already warmed config.
    func cachedUiConfig() -> UIConfig? {
        return self.manager.withCurrentConfigGeneration { generation in
            self.cachedUiConfig(currentGeneration: generation)
        }
    }

    func cachedUiConfig(currentGeneration: Int) -> UIConfig? {
        return self.cache.value(currentGeneration: currentGeneration)
    }

    private func assembleUiConfig() async -> UIConfig? {
        do {
            guard let uiConfig = try await self.manager.mergeItemsBlobData(
                for: .uiConfig,
                itemKeys: Self.itemKeys,
                as: UIConfig.self
            ) else {
                if !self.manager.isDisabled {
                    Logger.warn(Strings.remoteConfig.uiConfigMissingRequiredPart)
                }
                return nil
            }

            return uiConfig
        } catch {
            Logger.error(Strings.remoteConfig.uiConfigDecodeFailed(error))
            return nil
        }
    }

#else
    // Paywalls V2 (and therefore workflows) aren't supported on tvOS, where `UIConfig` carries no fields.
    func getUiConfig() async -> UIConfig? {
        guard let snapshot = await self.manager.topicCacheSnapshot(.uiConfig) else {
            return nil
        }

        if let cached = self.cache.value(for: snapshot) {
            return cached
        }

        guard !self.manager.isDisabled else { return nil }
        guard await self.manager.blobData(for: .uiConfig, itemKey: Self.appKey) != nil,
              await self.manager.blobData(for: .uiConfig, itemKey: Self.localizationsKey) != nil else {
            Logger.warn(Strings.remoteConfig.uiConfigMissingRequiredPart)
            return nil
        }

        guard await self.manager.isCurrent(snapshot, for: .uiConfig) else {
            self.cache.clearIfStale(currentGeneration: self.manager.configGeneration)
            return nil
        }

        self.cache.store(.empty, for: snapshot)
        return .empty
    }

    func cachedUiConfig() -> UIConfig? {
        return self.manager.withCurrentConfigGeneration { generation in
            self.cachedUiConfig(currentGeneration: generation)
        }
    }

    func cachedUiConfig(currentGeneration: Int) -> UIConfig? {
        return self.cache.value(currentGeneration: currentGeneration)
    }
#endif

    private static let appKey = "app"
    private static let localizationsKey = "localizations"
    private static let variableConfigKey = "variable_config"
    private static let customVariablesKey = "custom_variables"
    private static var itemKeys: [String] {
        return [
            Self.appKey,
            Self.localizationsKey,
            Self.variableConfigKey,
            Self.customVariablesKey
        ]
    }

}

extension UiConfigProvider: @unchecked Sendable {}
