//
//  AudiencesConfigProvider.swift
//  RevenueCat
//
//  Created by Cesar de la Vega.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol AudiencesConfigProviderType {

    func getAudience(_ identifier: String) async -> Audience?

}

/// The topic-specific front door for audiences, reading through `RemoteConfigManager`'s `audiences` topic.
final class AudiencesConfigProvider: AudiencesConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    /// Reads the audience from the topic item itself. The backend publishes audiences as item metadata with no
    /// blob at all, so `ConfigItem.content` (every key apart from the reserved `blob_ref` and `prefetch`) is
    /// the whole audience.
    ///
    /// An audience the SDK can't decode is dropped on its own, so one bad payload can't take out the others.
    func getAudience(_ identifier: String) async -> Audience? {
        guard let content = await self.manager.topic(.audiences)?[identifier]?.content,
              !content.isEmpty else {
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: content.mapValues(\.asAny))

            // Logged as JSON rather than the parsed values, so what the backend sent is legible when a
            // predicate turns out to behave differently than whoever configured the audience expected.
            Logger.debug(Strings.remoteConfig.audienceMetadataBeforeDecoding(
                identifier: identifier,
                metadata: String(bytes: data, encoding: .utf8) ?? "<non-UTF8>"
            ))

            return try JSONDecoder.default.decode(Audience.self, from: data)
        } catch {
            Logger.error(Strings.codable.decoding_error(error, Audience.self))
            return nil
        }
    }

}

extension AudiencesConfigProvider: @unchecked Sendable {}
