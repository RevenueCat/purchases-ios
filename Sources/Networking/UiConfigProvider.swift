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

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

#if !os(tvOS)
    /// Assembles a ``UIConfig`` from the `ui_config` topic's parts. Returns `nil` when any part is unavailable
    /// or fails to decode, so callers never render with a partially assembled configuration.
    func getUiConfig() async -> UIConfig? {
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
