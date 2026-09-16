//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowTriggerAction.swift
//
//  Created by RevenueCat.
// swiftlint:disable missing_docs

import Foundation

/// What a step's exit does when it is taken.
@_spi(Internal) public enum WorkflowTriggerAction: Equatable, Sendable {
    case step(stepId: String)
    /// An audience decides between two steps.
    case branch(WorkflowBranch)
    case unknown
}

// MARK: - Codable

extension WorkflowTriggerAction: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case stepId
        case branches
        case fallbackStepId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "step":
            let stepId = try container.decode(String.self, forKey: .stepId)
            self = .step(stepId: stepId)
        case "branch":
            // Never throws: a throw here would fail the whole workflow, not just this action.
            guard let branches = try? container.decode([WorkflowBranch.Route].self, forKey: .branches),
                  let fallbackStepId = try? container.decode(String.self, forKey: .fallbackStepId) else {
                Logger.warn(Strings.backendError.unknown_workflow_trigger_action_type(type: type))
                self = .unknown
                return
            }
            self = .branch(.init(branches: branches, fallbackStepId: fallbackStepId))
        default:
            Logger.warn(Strings.backendError.unknown_workflow_trigger_action_type(type: type))
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .step(let stepId):
            try container.encode("step", forKey: .type)
            try container.encode(stepId, forKey: .stepId)
        case .branch(let branch):
            try container.encode("branch", forKey: .type)
            try container.encode(branch.branches, forKey: .branches)
            try container.encode(branch.fallbackStepId, forKey: .fallbackStepId)
        case .unknown:
            try container.encode("unknown", forKey: .type)
        }
    }

}
