//
//  TransformationsConfigProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

struct Transformation: Equatable, Sendable {

    let identifier: String
    /// The JSON Logic rule, kept as a JSON string because that is what `RulesEngine.transform` takes.
    let rule: String

}

protocol TransformationsConfigProviderType {

    func getTransformation(_ identifier: String) async -> Transformation?

}

/// The topic-specific front door for transformations, reading through `RemoteConfigManager`'s
/// `transformations` topic.
final class TransformationsConfigProvider: TransformationsConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    /// Reads a transformation from inline topic metadata. A malformed transformation is dropped independently,
    /// so it does not prevent other transformations from being read.
    func getTransformation(_ identifier: String) async -> Transformation? {
        guard let content = await self.manager.topic(.transformations)?[identifier]?.content,
              !content.isEmpty else {
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: content.mapValues(\.asAny))
            let payload = try JSONDecoder.default.decode(TransformationPayload.self, from: data)

            return Transformation(identifier: identifier, rule: payload.rule)
        } catch {
            Logger.error(Strings.codable.decoding_error(error, Transformation.self))
            return nil
        }
    }

}

extension TransformationsConfigProvider: @unchecked Sendable {}

private struct TransformationPayload: Decodable {

    let rule: String

    private enum CodingKeys: String, CodingKey {
        case rule
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rule = try container.decode([String: AnyDecodable].self, forKey: .rule)

        guard let data = try? JSONSerialization.data(
            withJSONObject: rule.mapValues(\.asAny),
            options: [.sortedKeys]
        ), let serialized = String(bytes: data, encoding: .utf8) else {
            throw DecodingError.dataCorruptedError(
                forKey: .rule,
                in: container,
                debugDescription: "'rule' could not be re-serialized for the rules engine"
            )
        }

        self.rule = serialized
    }

}
