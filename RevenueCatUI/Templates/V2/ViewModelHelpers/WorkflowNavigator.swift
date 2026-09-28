//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowNavigator.swift

import Combine
@_spi(Internal) import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowBackNavigationDestination {
    let step: WorkflowStep
    let canNavigateBackAfterNavigation: Bool
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowForwardNavigationDestination {
    let step: WorkflowStep
    let canNavigateBackAfterNavigation: Bool
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WorkflowNavigator: ObservableObject {

    @Published private(set) var currentStepId: String
    private let workflow: PublishedWorkflow
    private var backStack: [String] = []
    /// The current step's branch destinations, keyed by action id. Cleared whenever the step changes, so
    /// reaching a step again re-resolves it. Until a step's resolve lands, its branches route to their
    /// configured `fallbackStepId`.
    private var resolvedBranchSteps: [String: String] = [:]
    /// Bumped on every step change, so a resolve started on one visit cannot apply to a later one. Step ids
    /// repeat when navigating back, so they cannot tell two visits apart on their own.
    private var stepVisit = 0

    private let branchResolver: BranchResolver?

    init(workflow: PublishedWorkflow, branchResolver: BranchResolver? = nil) {
        self.workflow = workflow
        self.branchResolver = branchResolver
        self.currentStepId = workflow.initialStepId
    }

    /// Resolves the current step's branches. Nothing waits on this: until it lands those branches route to
    /// their configured `fallbackStepId`. A result from a visit the user has already left is dropped.
    func resolveBranchesForCurrentStep() async {
        guard let branchResolver, let step = self.currentStep else { return }
        let visit = self.stepVisit
        let resolved = await branchResolver.resolveBranches(in: step)
        guard visit == self.stepVisit else { return }
        self.resolvedBranchSteps = resolved
    }

    var currentStep: WorkflowStep? {
        return workflow.steps[currentStepId]
    }

    var canNavigateBack: Bool {
        return !backStack.isEmpty
    }

    var backNavigationDestination: WorkflowBackNavigationDestination? {
        guard let previousStepId = backStack.last,
              let previousStep = workflow.steps[previousStepId] else {
            return nil
        }

        return .init(
            step: previousStep,
            canNavigateBackAfterNavigation: backStack.count > 1
        )
    }

    @discardableResult
    func triggerAction(componentId: String, triggerType: WorkflowTriggerType = .onPress) -> WorkflowStep? {
        guard let nextStep = self.triggerActionDestination(componentId: componentId, triggerType: triggerType) else {
            return nil
        }

        backStack.append(currentStepId)
        self.beginStepVisit()
        currentStepId = nextStep.step.id
        return nextStep.step
    }

    /// Resolves the step targeted by an action without changing the current step or back stack.
    /// Callers that need to ensure the target can be rendered should use this before `triggerAction`.
    func triggerActionDestination(
        componentId: String,
        triggerType: WorkflowTriggerType = .onPress
    ) -> WorkflowForwardNavigationDestination? {
        guard let step = currentStep,
              let trigger = step.stepTriggers.first(where: {
                  $0.componentId == componentId && $0.type == triggerType
              }),
              let actionId = trigger.actionId,
              let stepId = self.nextStepId(for: step.stepTriggerActions[actionId], actionId: actionId),
              let nextStep = workflow.steps[stepId] else {
            return nil
        }

        return .init(
            step: nextStep,
            canNavigateBackAfterNavigation: true
        )
    }

    @discardableResult
    func navigateBack() -> WorkflowStep? {
        guard let previousStepId = backStack.popLast() else {
            return nil
        }
        self.beginStepVisit()
        currentStepId = previousStepId
        return workflow.steps[previousStepId]
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowNavigator {

    private func beginStepVisit() {
        self.resolvedBranchSteps = [:]
        self.stepVisit += 1
    }

    /// A branch takes the route its audiences picked, or its fallback when none matched.
    func nextStepId(for action: WorkflowTriggerAction?, actionId: String) -> String? {
        switch action {
        case .step(let stepId): return stepId
        case .branch(let branch): return self.resolvedBranchSteps[actionId] ?? branch.fallbackStepId
        case .unknown, nil: return nil
        }
    }

}

#endif
