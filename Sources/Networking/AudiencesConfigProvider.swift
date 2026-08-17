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

    /// An audience the SDK can't decode is dropped on its own, so one bad payload can't take out the others.
    ///
    /// Audiences are served inline in the topic item rather than as a blob, so the item's own content is the
    /// primary source. The blob read stays as a fallback for any project still served the earlier shape.
    func getAudience(_ identifier: String) async -> Audience? {
        do {
            if let inline = try await self.inlineAudience(identifier) {
                return inline
            }

            return try await self.manager.blobData(
                for: .audiences,
                itemKey: identifier,
                as: Audience.self
            )
        } catch {
            Logger.error(Strings.codable.decoding_error(error, Audience.self))
            return nil
        }
    }

    /// Decodes the audience from the topic item itself. `ConfigItem.content` holds every key the item carried
    /// apart from the reserved `blob_ref` and `prefetch`, which for this topic is the whole audience.
    private func inlineAudience(_ identifier: String) async throws -> Audience? {
        guard let content = await self.manager.topic(.audiences)?[identifier]?.content,
              !content.isEmpty else {
            return nil
        }

        let data = try JSONSerialization.data(withJSONObject: content.mapValues(\.asAny))
        return try JSONDecoder.default.decode(Audience.self, from: data)
    }

}

extension AudiencesConfigProvider: @unchecked Sendable {}
