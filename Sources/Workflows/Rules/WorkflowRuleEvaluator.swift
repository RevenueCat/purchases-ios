//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowRuleEvaluator.swift
//
//  Created by Codex on 3/31/26.

import Foundation

/// Evaluates workflow rule predicates against an SDK-provided context.
@_spi(Internal) public enum WorkflowRuleEvaluator {

    /// Returns the first matching action in a rule bundle for the given trigger and context.
    @_spi(Internal) public static func firstMatchingAction(
        in bundle: WorkflowRuleBundle,
        triggerType: String,
        evaluationContext: WorkflowRuleValue
    ) -> WorkflowRuleAction? {
        return bundle.rules.first {
            $0.supportedRuntimes.sdk &&
            Self.evaluate(rule: $0, triggerType: triggerType, evaluationContext: evaluationContext)
        }?.action
    }

    /// Evaluates a single workflow rule for the given trigger and context.
    @_spi(Internal) public static func evaluate(
        rule: WorkflowRule,
        triggerType: String,
        evaluationContext: WorkflowRuleValue
    ) -> Bool {
        guard rule.trigger.type == triggerType else { return false }
        return Self.evaluate(expression: rule.predicate, context: evaluationContext)
    }

}

private extension WorkflowRuleEvaluator {

    static func evaluate(expression: WorkflowRuleValue, context: WorkflowRuleValue) -> Bool {
        guard case let .object(value) = expression else { return false }

        if let clauses = value["and"] {
            guard case let .array(items) = clauses else { return false }
            return items.allSatisfy { self.evaluate(expression: $0, context: context) }
        }

        if let equality = value["=="] {
            return self.evaluateEquality(expression: equality, context: context)
        }

        return false
    }

    static func evaluateEquality(expression: WorkflowRuleValue, context: WorkflowRuleValue) -> Bool {
        guard case let .array(operands) = expression,
              operands.count == 2,
              let left = self.resolve(operand: operands[0], context: context),
              let right = self.resolve(operand: operands[1], context: context) else {
            return false
        }

        return left == right
    }

    static func resolve(operand: WorkflowRuleValue, context: WorkflowRuleValue) -> WorkflowRuleValue? {
        if case let .object(value) = operand,
           case let .string(path)? = value["var"] {
            return context[path: path]
        }

        switch operand {
        case .string, .int, .double, .bool, .null:
            return operand
        case .object, .array:
            return nil
        }
    }

}
