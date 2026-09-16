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

@_spi(Internal) public enum WorkflowTriggerAction: Equatable, Sendable {
    case step(stepId: String)
    case branch(WorkflowBranch)
    case unknown
}

// MARK: - Codable

extension WorkflowTriggerAction: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case stepId
    }

    public init(from decoder: Decoder) throws {
        // Never throws: `triggerActions` propagates, so one bad action would fail the whole workflow.
        var decodedType: String?
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            decodedType = type
            switch type {
            case "step":
                self = .step(stepId: try container.decode(String.self, forKey: .stepId))
            case "branch":
                self = .branch(try WorkflowBranch(from: decoder))
            default:
                Logger.warn(Strings.backendError.unknown_workflow_trigger_action_type(type: type))
                self = .unknown
            }
        } catch {
            Logger.warn(Strings.backendError.malformed_workflow_trigger_action(type: decodedType ?? "nil"))
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
            try branch.encode(to: encoder)
        case .unknown:
            try container.encode("unknown", forKey: .type)
        }
    }

}
