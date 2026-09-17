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
final class WorkflowNavigator: ObservableObject {

    @Published private(set) var currentStepId: String
    private let workflow: PublishedWorkflow
    private var backStack: [String] = []

    init(workflow: PublishedWorkflow) {
        self.workflow = workflow
        self.currentStepId = Self.routed(from: workflow.initialStepId, in: workflow)?.id
            ?? workflow.initialStepId
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
              case .step(let stepId) = step.stepTriggerActions[actionId],
              let nextStep = Self.routed(from: stepId, in: workflow) else {
            return nil
        }

        return .init(
            step: nextStep,
            canNavigateBackAfterNavigation: true
        )
    }

    /// Follows `branch` steps to the first step that has a screen. A branch step carries no screen of its
    /// own, so entering one would fail presentation: it exists only to route.
    ///
    /// Every branch takes its `fallbackStepId` for now. Evaluating the audiences that pick a different route
    /// needs the rules engine, which this layer cannot reach yet.
    static func routed(from stepId: String, in workflow: PublishedWorkflow) -> WorkflowStep? {
        var visited: Set<String> = []
        var stepId = stepId

        while let step = workflow.steps[stepId], visited.insert(stepId).inserted {
            guard let branch = Self.branch(on: step) else { return step }
            stepId = branch.fallbackStepId
        }

        return nil
    }

    /// The branch a step routes through, if it is a routing step rather than a screen.
    private static func branch(on step: WorkflowStep) -> WorkflowBranch? {
        guard step.screenId == nil else { return nil }

        for action in step.stepTriggerActions.values {
            if case .branch(let branch) = action { return branch }
        }

        return nil
    }

    @discardableResult
    func navigateBack() -> WorkflowStep? {
        guard let previousStepId = backStack.popLast() else {
            return nil
        }
        currentStepId = previousStepId
        return workflow.steps[previousStepId]
    }

}

#endif
