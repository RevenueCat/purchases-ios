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

/// One immutable view of the audience rules and subscriber-specific protected values served together by
/// the `audiences` topic.
struct AudienceConfigurationSnapshot: Equatable, Sendable {

    let audiences: [String: Audience]

    /// Opaque values keyed by the hashes used as placeholders in the canonical audience rules.
    let backendPredicateResults: [String: DimensionValue]
    let configGeneration: Int

}

/// The topic-specific front door for canonical audience configuration.
///
/// All published audience rules live in the immutable `default` blob. Subscriber-specific protected values
/// remain inline under `backend_predicate_results`. Both values are loaded from one committed topic
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
        return try await self.manager.readConsistent {
            try await self.loadConfiguration()
        }
    }

    private func loadConfiguration() async throws -> AudienceConfigurationSnapshot? {
        try Task.checkCancellation()
        guard let topicSnapshot = await self.manager.awaitTopicAndPrefetchBlobsReady(.audiences) else {
            return nil
        }
        guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { return nil }
        if let cached = self.cachedConfiguration.value(for: topicSnapshot) { return cached }

        do {
            guard topicSnapshot.key[Self.audiencesBlobItemKey] != nil,
                  let blob = await self.manager.blobData(
                    for: .audiences,
                    itemKey: Self.audiencesBlobItemKey
                  ) else {
                return nil
            }
            let configuration = AudienceConfigurationSnapshot(
                audiences: try Self.decodeAudiences(from: blob),
                backendPredicateResults: Self.decodeBackendPredicateResults(from: topicSnapshot.key),
                configGeneration: topicSnapshot.generation
            )
            guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { return nil }
            self.cachedConfiguration.store(configuration, for: topicSnapshot)
            return configuration
        } catch {
            guard await self.manager.isCurrent(topicSnapshot, for: .audiences) else { return nil }
            Logger.error(Strings.remoteConfig.audienceConfigurationDecodeFailed(error))
            throw error
        }
    }

    func isCurrent(_ snapshot: AudienceConfigurationSnapshot) -> Bool {
        return self.manager.configGeneration == snapshot.configGeneration
    }

    private static func decodeAudiences(from data: Data) throws -> [String: Audience] {
        let entries = try JSONDecoder.default.decode([String: FailableAudience].self, from: data)

        return entries.reduce(into: [:]) { audiences, entry in
            let (mapKey, decoded) = entry
            switch decoded.result {
            case .success(let audience):
                audiences[mapKey] = audience
            case .failure(let error):
                Logger.error(Strings.remoteConfig.audienceDecodeFailed(identifier: mapKey, error: error))
            }
        }
    }

    private static func decodeBackendPredicateResults(
        from topic: RemoteConfiguration.ConfigTopic
    ) -> [String: DimensionValue] {
        guard let item = topic[Self.backendPredicateResultsItemKey] else { return [:] }

        return item.content.reduce(into: [:]) { results, entry in
            let (conditionHash, value) = entry
            guard let dimensionValue = value.dimensionValue else {
                Logger.warn(Strings.remoteConfig.backendPredicateResultUnsupported(conditionHash))
                return
            }
            results[conditionHash] = dimensionValue
        }
    }

    private static let audiencesBlobItemKey = "default"
    private static let backendPredicateResultsItemKey = "backend_predicate_results"

}

extension AudiencesConfigProvider: @unchecked Sendable {}

private struct FailableAudience: Decodable {

    let result: Result<Audience, Error>

    init(from decoder: Decoder) throws {
        do {
            self.result = .success(try Audience(from: decoder))
        } catch {
            self.result = .failure(error)
        }
    }

}
