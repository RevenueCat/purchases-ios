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
    private var currentStepBranches: [WorkflowActionID: WorkflowStepID] = [:]
    private var resolveTask: Task<Void, Never>?
    private var initialStepTask: Task<Void, Never>?

    private let resolveBranch: @Sendable (WorkflowBranch) async -> WorkflowStepID

    /// The branch that has to route the first step before anything can render.
    /// `branchingEnabled` goes away once branching ships; then an `initialTrigger` always routes.
    static func initialBranch(in workflow: PublishedWorkflow, branchingEnabled: Bool) -> WorkflowBranch? {
        guard branchingEnabled, case .branch(let branch) = workflow.initialTrigger else { return nil }
        return branch
    }

    init(
        workflow: PublishedWorkflow,
        branchingEnabled: Bool = false,
        resolveBranch: @escaping @Sendable (WorkflowBranch) async -> WorkflowStepID = { $0.fallbackStepId }
    ) {
        let initialBranch = Self.initialBranch(in: workflow, branchingEnabled: branchingEnabled)
        self.workflow = workflow
        self.resolveBranch = resolveBranch
        self.currentStepId = workflow.initialStepId

        guard let initialBranch else {
            self.resolveCurrentStepBranches()
            return
        }
        let task = Task { [weak self, resolveBranch] in
            let stepId = await resolveBranch(initialBranch)
            guard !Task.isCancelled else { return }
            self?.enterInitialStep(stepId)
        }
        self.resolveTask = task
        self.initialStepTask = task
    }

    /// `initialStepId` is the initial branch's fallback, so an unknown route just stays put.
    private func enterInitialStep(_ stepId: WorkflowStepID) {
        if self.workflow.steps[stepId] != nil {
            self.currentStepId = stepId
        }
        self.resolveCurrentStepBranches()
    }

    deinit {
        self.resolveTask?.cancel()
    }

    /// Completes once `initialTrigger` picked the first step. Returns right away when nothing had to
    /// be routed. This is the one resolve the UI waits on: it has nothing to render until it lands.
    func waitForInitialStep() async {
        await self.initialStepTask?.value
    }

    /// Tests only. Nothing in the UI waits for a step's own branches to resolve.
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

    private func resolveCurrentStepBranches() {
        self.currentStepBranches = [:]
        self.resolveTask?.cancel()
        self.resolveTask = nil

        guard let step = self.currentStep, step.hasBranchAction else { return }
        self.resolveTask = Task { [weak self, resolveBranch] in
            var resolved: [WorkflowActionID: WorkflowStepID] = [:]
            for (actionId, action) in step.stepTriggerActions {
                guard !Task.isCancelled else { return }
                guard case .branch(let branch) = action else { continue }
                resolved[actionId] = await resolveBranch(branch)
            }
            // Enough on its own: cancel() precedes the step change and this block never suspends.
            guard !Task.isCancelled else { return }
            self?.currentStepBranches = resolved
        }
    }

    /// If the branch has not been resolved, pick the fallback.
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
