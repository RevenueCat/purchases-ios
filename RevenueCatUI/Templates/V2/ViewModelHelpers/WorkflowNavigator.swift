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
    private let branchResolver: WorkflowStepBranchResolver
    private var initialStepTask: Task<Void, Never>?

    init(
        workflow: PublishedWorkflow,
        resolveBranch: (@Sendable (WorkflowBranch) async -> WorkflowStepID)? = nil
    ) {
        self.workflow = workflow
        self.branchResolver = WorkflowStepBranchResolver(resolveBranch: resolveBranch)
        self.currentStepId = workflow.initialStepId

        guard let resolveBranch, let initialBranch = workflow.initialBranch else {
            self.branchResolver.resolve(self.currentStep)
            return
        }
        self.initialStepTask = Task { [weak self] in
            let stepId = await resolveBranch(initialBranch)
            guard !Task.isCancelled else { return }
            self?.enterInitialStep(stepId)
        }
    }

    /// A route the workflow does not have is ignored, leaving `currentStepId` on `initialStepId`,
    /// which is this branch's fallback.
    private func enterInitialStep(_ stepId: WorkflowStepID) {
        if self.workflow.steps[stepId] != nil {
            self.currentStepId = stepId
        }
        self.branchResolver.resolve(self.currentStep)
    }

    deinit {
        self.initialStepTask?.cancel()
    }

    /// The one resolve the UI waits on: there is nothing to render until the first step is known.
    func waitForInitialStep() async {
        await self.initialStepTask?.value
    }

    /// Tests only. Nothing in the UI waits for a step's own branches to resolve.
    func waitForBranchResolution() async {
        await self.branchResolver.waitForResolution()
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
        self.branchResolver.resolve(self.currentStep)
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
        self.branchResolver.resolve(self.currentStep)
        return workflow.steps[previousStepId]
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowNavigator {

    /// If the branch has not been resolved, pick the fallback.
    func nextStepId(for action: WorkflowTriggerAction?, actionId: String) -> String? {
        switch action {
        case .step(let stepId):
            return stepId
        case .branch(let branch):
            guard let routed = self.branchResolver.route(for: actionId), self.workflow.steps[routed] != nil else {
                return branch.fallbackStepId
            }
            return routed
        case .unknown, nil:
            return nil
        }
    }

}

/// Where each of a step's `branch` actions routes. Cleared when the step is left, so every visit
/// routes on its own answer.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
private final class WorkflowStepBranchResolver {

    /// `nil` while branch routing is unreleased: every branch takes its fallback.
    private let resolveBranch: (@Sendable (WorkflowBranch) async -> WorkflowStepID)?
    private var routes: [WorkflowActionID: WorkflowStepID] = [:]
    private var task: Task<Void, Never>?

    init(resolveBranch: (@Sendable (WorkflowBranch) async -> WorkflowStepID)?) {
        self.resolveBranch = resolveBranch
    }

    deinit {
        self.task?.cancel()
    }

    /// Starts resolving the branches on the step just entered, abandoning the previous step's.
    func resolve(_ step: WorkflowStep?) {
        self.routes = [:]
        self.task?.cancel()
        self.task = nil

        guard let resolveBranch = self.resolveBranch, let step, step.hasBranchAction else { return }
        self.task = Task { [weak self] in
            var resolved: [WorkflowActionID: WorkflowStepID] = [:]
            for (actionId, action) in step.stepTriggerActions {
                guard !Task.isCancelled else { return }
                guard case .branch(let branch) = action else { continue }
                resolved[actionId] = await resolveBranch(branch)
            }
            // Enough on its own: cancel() precedes the step change and this block never suspends.
            guard !Task.isCancelled else { return }
            self?.routes = resolved
        }
    }

    func route(for actionId: WorkflowActionID) -> WorkflowStepID? {
        return self.routes[actionId]
    }

    /// Tests only. Nothing in the UI waits for a step's branches.
    func waitForResolution() async {
        await self.task?.value
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PublishedWorkflow {

    /// The branch that has to route the first step before anything can render.
    var initialBranch: WorkflowBranch? {
        guard case .branch(let branch) = self.initialTrigger else { return nil }
        return branch
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
