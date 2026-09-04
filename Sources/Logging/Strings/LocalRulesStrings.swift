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
    case ruleUnresolvedVariable(ruleIndex: Int, path: String)
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
        case let .ruleUnresolvedVariable(ruleIndex, path):
            return "Rule at index \(ruleIndex) did not match because variable '\(path)' could not be resolved."
        case let .subscriberAttributesUnavailable(error):
            return "The subscriber attributes are unavailable, so they cannot be evaluated: \(error)."
        case let .subscriberDimensionsUnavailable(error):
            return "The subscriber dimensions are unavailable, so they cannot be evaluated: \(error)."
        }
    }

    var category: String { return "local_rules" }

}
