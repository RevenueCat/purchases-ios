//
//  SubscriberDimensionsConfigProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol SubscriberDimensionsConfigProviderType: AnyObject, RemoteConfigLifecycleObserver, Sendable {

    func dimensions() async throws -> SubscriberDimensionsResolution
    func cachedDimensions() -> SubscriberDimensionsResolution?

}

/// Reads the inline `default` item from the optional `subscriber_dimensions` topic.
final class SubscriberDimensionsConfigProvider: SubscriberDimensionsConfigProviderType {

    private let manager: RemoteConfigManagerType
    private let cache = GenerationGuardedCache<String, SubscriberDimensionsResolution>()

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func dimensions() async throws -> SubscriberDimensionsResolution {
        if let cached = self.cachedDimensions() {
            return cached
        }

        return try await self.manager.readConsistent {
            let topic = await self.manager.topic(.subscriberDimensions)
            guard await self.manager.hasCommittedConfig() else {
                return .unavailable
            }
            return Self.resolve(topic)
        } ?? .unavailable
    }

    func cachedDimensions() -> SubscriberDimensionsResolution? {
        return self.manager.withCurrentConfigGeneration { generation in
            self.cache.value(currentGeneration: generation)
        }
    }

    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {
        switch event {
        case .observerRegistered, .committed:
            Task { [weak self] in
                await self?.warm()
            }
        case .refreshFinished:
            break
        }
    }

    func warm() async {
        let generation = self.manager.configGeneration
        guard await self.manager.hasCommittedConfig() else { return }

        let topic = await self.manager.topic(.subscriberDimensions, policy: .cachedOnly)
        guard self.manager.configGeneration == generation else { return }

        self.cache.store(
            Self.resolve(topic),
            for: .init(generation: generation, key: Self.cacheKey)
        )
    }

    private static func resolve(
        _ topic: RemoteConfiguration.ConfigTopic?
    ) -> SubscriberDimensionsResolution {
        guard let topic else {
            return .notConfigured
        }
        guard let item = topic[Self.defaultItemKey] else { return .unavailable }

        do {
            let data = try JSONEncoder.default.encode(item.content)
            let dimensions = try JSONDecoder.default.decode(SubscriberDimensions.self, from: data)
            return .resolved(dimensions)
        } catch {
            Logger.warn(Strings.localRules.subscriberDimensionsUnavailable(error))
            return .unavailable
        }
    }

    private static let defaultItemKey = "default"
    private static let cacheKey = "subscriber_dimensions"

}

extension SubscriberDimensionsConfigProvider: @unchecked Sendable {}
