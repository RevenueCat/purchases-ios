//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowGateController.swift
//

import Foundation
@_spi(Internal) import RevenueCat

enum WorkflowGateDecision: Equatable {
    case notGated
    case passed
    case blocked
}

/// Call-scoped gate and entry task state; the presenter owns navigation, rendering, and completion.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowGateController {

    /// Entry work belongs to this presentation, including while SwiftUI rebuilds its view value.
    var entryTask: Task<Void, Never>?
    var entryID: UUID?

    private var context: CheckpointGateContext?
    private var activeEntitlementIdentifiers: Set<String> = []
    private var reachedGate: WorkflowStepGating?
    private var outcome: CheckpointGateOutcome = .notApplicable

    var hasContext: Bool {
        return self.context != nil
    }

    var hasUnresolvedGate: Bool {
        return self.outcome == .notPassed
    }

    func reset(context: CheckpointGateContext?) {
        self.context = context
        self.activeEntitlementIdentifiers = []
        self.reachedGate = nil
        self.outcome = .notApplicable
        context?.onOutcomeChanged(self.outcome)
    }

    /// A branch can select an enforced gate, so passage stays blocked until its destination is known.
    func markInitialBranchPending() {
        guard self.context != nil else { return }
        self.reportOutcome(.notPassed)
    }

    /// Marks a gate unresolved before its customer read starts. Ungated destinations only clear a pending branch.
    func beginEntry(step: WorkflowStep) -> Bool {
        guard self.context != nil else { return false }
        guard step.gating?.isEnforced == true else {
            if self.reachedGate == nil { self.reportOutcome(.notApplicable) }
            return false
        }
        self.activeEntitlementIdentifiers = []
        _ = self.evaluate(step: step)
        return true
    }

    func evaluate(step: WorkflowStep) -> WorkflowGateDecision {
        guard self.context != nil, let gate = step.gating, gate.isEnforced else { return .notGated }
        return self.evaluate(gate: gate)
    }

    /// Re-evaluates the reached gate against customer info from a purchase or restore.
    func update(customerInfo: CustomerInfo) -> WorkflowGateDecision {
        guard self.context != nil else { return .notGated }
        self.activeEntitlementIdentifiers = customerInfo.activeEntitlementIdentifiers
        return self.reachedGate.map(self.evaluate(gate:)) ?? .notGated
    }

    func blocksForwardNavigation(step: WorkflowStep) -> Bool {
        guard self.context != nil, let gate = step.gating else { return false }
        return gate.isEnforced && !gate.isSatisfied(by: self.activeEntitlementIdentifiers)
    }

    @discardableResult
    private func evaluate(gate: WorkflowStepGating) -> WorkflowGateDecision {
        let passed = gate.isSatisfied(by: self.activeEntitlementIdentifiers)
        self.reachedGate = gate
        let newOutcome: CheckpointGateOutcome = passed ? .passed : .notPassed
        self.reportOutcome(newOutcome)
        return passed ? .passed : .blocked
    }

    private func reportOutcome(_ outcome: CheckpointGateOutcome) {
        guard outcome != self.outcome else { return }
        self.outcome = outcome
        self.context?.onOutcomeChanged(outcome)
    }

}
