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

@_spi(Internal) import RevenueCat

/// Whether the workflow's gate permits the pending checkpoint to pass.
enum CheckpointGateStatus: Equatable {
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

    var status: CheckpointGateStatus {
        switch self.gateState {
        case .notReached:
            return .notApplicable
        case .branchPending:
            return .notPassed
        case let .reached(gate):
            return gate.isSatisfied(by: self.activeEntitlementIdentifiers) ? .passed : .notPassed
        }
    }

    private var activeEntitlementIdentifiers: Set<String> = []
    private var gateState: GateState = .notReached

    private enum GateState {

        case notReached
        case branchPending
        case reached(WorkflowStepGating)

    }

    var hasUnresolvedGate: Bool {
        return self.status == .notPassed
    }

    /// A branch can select an enforced gate, so passage stays blocked until its destination is known.
    func markInitialBranchPending() {
        self.gateState = .branchPending
    }

    /// Marks a gate unresolved before its customer read starts. Ungated destinations only clear a pending branch.
    func beginEntry(step: WorkflowStep) -> Bool {
        guard let gate = step.gating,
              gate.isEnforced else {
            if case .branchPending = self.gateState { self.gateState = .notReached }
            return false
        }
        self.activeEntitlementIdentifiers = []
        self.gateState = .reached(gate)
        return true
    }

    /// Re-evaluates the reached gate against customer info from a purchase or restore.
    func update(customerInfo: CustomerInfo) -> WorkflowGateDecision {
        self.activeEntitlementIdentifiers = customerInfo.activeEntitlementIdentifiers
        guard case let .reached(gate) = self.gateState else { return .notGated }
        return gate.isSatisfied(by: self.activeEntitlementIdentifiers) ? .passed : .blocked
    }

    func blocksForwardNavigation(step: WorkflowStep) -> Bool {
        guard let gate = step.gating else { return false }
        return gate.isEnforced && !gate.isSatisfied(by: self.activeEntitlementIdentifiers)
    }

}
