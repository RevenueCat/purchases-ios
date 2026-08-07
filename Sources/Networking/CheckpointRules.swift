//
//  CheckpointRules.swift
//  RevenueCat
//
//  Created by Facundo Menzella.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// One checkpoint's rules, which decide whether it resolves to a workflow. Parsed only, not evaluated.
struct CheckpointRuleSet: Equatable, Sendable {

    /// The checkpoint name, which is also the topic item key.
    let identifier: String
    /// The checkpoint's backend id, as opposed to its name.
    let id: String?
    /// Served in priority order, first match wins. Never re-sorted here.
    let rules: [CheckpointRule]

    init(identifier: String, id: String? = nil, rules: [CheckpointRule]) {
        self.identifier = identifier
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

/// Either bound absent means open-ended on that side.
struct CheckpointRuleSchedule: Equatable, Sendable {

    let start: Date?
    let end: Date?

    init(start: Date? = nil, end: Date? = nil) {
        self.start = start
        self.end = end
    }

}

// MARK: - Parsing

extension CheckpointRuleSet {

    /// `nil` when the bytes aren't a JSON object.
    static func parse(identifier: String, blob data: Data) -> CheckpointRuleSet? {
        guard let fields = Self.fields(fromBlob: data) else { return nil }
        return Self.parse(identifier: identifier, fields: fields)
    }

    /// A malformed rule is skipped rather than failing the checkpoint, and unknown fields are ignored so the
    /// backend can extend the schema without a client release.
    static func parse(identifier: String, fields: [String: AnyDecodable]) -> CheckpointRuleSet {
        var id: String?
        if case let .string(value)? = fields[Self.idKey] {
            id = value
        }

        return CheckpointRuleSet(
            identifier: identifier,
            id: id,
            rules: Self.parseRules(from: fields, checkpoint: identifier)
        )
    }

    private static func parseRules(
        from fields: [String: AnyDecodable],
        checkpoint: String
    ) -> [CheckpointRule] {
        guard let rules = fields[Self.rulesKey] else { return [] }
        guard case let .array(entries) = rules else {
            Logger.warn(Strings.remoteConfig.checkpointRuleSkipped(
                checkpoint: checkpoint,
                reason: "expected '\(Self.rulesKey)' to be an array"
            ))
            return []
        }

        return entries.compactMap { Self.parseRule($0, checkpoint: checkpoint) }
    }

    private static func parseRule(_ entry: AnyDecodable, checkpoint: String) -> CheckpointRule? {
        guard case let .object(fields) = entry else {
            Logger.warn(Strings.remoteConfig.checkpointRuleSkipped(
                checkpoint: checkpoint,
                reason: "expected each rule to be an object"
            ))
            return nil
        }
        guard case let .string(workflowId)? = fields[Self.workflowIdKey], !workflowId.isEmpty else {
            Logger.warn(Strings.remoteConfig.checkpointRuleSkipped(
                checkpoint: checkpoint,
                reason: "missing '\(Self.workflowIdKey)'"
            ))
            return nil
        }

        guard case let .int(audienceId)? = fields[Self.audienceKey] else {
            Logger.warn(Strings.remoteConfig.checkpointRuleSkipped(
                checkpoint: checkpoint,
                reason: "missing '\(Self.audienceKey)'"
            ))
            return nil
        }

        var id: String?
        if case let .string(value)? = fields[Self.idKey] {
            id = value
        }

        return CheckpointRule(
            id: id,
            audienceId: audienceId,
            workflowId: workflowId,
            schedule: Self.parseSchedule(fields[Self.scheduleKey])
        )
    }

    /// Dropped rather than kept as open-ended, which would run the rule outside its dates.
    private static func parseSchedule(_ field: AnyDecodable?) -> CheckpointRuleSchedule? {
        guard case let .object(fields)? = field else { return nil }

        let start = Self.parseDate(fields[Self.startKey])
        let end = Self.parseDate(fields[Self.endKey])
        guard start != nil || end != nil else { return nil }

        return CheckpointRuleSchedule(start: start, end: end)
    }

    private static func parseDate(_ field: AnyDecodable?) -> Date? {
        guard case let .string(value)? = field else { return nil }
        return ISO8601DateFormatter.default.date(from: value)
    }

    private static func fields(fromBlob data: Data) -> [String: AnyDecodable]? {
        do {
            return try JSONDecoder.default.decode([String: AnyDecodable].self, from: data)
        } catch {
            Logger.error(Strings.codable.decoding_error(error, [String: AnyDecodable].self))
            return nil
        }
    }

    private static let idKey = "id"
    private static let rulesKey = "rules"
    private static let audienceKey = "audience"
    private static let workflowIdKey = "workflow_id"
    private static let scheduleKey = "schedule"
    private static let startKey = "start"
    private static let endKey = "end"

}
