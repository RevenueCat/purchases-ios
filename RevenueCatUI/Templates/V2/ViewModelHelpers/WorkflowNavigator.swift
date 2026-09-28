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
    /// The current step's branch destinations, keyed by action id. Cleared on every step change, so each
    /// visit re-resolves, and until a visit's resolve lands its branches route to their `fallbackStepId`.
    private var resolvedBranchSteps: [String: String] = [:]
    private var resolveTask: Task<Void, Never>?

    private let branchResolver: BranchResolver?

    init(workflow: PublishedWorkflow, branchResolver: BranchResolver? = nil) {
        self.workflow = workflow
        self.branchResolver = branchResolver
        self.currentStepId = workflow.initialStepId
        self.beginStepVisit()
    }

    deinit {
        self.resolveTask?.cancel()
    }

    /// Waits for the current visit's resolve. Only tests need this: nothing in the UI waits on resolution.
    func waitForBranchResolution() async {
        await self.resolveTask?.value
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

    /// Starts this visit's resolve and abandons the previous one, so each visit to a step, including a step
    /// that targets itself, routes on its own answer.
    private func beginStepVisit() {
        self.resolvedBranchSteps = [:]
        self.resolveTask?.cancel()

        guard let branchResolver else { return }
        self.resolveTask = Task { [weak self] in
            guard let step = self?.currentStep else { return }
            let resolved = await branchResolver.resolveBranches(in: step)
            guard !Task.isCancelled else { return }
            self?.resolvedBranchSteps = resolved
        }
    }

    /// A branch takes the route its audiences picked, or its fallback when none matched. A route naming a
    /// step the workflow does not contain also falls back, so config drift cannot leave the button dead.
    func nextStepId(for action: WorkflowTriggerAction?, actionId: String) -> String? {
        switch action {
        case .step(let stepId):
            return stepId
        case .branch(let branch):
            guard let routed = self.resolvedBranchSteps[actionId], self.workflow.steps[routed] != nil else {
                return branch.fallbackStepId
            }
            return routed
        case .unknown, nil:
            return nil
        }
    }

}

#endif
