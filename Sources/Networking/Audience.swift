//
//  Audience.swift
//  RevenueCat
//
//  Created by Facundo Menzella.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// One audience, whose predicate decides which checkpoint rule a customer falls into. Parsed only, not evaluated.
struct Audience: Equatable, Sendable {

    let id: String
    /// The JSON Logic predicate, kept as a JSON string because that is what `RulesEngine.evaluate` takes.
    /// Modeling the expression here would only mean serializing it back before every evaluation.
    let rules: String

    init(id: String, rules: String) {
        self.id = id
        self.rules = rules
    }

}

// MARK: - Decodable

extension Audience: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case rules
    }

    /// A predicate always arrives as a JSON object, so decoding `rules` as one rejects anything the engine
    /// couldn't evaluate anyway, and does it at ingest rather than at evaluation time.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)

        let rules = try container.decode([String: AnyDecodable].self, forKey: .rules)
        // An empty predicate doesn't mean the same thing as the one that was served, so a failure here has to
        // fail the audience rather than fall back to one.
        guard let data = try? JSONSerialization.data(
            withJSONObject: rules.mapValues(\.asAny),
            // Sorted because Swift dictionaries have no order of their own, and an unstable predicate string
            // would be a moving target for anything that caches or compares it.
            options: [.sortedKeys]
        ), let serialized = String(bytes: data, encoding: .utf8) else {
            throw DecodingError.dataCorruptedError(
                forKey: .rules,
                in: container,
                debugDescription: "'rules' could not be re-serialized for the rules engine"
            )
        }

        self.rules = serialized
    }

}
