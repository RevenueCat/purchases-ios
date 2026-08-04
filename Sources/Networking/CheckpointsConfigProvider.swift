//
//  CheckpointsConfigProvider.swift
//  RevenueCat
//
//  Created by Facundo Menzella.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol CheckpointsConfigProviderType: AnyObject {

    /// The rules configured for `identifier`, or `nil` when there are none the SDK can read.
    func getCheckpoint(_ identifier: String) async -> CheckpointRuleSet?

}

/// The topic-specific front door for checkpoints, reading through `RemoteConfigManager`'s `checkpoints` topic.
/// It knows only the topic name and how to parse a ``CheckpointRuleSet``; everything else is delegated to
/// `RemoteConfigManager`.
///
/// Items are keyed by checkpoint name, so a checkpoint resolves with a single `blobData` read: it needs no
/// topic-index scan, and `blobData` already resolves a blob whether its bytes arrived inlined with the config
/// response or have to be downloaded, and already invalidates on an identity change.
final class CheckpointsConfigProvider: CheckpointsConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    /// Returns `nil` when the checkpoint has no item in the topic, its payload can't be resolved, or remote
    /// config is disabled. Those are indistinguishable here, and all mean the same thing to a caller: there
    /// are no rules to run.
    func getCheckpoint(_ identifier: String) async -> CheckpointRuleSet? {
        guard let data = await self.manager.blobData(for: .checkpoints, itemKey: identifier) else {
            return nil
        }

        return CheckpointRuleSet.parse(identifier: identifier, blob: data)
    }

}

extension CheckpointsConfigProvider: @unchecked Sendable {}
