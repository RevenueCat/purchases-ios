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

/// Call-scoped gate state only; the presenter owns navigation, rendering, and completion.
///
/// Entitlements are only trusted for the app user they were read for. When the app user changes mid-checkpoint
/// they become unknown, and the gate fails closed until `update` is given customer info read for the new user
/// (after an anonymous purchase is aliased onto a newly logged-in user, that info holds the entitlement).
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowGateController {

    private let currentAppUserID: @MainActor () -> String
    private var context: CheckpointGateContext?
    private var appUserID: String?
    private var activeEntitlementIdentifiers: Set<String> = []
    private var reachedGate: WorkflowStepGating?
    private var outcome: CheckpointGateOutcome = .notApplicable

    init(currentAppUserID: @escaping @MainActor () -> String) {
        self.currentAppUserID = currentAppUserID
    }

    var hasContext: Bool {
        return self.context != nil
    }

    var hasUnresolvedGate: Bool {
        self.refreshIdentity()
        return self.outcome == .notPassed
    }

    func reset(context: CheckpointGateContext?) {
        self.context = context
        self.appUserID = context?.initialAppUserID
        self.activeEntitlementIdentifiers = context?.initialActiveEntitlementIdentifiers ?? []
        self.reachedGate = nil
        self.outcome = .notApplicable
        context?.onOutcomeChanged(self.outcome)
    }

    func evaluate(step: WorkflowStep) -> WorkflowGateDecision {
        guard self.context != nil, let gate = step.gating, gate.isEnforced else { return .notGated }
        self.refreshIdentity()
        return self.evaluate(gate: gate)
    }

    /// Applies `customerInfo`, which was read for `appUserID`. Ignored when that is no longer the current app
    /// user, as when the host switched users before this info was delivered.
    func update(forAppUserID appUserID: String, customerInfo: CustomerInfo) -> WorkflowGateDecision {
        guard self.context != nil else { return .notGated }
        self.refreshIdentity()
        if appUserID == self.appUserID {
            self.activeEntitlementIdentifiers = customerInfo.activeEntitlementIdentifiers
        }
        return self.reachedGate.map(self.evaluate(gate:)) ?? .notGated
    }

    func blocksForwardNavigation(step: WorkflowStep) -> Bool {
        self.refreshIdentity()
        guard self.context != nil, let gate = step.gating else { return false }
        return gate.isEnforced && !gate.isSatisfied(by: self.activeEntitlementIdentifiers)
    }

    func isCurrentAppUserID(_ operationAppUserID: String) -> Bool {
        self.refreshIdentity()
        return self.currentAppUserID() == operationAppUserID
    }

    private func refreshIdentity() {
        guard self.context != nil else { return }
        let currentID = self.currentAppUserID()
        guard self.appUserID != currentID else { return }

        self.appUserID = currentID
        self.activeEntitlementIdentifiers = []
        // Retain reached gates even after passage: host callbacks can switch identity before dismissal.
        if let reachedGate = self.reachedGate {
            self.evaluate(gate: reachedGate)
        }
    }

    @discardableResult
    private func evaluate(gate: WorkflowStepGating) -> WorkflowGateDecision {
        let passed = gate.isSatisfied(by: self.activeEntitlementIdentifiers)
        self.reachedGate = gate
        let newOutcome: CheckpointGateOutcome = passed ? .passed : .notPassed
        if newOutcome != self.outcome {
            self.outcome = newOutcome
            self.context?.onOutcomeChanged(newOutcome)
        }
        return passed ? .passed : .blocked
    }

}
