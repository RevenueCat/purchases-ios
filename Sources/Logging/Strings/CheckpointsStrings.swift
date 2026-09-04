//
//  CheckpointsStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

enum CheckpointsStrings {

    case audiencesNotEvaluated(checkpointID: String, reason: String)
    case resolutionRepeatedlyStale(identifier: String)
    case resolutionRetry(identifier: String)
    case ruleSkipped(reason: String)
    case workflowRuleSkipped(workflowID: String, reason: String)

}

extension CheckpointsStrings: LogMessage {

    var description: String {
        switch self {
        case let .audiencesNotEvaluated(checkpointID, reason):
            return "The audiences for checkpoint '\(checkpointID)' could not be evaluated: \(reason)."
        case let .resolutionRepeatedlyStale(identifier):
            return "Remote configuration kept changing while resolving checkpoint '\(identifier)'."
        case let .resolutionRetry(identifier):
            return "Remote configuration changed while resolving checkpoint '\(identifier)'; resolving it again."
        case let .ruleSkipped(reason):
            return "Skipping malformed checkpoint rule: \(reason)."
        case let .workflowRuleSkipped(workflowID, reason):
            return "Skipping checkpoint rule for workflow '\(workflowID)': \(reason)."
        }
    }

    var category: String { return "checkpoints" }

}
