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
    /// Assembles a ``UIConfig`` from the `ui_config` topic's parts. Returns `nil` when a required part
    /// (`app` or `localizations`) is unavailable or fails to decode.
    ///
    /// Each part decodes independently: a malformed `variable_config` or `custom_variables` blob falls
    /// back to its own default instead of invalidating the whole result, since those parts already have
    /// defaults `UIConfig` can use elsewhere.
    func getUiConfig() async -> UIConfig? {
        async let app = self.decodePart(UIConfig.AppConfig.self, itemKey: Self.appKey)
        async let localizations = self.decodePart([String: [String: String]].self, itemKey: Self.localizationsKey)
        async let variableConfig = self.decodePart(UIConfig.VariableConfig.self, itemKey: Self.variableConfigKey)
        async let customVariables = self.decodePart(
            [String: UIConfig.CustomVariableDefinition].self,
            itemKey: Self.customVariablesKey
        )

        guard let app = await app, let localizations = await localizations else {
            Logger.warn(Strings.remoteConfig.uiConfigMissingRequiredPart)
            return nil
        }

        return UIConfig(
            app: app,
            localizations: localizations,
            variableConfig: await variableConfig ?? Self.defaultVariableConfig,
            customVariables: await customVariables ?? [:]
        )
    }

    private func decodePart<T: Decodable>(_ type: T.Type, itemKey: String) async -> T? {
        do {
            return try await self.manager.blobData(for: .uiConfig, itemKey: itemKey, as: type)
        } catch {
            Logger.error(Strings.remoteConfig.uiConfigPartDecodeFailed(itemKey: itemKey, error: error))
            return nil
        }
    }

    private static let defaultVariableConfig = UIConfig.VariableConfig(
        variableCompatibilityMap: [:],
        functionCompatibilityMap: [:]
    )
#else
    // Paywalls V2 (and therefore workflows) aren't supported on tvOS, where `UIConfig` carries no fields.
    func getUiConfig() async -> UIConfig? {
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

}
