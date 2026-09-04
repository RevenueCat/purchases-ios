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
    /// Destination per exit (`actionId` -> step id), resolved when the step is entered so a tap is a
    /// lookup rather than a decision.
    private(set) var resolvedExits: [String: String] = [:]
    private let workflow: PublishedWorkflow
    private var backStack: [String] = []

    init(workflow: PublishedWorkflow) {
        self.workflow = workflow
        self.currentStepId = workflow.initialStepId
        self.resolvedExits = Self.resolveExits(for: workflow.steps[workflow.initialStepId], in: workflow)
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
              let stepId = resolvedExits[actionId],
              let nextStep = workflow.steps[stepId] else {
            return nil
        }

        backStack.append(currentStepId)
        moveTo(nextStep.id)
        return nextStep
    }

    @discardableResult
    func navigateBack() -> WorkflowStep? {
        guard let previousStepId = backStack.popLast() else {
            return nil
        }
        moveTo(previousStepId)
        return workflow.steps[previousStepId]
    }

    private func moveTo(_ stepId: String) {
        currentStepId = stepId
        resolvedExits = Self.resolveExits(for: workflow.steps[stepId], in: workflow)
    }

    /// Only `.step` exits resolve today. A `.conditions` exit needs the rules engine, which this
    /// layer cannot reach yet, so it is left unresolved and does not navigate.
    private static func resolveExits(
        for step: WorkflowStep?,
        in workflow: PublishedWorkflow
    ) -> [String: String] {
        guard let step else { return [:] }

        return step.stepTriggerActions.reduce(into: [:]) { exits, entry in
            guard case let .step(stepId) = entry.value, workflow.steps[stepId] != nil else { return }
            exits[entry.key] = stepId
        }
    }

}

#endif
