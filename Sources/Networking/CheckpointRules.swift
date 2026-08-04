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
    /// The checkpoint's backend id, absent when the backend doesn't send one.
    let id: String?
    /// Served in priority order: evaluated top to bottom, first match wins. Not re-sorted here, since the
    /// wire order *is* the order.
    let rules: [CheckpointRule]

    init(identifier: String, id: String? = nil, rules: [CheckpointRule]) {
        self.identifier = identifier
        self.id = id
        self.rules = rules
    }

}

/// One rule at a checkpoint: who it applies to, and the workflow it resolves to.
struct CheckpointRule: Equatable, Sendable {

    let id: String?
    /// The audience this rule targets, as a reference. The audience's own predicate is expected to arrive in
    /// a separate topic, so nothing here evaluates it. `nil` targets every user.
    let audienceId: String?
    let workflowId: String
    let frequencyCap: CheckpointFrequencyCap?
    /// When the rule is live. Rules are published on creation, ahead of their start date, so a scheduled
    /// window has to be resolved on device.
    let schedule: CheckpointRuleSchedule?

    init(
        id: String? = nil,
        audienceId: String? = nil,
        workflowId: String,
        frequencyCap: CheckpointFrequencyCap? = nil,
        schedule: CheckpointRuleSchedule? = nil
    ) {
        self.id = id
        self.audienceId = audienceId
        self.workflowId = workflowId
        self.frequencyCap = frequencyCap
        self.schedule = schedule
    }

}

/// How often a rule may fire. `type` stays the raw wire value: frequency capping is out of V1 scope and its
/// vocabulary isn't settled, so this carries what was sent instead of interpreting it.
struct CheckpointFrequencyCap: Equatable, Sendable {

    let type: String
    let count: Int?
    let window: String?

    init(type: String, count: Int? = nil, window: String? = nil) {
        self.type = type
        self.count = count
        self.window = window
    }

}

/// A rule's scheduled window. Either bound can be absent, meaning open-ended on that side.
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

    /// Parses a checkpoint's blob payload. Returns `nil` when the bytes aren't a JSON object.
    static func parse(identifier: String, blob data: Data) -> CheckpointRuleSet? {
        guard let fields = Self.fields(fromBlob: data) else { return nil }
        return Self.parse(identifier: identifier, fields: fields)
    }

    /// Parses one checkpoint's id and rules from its decoded payload. A malformed rule is skipped rather than
    /// failing the checkpoint, and unknown fields are ignored so the backend can extend the schema without a
    /// client release.
    ///
    /// Keys are read at their wire spelling (`workflow_id`, `frequency_cap`): the payload is decoded as a
    /// dictionary, and `.convertFromSnakeCase` only renames keys read through a keyed container. That holds at
    /// every depth here, unlike an item's `content`, whose own keys `ConfigItem.init(from:)` does camelCase.
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

        var id: String?
        if case let .string(value)? = fields[Self.idKey] {
            id = value
        }
        var audienceId: String?
        if case let .string(value)? = fields[Self.audienceKey] {
            audienceId = value
        }

        return CheckpointRule(
            id: id,
            audienceId: audienceId,
            workflowId: workflowId,
            frequencyCap: Self.parseFrequencyCap(fields[Self.frequencyCapKey]),
            schedule: Self.parseSchedule(fields[Self.scheduleKey])
        )
    }

    private static func parseFrequencyCap(_ field: AnyDecodable?) -> CheckpointFrequencyCap? {
        guard case let .object(fields)? = field,
              case let .string(type)? = fields[Self.typeKey] else {
            return nil
        }

        var count: Int?
        if case let .int(value)? = fields[Self.countKey] {
            count = value
        }
        var window: String?
        if case let .string(value)? = fields[Self.windowKey] {
            window = value
        }

        return CheckpointFrequencyCap(type: type, count: count, window: window)
    }

    /// A schedule with neither bound parseable is dropped, so an unparseable window can't be mistaken for
    /// an open-ended one.
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
    private static let frequencyCapKey = "frequency_cap"
    private static let typeKey = "type"
    private static let countKey = "count"
    private static let windowKey = "window"
    private static let scheduleKey = "schedule"
    private static let startKey = "start"
    private static let endKey = "end"

}
