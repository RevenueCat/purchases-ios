//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultCheckpointWorkflowResolver+Offering.swift
//
//  Created by RevenueCat.

import Foundation

extension DefaultCheckpointWorkflowResolver {

    func resolveOfferingStep(
        _ rule: CheckpointRule,
        in workflow: SingleStepWorkflow,
        checkpointIdentifier: String,
        traceID: String,
        stepEvents: inout [WorkflowEvent]
    ) async -> CheckpointResolution {
        guard workflow.workflowData.workflow.steps.count == 1 else {
            return Self.unservable(rule, reason: "an offering step cannot be mixed with other steps")
        }
        // Validated before the step starts, so a step that was never servable emits nothing.
        guard let offeringID = workflow.step.offeringIdentifier else {
            return Self.unservable(rule, reason: "the offering step has no valid offering identifier")
        }

        return await Self.trackingStepEvents(for: workflow, traceID: traceID, into: &stepEvents) {
            await self.resolveOffering(
                rule,
                offeringID: offeringID,
                checkpointIdentifier: checkpointIdentifier,
                traceID: traceID
            )
        }
    }

    /// Serves a workflow whose only step is a terminal `offering` step as an offering the app owns.
    ///
    /// Gating has already been validated. Other than that, only the offering identifier is validated,
    /// since a step of this kind renders nothing.
    private func resolveOffering(
        _ rule: CheckpointRule, offeringID: String, checkpointIdentifier: String, traceID: String
    ) async -> CheckpointResolution {
        guard let match = await self.offering(identifier: offeringID, for: rule) else {
            return .noAction(.configurationUnavailable)
        }

        return Self.makeMatchedOffering(match.offering, checkpointIdentifier: checkpointIdentifier, traceID: traceID)
    }

    private static func makeMatchedOffering(
        _ offering: Offering,
        checkpointIdentifier: String,
        traceID: String
    ) -> CheckpointResolution {
        return .matchedOffering(
            offering.withPresentedCheckpointIdentifier(checkpointIdentifier, traceID: traceID),
            traceID: traceID
        )
    }

    /// Loads the offerings and picks `identifier` out of them, logging why the rule can't be served when it
    /// isn't there. Both resolution paths need the offering and the container it came from.
    private func offering(
        identifier: String,
        for rule: CheckpointRule
    ) async -> (offering: Offering, offerings: Offerings)? {
        guard let offerings = await self.loadOfferings() else { return nil }
        guard let offering = offerings.offering(identifier: identifier) else {
            Self.unservable(rule, reason: "offering '\(identifier)' is unavailable")
            return nil
        }

        return (offering, offerings)
    }

}
