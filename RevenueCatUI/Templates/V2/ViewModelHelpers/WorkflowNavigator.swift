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
    /// Keyed by action id. Empty until this visit's resolve lands.
    private var currentStepBranches: [String: String] = [:]
    private var resolveTask: Task<Void, Never>?

    private let resolveBranches: @Sendable (WorkflowStep) async -> [String: String]

    init(
        workflow: PublishedWorkflow,
        resolveBranches: @escaping @Sendable (WorkflowStep) async -> [String: String] = { _ in [:] }
    ) {
        self.workflow = workflow
        self.resolveBranches = resolveBranches
        self.currentStepId = workflow.initialStepId
        self.resolveCurrentStepBranches()
    }

    deinit {
        self.resolveTask?.cancel()
    }

    /// The observation point for a resolve nothing else awaits.
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
        currentStepId = nextStep.step.id
        self.resolveCurrentStepBranches()
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
        currentStepId = previousStepId
        self.resolveCurrentStepBranches()
        return workflow.steps[previousStepId]
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowNavigator {

    /// Abandons the previous step's resolve, so every visit routes on its own answer.
    private func resolveCurrentStepBranches() {
        self.currentStepBranches = [:]
        self.resolveTask?.cancel()
        self.resolveTask = nil

        guard let step = self.currentStep, step.hasBranchAction else { return }
        self.resolveTask = Task { [weak self, resolveBranches] in
            let resolved = await resolveBranches(step)
            // Enough on its own: cancel() precedes the step change and this block never suspends.
            guard !Task.isCancelled else { return }
            self?.currentStepBranches = resolved
        }
    }

    /// A branch falls back unless its route resolved to a step the workflow still has.
    func nextStepId(for action: WorkflowTriggerAction?, actionId: String) -> String? {
        switch action {
        case .step(let stepId):
            return stepId
        case .branch(let branch):
            guard let routed = self.currentStepBranches[actionId], self.workflow.steps[routed] != nil else {
                return branch.fallbackStepId
            }
            return routed
        case .unknown, nil:
            return nil
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowStep {

    var hasBranchAction: Bool {
        return self.stepTriggerActions.values.contains { action in
            if case .branch = action { return true }
            return false
        }
    }

}

#endif
