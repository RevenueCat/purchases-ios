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

/// Whether the workflow's gate permits the pending checkpoint to pass.
enum CheckpointGateOutcome: Equatable {
    case notApplicable
    case passed
    case notPassed
}

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

    private(set) var outcome: CheckpointGateOutcome = .notApplicable

    private var activeEntitlementIdentifiers: Set<String> = []
    private var reachedGate: WorkflowStepGating?

    var hasUnresolvedGate: Bool {
        return self.outcome == .notPassed
    }

    /// A branch can select an enforced gate, so passage stays blocked until its destination is known.
    func markInitialBranchPending() {
        self.outcome = .notPassed
    }

    /// Marks a gate unresolved before its customer read starts. Ungated destinations only clear a pending branch.
    func beginEntry(step: WorkflowStep) -> Bool {
        guard step.gating?.isEnforced == true else {
            if self.reachedGate == nil { self.outcome = .notApplicable }
            return false
        }
        self.activeEntitlementIdentifiers = []
        _ = self.evaluate(step: step)
        return true
    }

    func evaluate(step: WorkflowStep) -> WorkflowGateDecision {
        guard let gate = step.gating, gate.isEnforced else { return .notGated }
        return self.evaluate(gate: gate)
    }

    /// Re-evaluates the reached gate against customer info from a purchase or restore.
    func update(customerInfo: CustomerInfo) -> WorkflowGateDecision {
        self.activeEntitlementIdentifiers = customerInfo.activeEntitlementIdentifiers
        return self.reachedGate.map(self.evaluate(gate:)) ?? .notGated
    }

    func blocksForwardNavigation(step: WorkflowStep) -> Bool {
        guard let gate = step.gating else { return false }
        return gate.isEnforced && !gate.isSatisfied(by: self.activeEntitlementIdentifiers)
    }

    @discardableResult
    private func evaluate(gate: WorkflowStepGating) -> WorkflowGateDecision {
        let passed = gate.isSatisfied(by: self.activeEntitlementIdentifiers)
        self.reachedGate = gate
        self.outcome = passed ? .passed : .notPassed
        return passed ? .passed : .blocked
    }

}
