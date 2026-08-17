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
    func getAudience(_ identifier: String) async -> Audience? {
        do {
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

}

extension AudiencesConfigProvider: @unchecked Sendable {}
