//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultCheckpointWorkflowResolver+Ad.swift
//
//  Created by RevenueCat.

import Foundation

extension DefaultCheckpointWorkflowResolver {

    static let adStepType = "ad"
    static let adIdentifierParam = "ad_identifier"
    static let mediatorParam = "mediator"
    static let adFormatParam = "ad_format"

    /// Serves a workflow made only of `ad` steps as an ad workflow the app owns. Every step is validated up
    /// front, since a chain the presenter can't finish shouldn't start.
    static func resolveAdWorkflow(_ rule: CheckpointRule, workflow: PublishedWorkflow) -> CheckpointResolution {
        guard workflow.steps.values.allSatisfy({ $0.type == Self.adStepType }) else {
            return Self.unservable(rule, reason: "an ad step cannot be mixed with other steps")
        }

        var steps: [String: ResolvedAdStep] = [:]
        for (stepId, step) in workflow.steps {
            guard let resolved = Self.resolveAdStep(rule, step: step, in: workflow) else {
                return .noAction(.configurationUnavailable)
            }
            steps[stepId] = resolved
        }
        guard let initialStep = steps[workflow.initialStepId] else {
            return Self.unservable(rule, reason: "its initial step was not found")
        }

        return .matchedAd(ResolvedAdWorkflow(initialStep: initialStep, steps: steps))
    }

    /// Only `ad_identifier`, `mediator` and `ad_format` are validated. Anything else the step happens to carry
    /// is ignored rather than treated as unservable, since a step of this kind renders nothing.
    private static func resolveAdStep(
        _ rule: CheckpointRule,
        step: WorkflowStep,
        in workflow: PublishedWorkflow
    ) -> ResolvedAdStep? {
        guard let adIdentifier = Self.stringParam(Self.adIdentifierParam, in: step), !adIdentifier.isEmpty else {
            Self.unservable(rule, reason: "the ad step has no valid ad identifier")
            return nil
        }
        guard let mediator = Self.stringParam(Self.mediatorParam, in: step), !mediator.isEmpty else {
            Self.unservable(rule, reason: "the ad step has no valid mediator")
            return nil
        }
        guard let adFormat = Self.stringParam(Self.adFormatParam, in: step), !adFormat.isEmpty else {
            Self.unservable(rule, reason: "the ad step has no valid ad format")
            return nil
        }

        // Like `WorkflowNavigator`, an action that isn't a step or points nowhere ends the workflow.
        var nextStepId: String?
        if case let .step(stepId)? = step.triggerActions[ResolvedAdStep.triggerActionId],
           workflow.steps[stepId] != nil {
            nextStepId = stepId
        }

        return ResolvedAdStep(
            adIdentifier: adIdentifier,
            mediator: Self.normalizedMediator(mediator),
            adFormat: AdFormat(rawValue: adFormat),
            nextStepId: nextStepId
        )
    }

    static func stringParam(_ key: String, in step: WorkflowStep) -> String? {
        guard case let .string(value)? = step.paramValues[key] else { return nil }
        return value
    }

    /// The backend serializes mediators in lowercase (`admob`) while the SDK's canonical constants are
    /// mixed case (`AdMob`), and `MediatorName` equality is case-sensitive. Map mediators checkpoints
    /// support onto their canonical instance so presenters can match on them; anything else (including
    /// unsupported mediators like AppLovin) passes through untouched.
    private static let knownMediators: [MediatorName] = [.adMob]

    private static func normalizedMediator(_ rawValue: String) -> MediatorName {
        return Self.knownMediators.first { known in
            known.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame
        } ?? MediatorName(rawValue: rawValue)
    }

}
