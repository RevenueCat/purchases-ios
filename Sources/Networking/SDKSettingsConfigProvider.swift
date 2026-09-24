//
//  SDKSettingsConfigProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

protocol SDKSettingsConfigProviderType {

    func settings() async -> SDKSettings
    func cachedSettings() -> SDKSettings?

}

protocol SDKSettingsConfigProviderDelegate: AnyObject {

    func sdkSettingsConfigProviderDidUpdate(_ provider: SDKSettingsConfigProviderType) async

}

/// Loads SDK settings from the `sdk_settings` topic's inline `default` item.
final class SDKSettingsConfigProvider: SDKSettingsConfigProviderType, RemoteConfigStateObserver {

    private let manager: RemoteConfigManagerType
    private let cache = GenerationGuardedCache<String, SDKSettings>()
    weak var delegate: SDKSettingsConfigProviderDelegate?

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func settings() async -> SDKSettings {
        if let cachedSettings = self.cachedSettings() {
            return cachedSettings
        }

        do {
            return try await self.manager.readConsistent {
                guard let item = await self.manager.topic(.sdkSettings)?[Self.defaultItemKey] else {
                    return Self.fallbackSettings
                }
                return try Self.decodeSettings(from: item)
            } ?? Self.fallbackSettings
        } catch {
            Logger.error(Strings.codable.decoding_error(error, SDKSettings.self))
            return Self.fallbackSettings
        }
    }

    func cachedSettings() -> SDKSettings? {
        return self.manager.withCurrentConfigGeneration { generation in
            self.cache.value(currentGeneration: generation)
        }
    }

    func remoteConfigStateDidChange(generation _: Int) {
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func refresh() async {
        guard await self.manager.hasCommittedConfig() else { return }

        let generation = self.manager.configGeneration
        let settings: SDKSettings
        do {
            let item = await self.manager.topic(.sdkSettings, policy: .cachedOnly)?[Self.defaultItemKey]
            settings = try item.map(Self.decodeSettings) ?? Self.fallbackSettings
        } catch {
            Logger.error(Strings.codable.decoding_error(error, SDKSettings.self))
            settings = Self.fallbackSettings
        }
        guard self.manager.configGeneration == generation else { return }

        self.cache.store(settings, for: .init(generation: generation, key: Self.cacheKey))
        await self.delegate?.sdkSettingsConfigProviderDidUpdate(self)
    }

    private static func decodeSettings(from item: RemoteConfiguration.ConfigItem) throws -> SDKSettings {
        let data = try JSONEncoder.default.encode(item.content)
        return try JSONDecoder.default.decode(SDKSettings.self, from: data)
    }

    private static let defaultItemKey = "default"
    private static let cacheKey = "sdk_settings"
    private static let fallbackSettings = SDKSettings()

}

extension SDKSettingsConfigProvider: @unchecked Sendable {}
