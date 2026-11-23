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

enum WorkflowOperationCompletion: Equatable {
    case none
    case dismissWorkflow
    case completeGate
}

/// Call-scoped gate and operation state; the presenter owns navigation, rendering, and completion.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowGateController {

    /// Entry work belongs to this presentation, including while SwiftUI rebuilds its view value.
    private(set) var entryTask: Task<Void, Never>?

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

    /// Renders the destination when an operation result supersedes its pending read but keeps the gate blocked.
    private var resumePendingEntry: (@MainActor () -> Void)?
    private var activeEntitlementIdentifiers: Set<String> = []
    private var gateState: GateState = .notReached
    private var operationAppUserID: String?
    private var deferredOperation: OperationResult?

    private struct OperationResult {

        let customerInfo: CustomerInfo
        let appUserID: String?
        let isPurchase: Bool

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

    func enter(
        step: WorkflowStep,
        customerInfo: @escaping @MainActor () async throws -> CustomerInfo,
        appUserID: @escaping @MainActor () -> String,
        canApplyResult: @escaping @MainActor () -> Bool,
        completion: @escaping @MainActor (WorkflowGateDecision) -> Void
    ) {
        self.cancelEntry()
        guard self.beginEntry(step: step) else {
            completion(.notGated)
            return
        }
        let entryAppUserID = appUserID()
        self.resumePendingEntry = { completion(.blocked) }
        self.entryTask = Task { @MainActor in
            let result: Result<CustomerInfo, Error>
            do {
                result = .success(try await customerInfo())
            } catch {
                result = .failure(error)
            }
            guard !Task.isCancelled else { return }
            self.entryTask = nil
            self.resumePendingEntry = nil
            guard canApplyResult() else { return }

            var decision = WorkflowGateDecision.blocked
            switch result {
            case let .success(info):
                if appUserID() == entryAppUserID {
                    decision = self.update(customerInfo: info)
                }
            case let .failure(error):
                Logger.warning(Strings.workflow_gate_customer_read_failed(stepId: step.id, error: error))
            }
            completion(decision)
        }
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
    }

    func completeOperation(
        customerInfo: CustomerInfo,
        appUserID: String,
        isPresentationHidden: Bool,
        isPurchase: Bool
    ) -> WorkflowOperationCompletion {
        let operation = OperationResult(
            customerInfo: customerInfo, appUserID: self.operationAppUserID, isPurchase: isPurchase
        )
        self.operationAppUserID = nil
        let decision = self.applyOperation(operation, appUserID: appUserID, isPresentationHidden: isPresentationHidden)
        return self.operationCompletion(for: decision, isPurchase: isPurchase)
    }

    func applyDeferredOperation() -> WorkflowOperationCompletion {
        guard let operation = self.deferredOperation else { return .none }
        self.deferredOperation = nil
        let decision = self.update(customerInfo: operation.customerInfo)
        return self.operationCompletion(for: decision, isPurchase: operation.isPurchase)
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

    func operationCompletion(for decision: WorkflowGateDecision, isPurchase: Bool) -> WorkflowOperationCompletion {
        switch decision {
        case .passed:
            return .completeGate
        case .notGated:
            return isPurchase && !self.hasUnresolvedGate ? .dismissWorkflow : .none
        case .blocked:
            return .none
        }
    }

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
