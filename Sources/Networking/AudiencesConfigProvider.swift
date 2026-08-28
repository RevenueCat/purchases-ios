//
//  AudiencesConfigProvider.swift
//  RevenueCat
//
//  Created by Cesar de la Vega.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol AudiencesConfigProviderType {

    func configuration() async throws -> AudienceConfigurationSnapshot?
    func isCurrent(_ snapshot: AudienceConfigurationSnapshot) -> Bool

}

/// One immutable view of the audience rules and subscriber-specific protected results served together by
/// the `audiences` topic.
struct AudienceConfigurationSnapshot: Equatable, Sendable {

    let audiences: [String: Audience]
    let backendPredicateResults: [String: Bool]
    let configGeneration: Int

}

enum AudiencesConfigProviderError: Error, Equatable, Sendable {

    case audienceIdentifierMismatch(mapKey: String, identifier: String)
    case malformedBackendPredicateResult(String)

}

/// The topic-specific front door for canonical audience configuration.
///
/// All published audience rules live in the immutable `default` blob. Subscriber-specific protected predicate
/// results remain inline under `backend_predicate_results`. Both values are loaded from one committed topic
/// generation so callers can never evaluate rules with results belonging to a different configuration.
final class AudiencesConfigProvider: AudiencesConfigProviderType {

    private let manager: RemoteConfigManagerType
    private let cachedConfiguration = GenerationGuardedCache<
        RemoteConfiguration.ConfigTopic,
        AudienceConfigurationSnapshot
    >()

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func configuration() async throws -> AudienceConfigurationSnapshot? {
        while true {
            try Task.checkCancellation()

            guard let topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.audiences) else {
                return nil
            }

            let topicSnapshot = GenerationGuardedCacheSnapshot(
                generation: self.manager.configGeneration,
                key: topic
            )
            if let cached = self.cachedConfiguration.value(for: topicSnapshot) {
                guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { continue }
                return cached
            }

            do {
                guard topic[Self.audiencesBlobItemKey]?.blobRef != nil,
                      let blob = await self.manager.blobData(
                        for: .audiences,
                        itemKey: Self.audiencesBlobItemKey
                      ) else {
                    guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { continue }
                    return nil
                }

                let audiences = try Self.decodeAudiences(from: blob)
                let backendPredicateResults = try Self.decodeBackendPredicateResults(from: topic)

                guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { continue }

                let configuration = AudienceConfigurationSnapshot(
                    audiences: audiences,
                    backendPredicateResults: backendPredicateResults,
                    configGeneration: topicSnapshot.generation
                )
                self.cachedConfiguration.store(configuration, for: topicSnapshot)
                return configuration
            } catch {
                guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { continue }
                Logger.error(Strings.remoteConfig.audienceConfigurationDecodeFailed(error))
                throw error
            }
        }
    }

    func isCurrent(_ snapshot: AudienceConfigurationSnapshot) -> Bool {
        return self.manager.configGeneration == snapshot.configGeneration
    }

    private static func decodeAudiences(from data: Data) throws -> [String: Audience] {
        let audiences = try JSONDecoder.default.decode([String: Audience].self, from: data)

        for (mapKey, audience) in audiences where mapKey != audience.id {
            throw AudiencesConfigProviderError.audienceIdentifierMismatch(
                mapKey: mapKey,
                identifier: audience.id
            )
        }

        return audiences
    }

    private static func decodeBackendPredicateResults(
        from topic: RemoteConfiguration.ConfigTopic
    ) throws -> [String: Bool] {
        guard let item = topic[Self.backendPredicateResultsItemKey] else { return [:] }

        return try item.content.reduce(into: [:]) { results, entry in
            let (conditionHash, value) = entry
            guard case let .bool(result) = value else {
                throw AudiencesConfigProviderError.malformedBackendPredicateResult(conditionHash)
            }
            results[conditionHash] = result
        }
    }

    private static let audiencesBlobItemKey = "default"
    private static let backendPredicateResultsItemKey = "backend_predicate_results"

}

extension AudiencesConfigProvider: @unchecked Sendable {}
