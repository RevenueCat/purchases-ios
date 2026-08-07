//
//  CheckpointRules.swift
//  RevenueCat
//
//  Created by Facundo Menzella.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// One checkpoint's rules, which decide whether it resolves to a workflow. Parsed only, not evaluated.
struct CheckpointRuleSet: Equatable, Sendable {

    /// The checkpoint's backend id, as opposed to its name, which is the topic item key.
    let id: String?
    /// Served in priority order, first match wins. Never re-sorted here.
    let rules: [CheckpointRule]

    init(id: String? = nil, rules: [CheckpointRule]) {
        self.id = id
        self.rules = rules
    }

}

struct CheckpointRule: Equatable, Sendable {

    let id: String?
    /// Reference to the targeted audience, whose predicate arrives in a separate topic. Required, so a rule
    /// can never end up targeting everyone by omission.
    let audienceId: String
    let workflowId: String

    init(id: String? = nil, audienceId: String, workflowId: String) {
        self.id = id
        self.audienceId = audienceId
        self.workflowId = workflowId
    }

}

// MARK: - Decodable

extension CheckpointRuleSet: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case rules
    }

    /// A rule the SDK can't make sense of is skipped rather than failing the checkpoint, so one bad rule
    /// can't take out the rest.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.rules = (try container.decodeIfPresent([SkippableRule].self, forKey: .rules) ?? [])
            .compactMap(\.rule)
    }

}

extension CheckpointRule: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case audienceId = "audience"
        case workflowId
    }

}

/// Turns a rule that fails to decode into `nil` instead of failing its enclosing array.
private struct SkippableRule: Decodable {

    let rule: CheckpointRule?

    init(from decoder: Decoder) throws {
        do {
            self.rule = try CheckpointRule(from: decoder)
        } catch {
            Logger.warn(Strings.remoteConfig.checkpointRuleSkipped(reason: "\(error)"))
            self.rule = nil
        }
    }

}
