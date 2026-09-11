//
//  LocalRulesStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

enum LocalRulesStrings {

    case customerInfoUnavailable(Error)
    case invalidDimensionName(String, parentPath: String)
    case evaluatingRules(logPrefix: String, ruleCount: Int, dimensions: [String])
    case ruleMatched(logPrefix: String, ruleIndex: Int)
    case ruleDidNotMatch(logPrefix: String, ruleIndex: Int)
    case ruleUnresolvedVariable(logPrefix: String, ruleIndex: Int, path: String)
    case ruleEvaluationFailed(logPrefix: String, ruleIndex: Int, errorKind: String)
    case subscriberAttributesUnavailable(Error)
    case subscriberDimensionsUnavailable(Error)

}

extension LocalRulesStrings: LogMessage {

    var description: String {
        switch self {
        case let .customerInfoUnavailable(error):
            return "The customer info is unavailable, so its checkpoint dimensions cannot be evaluated: \(error)."
        case let .invalidDimensionName(name, parentPath):
            return "Ignoring dimension name '\(name)' under '\(parentPath)': " +
                "a dimension name cannot be empty, whitespace-only, or contain '.'."
        case let .evaluatingRules(logPrefix, ruleCount, dimensions):
            return "\(logPrefix)Evaluating \(ruleCount) rules against dimensions \(dimensions)."
        case let .ruleMatched(logPrefix, ruleIndex):
            return "\(logPrefix)Rule \(ruleIndex) matched."
        case let .ruleDidNotMatch(logPrefix, ruleIndex):
            return "\(logPrefix)Rule \(ruleIndex) did not match."
        case let .ruleUnresolvedVariable(logPrefix, ruleIndex, path):
            return "\(logPrefix)Rule \(ruleIndex) did not match: it reads '\(path)', " +
                "which this SDK does not supply."
        case let .ruleEvaluationFailed(logPrefix, ruleIndex, errorKind):
            return "\(logPrefix)Rule \(ruleIndex) could not be evaluated (\(errorKind))."
        case let .subscriberAttributesUnavailable(error):
            return "The subscriber attributes are unavailable, so they cannot be evaluated: \(error)."
        case let .subscriberDimensionsUnavailable(error):
            return "The subscriber dimensions are unavailable, so they cannot be evaluated: \(error)."
        }
    }

    var category: String { return "local_rules" }

}
