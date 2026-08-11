//
//  CheckpointsConfigProvider.swift
//  RevenueCat
//
//  Created by Facundo Menzella.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol CheckpointsConfigProviderType {

    func rules(for identifier: String) async throws -> CheckpointRulesSnapshot?
    func isCurrent(_ snapshot: CheckpointRulesSnapshot) -> Bool

}

struct CheckpointRulesSnapshot {

    let ruleSet: CheckpointRuleSet
    let configGeneration: Int

}

enum CheckpointRulesProviderError: Error, Equatable {

    case remoteConfigDisabled
    case payloadUnavailable

}

/// The topic-specific front door for checkpoints, reading through `RemoteConfigManager`'s `checkpoint_rules` topic.
///
/// Items are keyed by checkpoint identifier, so rules load with a single `blobData` read: no topic-index
/// scan, and `blobData` already handles inlined versus downloaded blobs and identity invalidation.
final class CheckpointsConfigProvider: CheckpointsConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func rules(for identifier: String) async throws -> CheckpointRulesSnapshot? {
        while true {
            try Task.checkCancellation()
            let configGeneration = self.manager.configGeneration

            do {
                let rules = try await self.loadRules(for: identifier)
                guard self.manager.configGeneration == configGeneration else { continue }

                return rules.map {
                    CheckpointRulesSnapshot(ruleSet: $0, configGeneration: configGeneration)
                }
            } catch {
                guard self.manager.configGeneration == configGeneration else { continue }
                throw error
            }
        }
    }

    func isCurrent(_ snapshot: CheckpointRulesSnapshot) -> Bool {
        return self.manager.configGeneration == snapshot.configGeneration
    }

    private func loadRules(for identifier: String) async throws -> CheckpointRuleSet? {
        do {
            if let checkpoint = try await self.manager.blobData(
                for: .checkpointRules,
                itemKey: identifier,
                as: CheckpointRuleSet.self
            ) {
                return checkpoint
            }
        } catch {
            Logger.error(Strings.codable.decoding_error(error, CheckpointRuleSet.self))
        }

        // The blob read above self-primes remote config on a cold cache. Classifying afterwards prevents an
        // existing checkpoint from briefly looking unconfigured while that initial refresh is still in flight.
        if self.manager.isDisabled {
            throw CheckpointRulesProviderError.remoteConfigDisabled
        }

        let topic = await self.manager.topic(.checkpointRules)
        if self.manager.isDisabled {
            throw CheckpointRulesProviderError.remoteConfigDisabled
        }

        guard topic?[identifier] != nil else { return nil }
        throw CheckpointRulesProviderError.payloadUnavailable
    }

}

extension CheckpointsConfigProvider: @unchecked Sendable {}
