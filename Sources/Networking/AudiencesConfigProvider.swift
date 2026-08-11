//
//  AudiencesConfigProvider.swift
//  RevenueCat
//
//  Created by Cesar de la Vega.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol AudiencesConfigProviderType {

    func getAudience(_ identifier: String) async -> [String: AnyDecodable]?

}

/// The topic-specific front door for audiences, reading through `RemoteConfigManager`'s `audiences` topic.
///
/// Audience payloads stay schema-agnostic until the SDK has a consumer that can define their concrete shape.
final class AudiencesConfigProvider: AudiencesConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func getAudience(_ identifier: String) async -> [String: AnyDecodable]? {
        do {
            return try await self.manager.blobData(
                for: .audiences,
                itemKey: identifier,
                as: [String: AnyDecodable].self
            )
        } catch {
            Logger.error(Strings.codable.decoding_error(error, [String: AnyDecodable].self))
            return nil
        }
    }

}

extension AudiencesConfigProvider: @unchecked Sendable {}
