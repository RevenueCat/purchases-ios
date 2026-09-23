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
final class CheckpointsConfigProvider: CheckpointsConfigProviderType, RemoteConfigStateObserver {

    private let manager: RemoteConfigManagerType
    private let cacheLock = Lock()
    private let cachedRules = GenerationGuardedCache<
        RemoteConfiguration.ConfigTopic,
        [String: CheckpointRuleSet]
    >()

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func remoteConfigStateDidChange(generation _: Int) {
        Task { [weak self] in
            await self?.warm()
        }
    }

    func warm() async {
        guard let snapshot = await self.manager.committedTopicCacheSnapshot(.checkpointRules) else { return }

        for (identifier, item) in snapshot.key where item.prefetch {
            guard self.manager.configGeneration == snapshot.generation else { return }
            guard let data = await self.manager.blobData(
                for: .checkpointRules,
                itemKey: identifier,
                policy: .cachedOnly
            ), let ruleSet = try? JSONDecoder.default.decode(CheckpointRuleSet.self, from: data) else { continue }
            guard self.manager.configGeneration == snapshot.generation else { return }
            self.cache(ruleSet, for: identifier, snapshot: snapshot)
        }
    }

    func rules(for identifier: String) async throws -> CheckpointRulesSnapshot? {
        if let cached = self.currentCachedRules(for: identifier) {
            return cached
        }

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
        do {
            if let checkpoint = try await self.manager.blobData(
                for: .checkpointRules,
                itemKey: identifier,
                as: CheckpointRuleSet.self
            ) {
                guard let topic = await self.manager.topic(.checkpointRules), topic[identifier] != nil else {
                    return nil
                }
                let topicSnapshot = GenerationGuardedCacheSnapshot(
                    generation: self.manager.configGeneration,
                    key: topic
                )
                self.cache(checkpoint, for: identifier, snapshot: topicSnapshot)
                return checkpoint
            }
        } catch {
            Logger.error(Strings.codable.decoding_error(error, CheckpointRuleSet.self))
        }

        guard let topic = await self.manager.topic(.checkpointRules) else {
            guard await self.manager.hasCommittedConfig() else {
                throw CheckpointRulesProviderError.payloadUnavailable
            }
            return nil
        }

        guard topic[identifier] != nil else { return nil }
        throw CheckpointRulesProviderError.payloadUnavailable
    }

    private func currentCachedRules(for identifier: String) -> CheckpointRulesSnapshot? {
        let generation = self.manager.configGeneration
        return self.cacheLock.perform {
            guard let ruleSet = self.cachedRules.value(currentGeneration: generation)?[identifier] else { return nil }
            return .init(ruleSet: ruleSet, configGeneration: generation)
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
