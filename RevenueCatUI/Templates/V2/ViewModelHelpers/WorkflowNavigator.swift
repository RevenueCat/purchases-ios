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
final class WorkflowNavigator: ObservableObject {

    @Published private(set) var currentStepId: String
    private let workflow: PublishedWorkflow
    private var backStack: [String] = []

    init(workflow: PublishedWorkflow) {
        self.workflow = workflow
        self.currentStepId = Self.resolveExperimentStep(workflow.initialStepId, in: workflow)
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
        guard let step = currentStep,
              let trigger = step.stepTriggers.first(where: {
                  $0.componentId == componentId && $0.type == triggerType
              }),
              let actionId = trigger.actionId,
              let triggerAction = step.stepTriggerActions[actionId],
              case .step(let stepId) = triggerAction,
              let nextStep = workflow.steps[stepId] else {
            return nil
        }

        backStack.append(currentStepId)
        currentStepId = Self.resolveExperimentStep(nextStep.id, in: workflow)
        return workflow.steps[currentStepId]
    }

    @discardableResult
    func navigateBack() -> WorkflowStep? {
        guard let previousStepId = backStack.popLast() else {
            return nil
        }
        currentStepId = previousStepId
        return workflow.steps[previousStepId]
    }

    // MARK: - Experiment resolution

    /// If `stepId` points to an experiment step, follows the enrolled variant's trigger action
    /// to the real content step. Experiment steps are skipped silently (not added to back stack)
    /// so the user can never navigate back to them. Safe against cycles — stops after visiting
    /// each step at most once.
    // Experiment steps are pruned by WorkflowDetailProcessor before the navigator sees the workflow,
    // so each experiment step has at most one remaining .step action (the enrolled variant's).
    private static func resolveExperimentStep(_ stepId: String, in workflow: PublishedWorkflow) -> String {
        var visitedIds = Set<String>()
        var resolvedId = stepId

        while true {
            guard !visitedIds.contains(resolvedId),
                  let step = workflow.steps[resolvedId],
                  step.isExperimentStep,
                  let nextAction = step.stepTriggerActions.values
                      .first(where: { if case .step = $0 { return true }; return false }),
                  case .step(let nextStepId) = nextAction else {
                break
            }
            visitedIds.insert(resolvedId)
            resolvedId = nextStepId
        }

        return resolvedId
    }

}

#endif
