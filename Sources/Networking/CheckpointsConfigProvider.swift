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

    case payloadUnavailable
    case stale

}

/// The topic-specific front door for checkpoints, reading through `RemoteConfigManager`'s `checkpoint_rules` topic.
///
/// Items are keyed by checkpoint identifier. Decoded rule sets are retained for their exact committed topic
/// snapshot, so repeated hits avoid reading and decoding the same blob while config is unchanged.
final class CheckpointsConfigProvider: CheckpointsConfigProviderType {

    private let manager: RemoteConfigManagerType
    private let cacheLock = Lock()
    private let cachedRules = GenerationGuardedCache<
        RemoteConfiguration.ConfigTopic,
        [String: CheckpointRuleSet]
    >()

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func rules(for identifier: String) async throws -> CheckpointRulesSnapshot? {
        do {
            return try await self.manager.readConsistent {
                let generation = self.manager.configGeneration
                let rules = try await self.loadRules(for: identifier)
                return rules.map {
                    CheckpointRulesSnapshot(ruleSet: $0, configGeneration: generation)
                }
            }
        } catch RemoteConfigConsistencyError.stale {
            throw CheckpointRulesProviderError.stale
        }
    }

    func isCurrent(_ snapshot: CheckpointRulesSnapshot) -> Bool {
        return self.manager.configGeneration == snapshot.configGeneration
    }

    private func loadRules(for identifier: String) async throws -> CheckpointRuleSet? {
        guard let topic = await self.manager.topic(.checkpointRules) else {
            guard await self.manager.hasCommittedConfig() else {
                throw CheckpointRulesProviderError.payloadUnavailable
            }
            return nil
        }

        guard topic[identifier] != nil else { return nil }
        let topicSnapshot = GenerationGuardedCacheSnapshot(
            generation: self.manager.configGeneration,
            key: topic
        )

        if let cached = self.cachedRule(for: identifier, snapshot: topicSnapshot) {
            return cached
        }

        do {
            if let checkpoint = try await self.manager.blobData(
                for: .checkpointRules,
                itemKey: identifier,
                as: CheckpointRuleSet.self
            ) {
                self.cache(checkpoint, for: identifier, snapshot: topicSnapshot)
                return checkpoint
            }
        } catch {
            Logger.error(Strings.codable.decoding_error(error, CheckpointRuleSet.self))
        }

        throw CheckpointRulesProviderError.payloadUnavailable
    }

    private func cachedRule(
        for identifier: String,
        snapshot: GenerationGuardedCacheSnapshot<RemoteConfiguration.ConfigTopic>
    ) -> CheckpointRuleSet? {
        return self.cacheLock.perform {
            return self.cachedRules.value(for: snapshot)?[identifier]
        }
    }

    private func cache(
        _ ruleSet: CheckpointRuleSet,
        for identifier: String,
        snapshot: GenerationGuardedCacheSnapshot<RemoteConfiguration.ConfigTopic>
    ) {
        self.cacheLock.perform {
            var rules = self.cachedRules.value(for: snapshot) ?? [:]
            rules[identifier] = ruleSet
            self.cachedRules.store(rules, for: snapshot)
        }
    }

}

extension CheckpointsConfigProvider: @unchecked Sendable {}
