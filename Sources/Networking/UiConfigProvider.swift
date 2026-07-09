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
    /// Optional parts decode independently so missing or malformed optional blobs fall back to the same
    /// defaults as `UIConfig`'s decoder.
    func getUiConfig() async -> UIConfig? {
        do {
            guard let requiredParts = try await self.manager.mergeItemsBlobData(
                for: .uiConfig,
                itemKeys: Self.requiredItemKeys,
                as: RequiredParts.self
            ) else {
                if !self.manager.isDisabled {
                    Logger.warn(Strings.remoteConfig.uiConfigMissingRequiredPart)
                }
                return nil
            }

            let topic = await self.manager.topic(.uiConfig)
            async let variableConfig = self.decodeOptionalPart(
                UIConfig.VariableConfig.self,
                itemKey: Self.variableConfigKey,
                topic: topic
            )
            async let customVariables = self.decodeOptionalPart(
                [String: UIConfig.CustomVariableDefinition].self,
                itemKey: Self.customVariablesKey,
                topic: topic
            )

            return UIConfig(
                app: requiredParts.app,
                localizations: requiredParts.localizations,
                variableConfig: await variableConfig ?? Self.defaultVariableConfig,
                customVariables: await customVariables ?? [:]
            )
        } catch {
            Logger.error(Strings.remoteConfig.uiConfigDecodeFailed(error))
            return nil
        }
    }

    private func decodeOptionalPart<T: Decodable>(
        _ type: T.Type,
        itemKey: String,
        topic: RemoteConfiguration.ConfigTopic?
    ) async -> T? {
        guard topic?[itemKey] != nil else { return nil }

        do {
            return try await self.manager.blobData(for: .uiConfig, itemKey: itemKey, as: type)
        } catch {
            Logger.error(Strings.remoteConfig.uiConfigPartDecodeFailed(itemKey: itemKey, error: error))
            return nil
        }
    }

    private struct RequiredParts: Decodable {
        let app: UIConfig.AppConfig
        let localizations: [String: [String: String]]
    }

    private static let defaultVariableConfig = UIConfig.VariableConfig(
        variableCompatibilityMap: [:],
        functionCompatibilityMap: [:]
    )
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
    private static var requiredItemKeys: [String] {
        return [
            Self.appKey,
            Self.localizationsKey
        ]
    }

}

extension UiConfigProvider: @unchecked Sendable {}
