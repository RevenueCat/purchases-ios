//
//  SDKSettingsConfigProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

protocol SDKSettingsConfigProviderType: AnyObject, RemoteConfigLifecycleObserver {

    func settings() async -> SDKSettings
    func cachedSettings() -> SDKSettings?
    var delegate: SDKSettingsConfigProviderDelegate? { get set }

}

protocol SDKSettingsConfigProviderDelegate: AnyObject {

    func sdkSettingsConfigProviderDidUpdate(_ settings: SDKSettings)

}

/// Loads SDK settings from the `sdk_settings` topic's inline `default` item.
///
/// A remote-config commit loads and delivers the new settings. The session's first app-start refresh is also
/// resolved, including when that refresh does not commit a new config.
final class SDKSettingsConfigProvider: SDKSettingsConfigProviderType, RemoteConfigLifecycleObserver {

    private let manager: RemoteConfigManagerType
    private let cache = GenerationGuardedCache<String, SDKSettings>()
    private let lastDeliveredSettings: Atomic<DeliveredSettings?> = nil
    private let delegateStorage = Atomic(DelegateStorage())

    var delegate: SDKSettingsConfigProviderDelegate? {
        get { self.delegateStorage.withValue(\.value) }
        set { self.delegateStorage.modify { $0.value = newValue } }
    }

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

    /// Waits for a refresh already in flight, then caches and delivers the latest committed settings.
    func loadAndDeliverSettings() async {
        let generation = self.manager.configGeneration
        let topic = await self.manager.committedTopicAfterInFlightRefresh(.sdkSettings)
        guard await self.manager.hasCommittedConfig() else { return }
        self.cacheAndDeliverSettings(from: topic, generation: generation)
    }

    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {
        switch event {
        case .initialState:
            break
        case .committed:
            Task { [weak self] in
                await self?.loadAndDeliverSettings()
            }
        case .refreshFinished(fetchContext: .appStart, generation: _):
            Task { [weak self] in
                await self?.loadAndDeliverSettings()
            }
        case .refreshFinished:
            break
        }
    }

    private func cacheAndDeliverSettings(
        from topic: RemoteConfiguration.ConfigTopic?,
        generation: Int
    ) {
        let settings = self.decodeSettingsOrFallback(from: topic?[Self.defaultItemKey])
        guard self.manager.configGeneration == generation else { return }

        self.cache.store(settings, for: .init(generation: generation, key: Self.cacheKey))
        self.notifyDelegate(settings, generation: generation)
    }

    private func decodeSettingsOrFallback(from item: RemoteConfiguration.ConfigItem?) -> SDKSettings {
        do {
            return try item.map(Self.decodeSettings) ?? Self.fallbackSettings
        } catch {
            Logger.error(Strings.codable.decoding_error(error, SDKSettings.self))
            return Self.fallbackSettings
        }
    }

    private func notifyDelegate(_ settings: SDKSettings, generation: Int) {
        guard let delegate = self.delegate else { return }

        let didChange = self.lastDeliveredSettings.modify { previous in
            guard (previous?.generation ?? Int.min) <= generation else { return false }
            let didChange = previous?.settings != settings
            previous = .init(generation: generation, settings: settings)
            return didChange
        }
        guard didChange else { return }

        delegate.sdkSettingsConfigProviderDidUpdate(settings)
    }

    private static func decodeSettings(from item: RemoteConfiguration.ConfigItem) throws -> SDKSettings {
        let data = try JSONEncoder.default.encode(item.content)
        return try JSONDecoder.default.decode(SDKSettings.self, from: data)
    }

    private static let defaultItemKey = "default"
    private static let cacheKey = "sdk_settings"
    private static let fallbackSettings = SDKSettings()

    private struct DeliveredSettings {

        let generation: Int
        let settings: SDKSettings

    }

    private final class DelegateStorage {

        weak var value: SDKSettingsConfigProviderDelegate?

    }

}

extension SDKSettingsConfigProvider: @unchecked Sendable {}
