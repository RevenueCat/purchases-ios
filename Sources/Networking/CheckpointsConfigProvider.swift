//
//  CheckpointsConfigProvider.swift
//  RevenueCat
//
//  Created by Facundo Menzella.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol CheckpointsConfigProviderType {

    func getCheckpoint(_ identifier: String) async -> CheckpointRuleSet?

}

/// The topic-specific front door for checkpoints, reading through `RemoteConfigManager`'s `checkpoint_rules` topic.
///
/// Items are keyed by checkpoint name, so a checkpoint resolves with a single `blobData` read: no topic-index
/// scan, and `blobData` already handles inlined versus downloaded blobs and identity invalidation.
final class CheckpointsConfigProvider: CheckpointsConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    /// `nil` covers no item, an unresolvable or undecodable payload and remote config being disabled:
    /// indistinguishable here, and all mean there are no rules to run.
    func getCheckpoint(_ identifier: String) async -> CheckpointRuleSet? {
        do {
            return try await self.manager.blobData(
                for: .checkpointRules,
                itemKey: identifier,
                as: CheckpointRuleSet.self
            )
        } catch {
            Logger.error(Strings.codable.decoding_error(error, CheckpointRuleSet.self))
            return nil
        }
    }

}

extension CheckpointsConfigProvider: @unchecked Sendable {}
