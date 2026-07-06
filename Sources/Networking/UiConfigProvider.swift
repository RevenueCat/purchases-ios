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

    /// Assembles a ``UIConfig`` from the `ui_config` topic's parts. Returns `nil` when a required part
    /// (`app` or `localizations`) is unavailable; `UIConfig`'s own decoding already defaults the rest.
    ///
    /// The four parts are unrelated blobs, fetched concurrently rather than one at a time, so a cold
    /// cache pays for one round trip instead of four sequential ones.
    func getUiConfig() async -> UIConfig? {
        let parts = await withTaskGroup(of: (String, Any?).self) { group in
            for key in Self.partKeys {
                group.addTask {
                    guard let data = await self.manager.blobData(for: .uiConfig, itemKey: key) else {
                        return (key, nil)
                    }
                    return (key, try? JSONSerialization.jsonObject(with: data))
                }
            }

            return await group.reduce(into: [String: Any]()) { parts, result in
                let (key, jsonObject) = result
                parts[key] = jsonObject
            }
        }

        guard parts[Self.appKey] != nil, parts[Self.localizationsKey] != nil else {
            return nil
        }

        return try? JSONDecoder.default.decode(UIConfig.self, dictionary: parts)
    }

    private static let appKey = "app"
    private static let localizationsKey = "localizations"
    private static let variableConfigKey = "variable_config"
    private static let customVariablesKey = "custom_variables"
    private static let partKeys = [appKey, localizationsKey, variableConfigKey, customVariablesKey]

}
