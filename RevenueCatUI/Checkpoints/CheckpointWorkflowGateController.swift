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

/// Call-scoped gate and operation state; the presenter owns navigation, rendering, and completion.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowGateController {

    /// Entry work belongs to this presentation, including while SwiftUI rebuilds its view value.
    var entryTask: Task<Void, Never>?
    /// Renders the destination when an operation result supersedes its pending read but keeps the gate blocked.
    var resumePendingEntry: (@MainActor () -> Void)?

    private(set) var permitsPurchaseDismissal = true

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
    private var operationAppUserID: String?
    private var deferredOperation: OperationResult?

    private struct OperationResult {

        let customerInfo: CustomerInfo
        let appUserID: String?

    }

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

    func beginOperation(appUserID: String) {
        self.operationAppUserID = appUserID
        self.permitsPurchaseDismissal = false
    }

    func completeOperation(
        customerInfo: CustomerInfo,
        appUserID: String,
        isPresentationHidden: Bool,
        isPurchase: Bool
    ) {
        let operation = OperationResult(customerInfo: customerInfo, appUserID: self.operationAppUserID)
        self.operationAppUserID = nil
        let decision = self.applyOperation(operation, appUserID: appUserID, isPresentationHidden: isPresentationHidden)
        if isPurchase { self.permitsPurchaseDismissal = decision != .blocked }
    }

    func applyDeferredOperation() {
        guard let operation = self.deferredOperation else { return }
        self.deferredOperation = nil
        let decision = self.update(customerInfo: operation.customerInfo)
        self.permitsPurchaseDismissal = decision != .blocked
    }

    func cancelEntry() {
        self.entryTask?.cancel()
        self.entryTask = nil
        self.resumePendingEntry = nil
    }

    func cancelPendingWork() {
        self.deferredOperation = nil
        self.operationAppUserID = nil
        self.cancelEntry()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CheckpointWorkflowGateController {

    private func applyOperation(
        _ operation: OperationResult,
        appUserID: String,
        isPresentationHidden: Bool
    ) -> WorkflowGateDecision {
        let resumePendingEntry = self.resumePendingEntry
        self.cancelEntry()
        if let operationAppUserID = operation.appUserID, appUserID != operationAppUserID {
            resumePendingEntry?()
            return .blocked
        }
        if isPresentationHidden {
            self.deferredOperation = operation
            return .blocked
        }
        let decision = self.update(customerInfo: operation.customerInfo)
        if decision == .blocked { resumePendingEntry?() }
        return decision
    }

}
