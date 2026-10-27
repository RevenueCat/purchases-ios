//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowRuleBundle.swift
//
//  Created by Codex on 3/31/26.

import Foundation

/// A versioned bundle of workflow targeting rules delivered to the SDK.
@_spi(Internal) public struct WorkflowRuleBundle: Codable, Equatable, Sendable {

    /// Version of the artifact schema.
    @_spi(Internal) public let artifactVersion: Int
    /// Stable identifier for the bundle payload.
    @_spi(Internal) public let bundleKey: String
    /// RFC3339 timestamp indicating when the bundle was generated.
    @_spi(Internal) public let generatedAt: String
    /// Rule artifacts available in this bundle.
    @_spi(Internal) public let rules: [WorkflowRule]

    /// Creates a workflow rule bundle.
    @_spi(Internal) public init(
        artifactVersion: Int,
        bundleKey: String,
        generatedAt: String,
        rules: [WorkflowRule]
    ) {
        self.artifactVersion = artifactVersion
        self.bundleKey = bundleKey
        self.generatedAt = generatedAt
        self.rules = rules
    }

    private enum CodingKeys: String, CodingKey {
        case artifactVersion = "artifact_version"
        case bundleKey = "bundle_key"
        case generatedAt = "generated_at"
        case rules
    }

}

/// A single workflow rule artifact containing trigger, predicate, and action data.
@_spi(Internal) public struct WorkflowRule: Codable, Equatable, Sendable {

    /// Action to perform when the rule matches.
    @_spi(Internal) public let action: WorkflowRuleAction
    /// Version of the artifact schema for this rule.
    @_spi(Internal) public let artifactVersion: Int
    /// Rule kind, such as targeting or branching.
    @_spi(Internal) public let kind: String
    /// Canonical JsonLogic predicate represented as a JSON-compatible value.
    @_spi(Internal) public let predicate: WorkflowRuleValue
    /// Evaluation context fields needed by this rule.
    @_spi(Internal) public let requiredFields: [String]
    /// Stable identifier for the rule.
    @_spi(Internal) public let ruleID: String
    /// Version of the rule contents.
    @_spi(Internal) public let ruleVersion: Int
    /// Runtime support flags for this rule.
    @_spi(Internal) public let supportedRuntimes: WorkflowSupportedRuntimes
    /// Trigger metadata associated with this rule.
    @_spi(Internal) public let trigger: WorkflowRuleTrigger

    private enum CodingKeys: String, CodingKey {
        case action
        case artifactVersion = "artifact_version"
        case kind
        case predicate
        case requiredFields = "required_fields"
        case ruleID = "rule_id"
        case ruleVersion = "rule_version"
        case supportedRuntimes = "supported_runtimes"
        case trigger
    }

}

/// The action to take when a workflow rule matches.
@_spi(Internal) public struct WorkflowRuleAction: Codable, Equatable, Sendable {

    /// Action type.
    @_spi(Internal) public let type: String
    /// Target workflow public identifier.
    @_spi(Internal) public let workflowID: String
    /// Human-readable workflow name.
    @_spi(Internal) public let workflowName: String

    private enum CodingKeys: String, CodingKey {
        case type
        case workflowID = "workflow_id"
        case workflowName = "workflow_name"
    }

}

/// Runtime support flags for a workflow rule.
@_spi(Internal) public struct WorkflowSupportedRuntimes: Codable, Equatable, Sendable {

    /// Whether ClickHouse can evaluate the rule.
    @_spi(Internal) public let clickhouse: Bool
    /// Whether the SDK can evaluate the rule.
    @_spi(Internal) public let sdk: Bool
    /// Whether the backend server evaluator can evaluate the rule.
    @_spi(Internal) public let server: Bool

}

/// Trigger metadata associated with a workflow rule.
@_spi(Internal) public struct WorkflowRuleTrigger: Codable, Equatable, Sendable {

    /// Trigger-supplied fields referenced by the rule.
    @_spi(Internal) public let fields: [String]
    /// Trigger type name.
    @_spi(Internal) public let type: String

}

/// A JSON-compatible value used to represent workflow predicates and evaluation context.
@_spi(Internal) public enum WorkflowRuleValue: Codable, Equatable, Sendable {

    /// A string value.
    case string(String)
    /// An integer value.
    case int(Int)
    /// A floating-point value.
    case double(Double)
    /// A boolean value.
    case bool(Bool)
    /// An object value keyed by strings.
    case object([String: WorkflowRuleValue])
    /// An array value.
    case array([WorkflowRuleValue])
    /// A null value.
    case null

    /// Resolves a dotted path inside an object-backed rule value.
    @_spi(Internal) public subscript(path path: String) -> WorkflowRuleValue? {
        return self[pathSegments: path.split(separator: ".").map(String.init)]
    }

    private subscript(pathSegments pathSegments: [String]) -> WorkflowRuleValue? {
        guard let segment = pathSegments.first else { return self }

        switch self {
        case let .object(value):
            guard let next = value[segment] else { return nil }
            return next[pathSegments: Array(pathSegments.dropFirst())]
        default:
            return nil
        }
    }

    /// Decodes a JSON-compatible workflow rule value.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: WorkflowRuleValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([WorkflowRuleValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                WorkflowRuleValue.self,
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "Unexpected rule value at \(container.codingPath)"
                )
            )
        }
    }

    /// Encodes a JSON-compatible workflow rule value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

}
