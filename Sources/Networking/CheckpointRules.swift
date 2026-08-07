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
    let audienceId: Int
    let workflowId: String
    /// Rules are published ahead of their start date, so this window is resolved on device.
    let schedule: CheckpointRuleSchedule?

    init(
        id: String? = nil,
        audienceId: Int,
        workflowId: String,
        schedule: CheckpointRuleSchedule? = nil
    ) {
        self.id = id
        self.audienceId = audienceId
        self.workflowId = workflowId
        self.schedule = schedule
    }

}

/// Either bound absent means open-ended on that side. A bound that's present but unparseable fails the whole
/// rule rather than reading as open-ended, which would run it outside its dates.
struct CheckpointRuleSchedule: Equatable, Sendable {

    let start: Date?
    let end: Date?

    init(start: Date? = nil, end: Date? = nil) {
        self.start = start
        self.end = end
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
        case schedule
    }

}

extension CheckpointRuleSchedule: Decodable {}

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
