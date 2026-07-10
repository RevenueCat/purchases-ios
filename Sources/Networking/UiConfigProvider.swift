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
    private let cacheLock = Lock()
    // Last decoded config and the `ui_config` topic it was built from. Reused while the topic
    // is unchanged so repeated callers (the offerings gate, workflow render) don't re-read and
    // re-decode the blobs on every call. Blob refs are content-addressed, so any content change
    // moves the topic and invalidates this.
    private var cached: (topic: RemoteConfiguration.ConfigTopic, uiConfig: UIConfig)?

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

#if !os(tvOS)
    /// Assembles a ``UIConfig`` from the `ui_config` topic's parts. Returns `nil` when any part is
    /// unavailable or fails to decode, so callers never render with a partially assembled
    /// configuration. Successful results are memoized per `ui_config` topic; a topic change re-decodes.
    func getUiConfig() async -> UIConfig? {
        let topic = await self.manager.topic(.uiConfig)
        if let cached = self.cachedUiConfig(for: topic) {
            return cached
        }

        guard let uiConfig = await self.assembleUiConfig() else {
            return nil
        }
        // `mergeItemsBlobData` reads the manager's live topic, so a refresh mid-assembly could
        // decode a topic other than the key captured above. Only memoize when the topic is
        // unchanged across the assembly.
        if await self.manager.topic(.uiConfig) == topic {
            self.store(uiConfig, for: topic)
        }
        return uiConfig
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

    private func cachedUiConfig(for topic: RemoteConfiguration.ConfigTopic?) -> UIConfig? {
        return self.cacheLock.perform {
            guard let cached = self.cached, cached.topic == topic else { return nil }
            return cached.uiConfig
        }
    }

    private func store(_ uiConfig: UIConfig, for topic: RemoteConfiguration.ConfigTopic?) {
        // A successful assembly always has a concrete topic (its items are topic items);
        // never cache under a nil key.
        guard let topic else { return }
        self.cacheLock.perform { self.cached = (topic, uiConfig) }
    }
#else
    // Paywalls V2 (and therefore workflows) aren't supported on tvOS, where `UIConfig` carries no fields.
    func getUiConfig() async -> UIConfig? {
        guard !self.manager.isDisabled else { return nil }
        guard await self.manager.blobData(for: .uiConfig, itemKey: Self.appKey) != nil,
              await self.manager.blobData(for: .uiConfig, itemKey: Self.localizationsKey) != nil else {
            Logger.warn(Strings.remoteConfig.uiConfigMissingRequiredPart)
            return nil
        }
        return .empty
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
