//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowResolver.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// The result of resolving a checkpoint against RevenueCat configuration.
@_spi(Internal) public enum CheckpointResolution {

    /// A workflow was selected for the checkpoint.
    case matchedWorkflow(ResolvedCheckpointWorkflow)
    /// An offering was selected for the checkpoint, with no RevenueCat-managed UI to present. The app
    /// decides whether and how to use it.
    case matchedOffering(Offering)
    /// No workflow should run for the checkpoint.
    case noAction(CheckpointResolutionReason)

}

/// The reason that checkpoint resolution selected no workflow.
@_spi(Internal) public enum CheckpointResolutionReason: Sendable {

    /// No targeting rule matched.
    case noMatch
    /// Checkpoint configuration could not be loaded.
    case configurationUnavailable
    /// Checkpoints are disabled.
    case disabled
    /// The checkpoint identifier is not configured.
    case unknownCheckpoint
    /// The customer changed while the checkpoint was being resolved.
    case customerChanged

}

/// A workflow resolved from RevenueCat configuration and ready for RevenueCatUI to present.
@_spi(Internal) public final class ResolvedCheckpointWorkflow: @unchecked Sendable {

    /// The workflow to render.
    public let workflow: PublishedWorkflow
    /// UI configuration used to render the workflow.
    public let uiConfig: UIConfig
    /// The offering referenced by the workflow.
    public let offering: Offering
    /// All offerings available while executing the workflow.
    public let offerings: Offerings

    init(workflow: PublishedWorkflow, uiConfig: UIConfig, offering: Offering, offerings: Offerings) {
        self.workflow = workflow
        self.uiConfig = uiConfig
        self.offering = offering
        self.offerings = offerings
    }

}

/// Resolves a checkpoint to the workflow that should run, or the reason no workflow should run.
protocol CheckpointWorkflowResolver: AnyObject {

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution

}

final class DisabledCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        return .noAction(.disabled)
    }

}

/// Resolves checkpoints through the ordered rules served by the `checkpoint_rules` remote-config topic, taking
/// the first rule whose audience the customer matches.
///
/// The matched rule's workflow body is read first, because its shape decides what else the rule needs: a
/// workflow whose only step is a terminal `offering` step is handed back to the app as an offering, with
/// nothing presented, while every other workflow keeps resolving its offering through the workflows topic
/// and is presented as before.
///
/// The match is final either way. A matched rule that turns out to be unservable resolves to
/// ``CheckpointResolutionReason/configurationUnavailable`` instead of falling through to a rule this
/// customer wasn't the first choice for.
final class DefaultCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    private let checkpointsConfigProvider: CheckpointsConfigProviderType
    private let audiencesConfigProvider: AudiencesConfigProviderType
    private let localRulesEvaluator: LocalRulesEvaluator
    private let workflowManager: WorkflowManager
    private let offeringsProvider: (String) async throws -> Offerings
    private let currentUserProvider: any CurrentUserProvider

    init(
        checkpointsConfigProvider: CheckpointsConfigProviderType,
        audiencesConfigProvider: AudiencesConfigProviderType,
        localRulesEvaluator: LocalRulesEvaluator,
        workflowManager: WorkflowManager,
        offeringsProvider: @escaping (String) async throws -> Offerings,
        currentUserProvider: any CurrentUserProvider
    ) {
        self.checkpointsConfigProvider = checkpointsConfigProvider
        self.audiencesConfigProvider = audiencesConfigProvider
        self.localRulesEvaluator = localRulesEvaluator
        self.workflowManager = workflowManager
        self.offeringsProvider = offeringsProvider
        self.currentUserProvider = currentUserProvider
    }

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        #if DEBUG
        // Temporary CheckpointTester escape hatch. Config-backed resolution has no natural throwing case yet.
        if identifier == Self.simulatedErrorCheckpointIdentifier {
            throw ErrorUtils.configurationError(
                message: "Simulated error: checkpoint workflow not presentable."
            )
        }
        #endif

        return try await self.resolveConfiguredWorkflow(identifier: identifier, params: params)
    }

    private func resolveConfiguredWorkflow(
        identifier: String,
        params: CheckpointParams
    ) async throws -> CheckpointResolution {
        // The audience walk suspends, so pin the customer the offerings are loaded for too.
        let appUserID = self.currentUserProvider.currentAppUserID
        let rulesSnapshot: CheckpointRulesSnapshot
        do {
            guard let snapshot = try await self.checkpointsConfigProvider.rules(for: identifier) else {
                return .noAction(.unknownCheckpoint)
            }
            rulesSnapshot = snapshot
        } catch let error as CancellationError {
            throw error
        } catch CheckpointRulesProviderError.remoteConfigDisabled {
            return .noAction(.disabled)
        } catch {
            return .noAction(.configurationUnavailable)
        }

        let rule: CheckpointRule?
        do {
            rule = try await self.matchingRule(
                in: rulesSnapshot.ruleSet.rules,
                params: params,
                appUserID: appUserID
            )
        } catch let error as CancellationError {
            throw error
        } catch {
            // An audience the SDK failed to evaluate is not the same answer as an audience the customer is
            // outside of, so this can't report `noMatch`.
            Logger.error(Strings.remoteConfig.checkpointAudiencesNotEvaluated(
                checkpointID: identifier,
                reason: "\(error)"
            ))
            return .noAction(.configurationUnavailable)
        }

        // Audiences are read live rather than pinned to this snapshot, so a refresh landing mid-walk leaves
        // the match built from config that is already gone.
        if let outdated = self.outdated(rulesSnapshot, appUserID: appUserID) {
            return .noAction(outdated)
        }

        // The offering mapping is resolved per branch now, since only a UI workflow needs it.
        guard let rule else { return .noAction(.noMatch) }

        let resolution = await self.resolve(rule, appUserID: appUserID)
        if let outdated = self.outdated(rulesSnapshot, appUserID: appUserID) {
            return .noAction(outdated)
        }

        return resolution
    }

    /// Why an answer worked out during the awaits above no longer describes the world it will be
    /// delivered into, or `nil` when it still does. `noMatch` is an answer too, so it is checked.
    private func outdated(
        _ rulesSnapshot: CheckpointRulesSnapshot,
        appUserID: String
    ) -> CheckpointResolutionReason? {
        if !self.checkpointsConfigProvider.isCurrent(rulesSnapshot) {
            return .configurationUnavailable
        }
        if self.currentUserProvider.currentAppUserID != appUserID {
            return .customerChanged
        }
        return nil
    }

    /// Walks the served rules in priority order and returns the first one whose audience matches.
    private func matchingRule(
        in rules: [CheckpointRule],
        params: CheckpointParams,
        appUserID: String
    ) async throws -> CheckpointRule? {
        return try await self.localRulesEvaluator.match(
            in: rules,
            // Already filtered to valid keys by `DimensionResolver`, which exposes them under `custom.*`.
            customVariables: params.customVariables.mapValues(\.dimensionValue),
            appUserID: appUserID
        ) { rule in
            guard let audience = await self.audiencesConfigProvider.getAudience(rule.audienceId) else {
                throw AudienceUnavailableError(audienceID: rule.audienceId)
            }

            return audience.rules
        }
    }

    private func offeringID(for rule: CheckpointRule) async -> String? {
        let offeringIdByWorkflowId = await self.workflowManager.offeringIdByWorkflowId()
        guard let offeringID = offeringIdByWorkflowId[rule.workflowId] ?? nil else {
            Logger.warn(Strings.remoteConfig.checkpointWorkflowRuleSkipped(
                workflowID: rule.workflowId,
                reason: "no offering identifier is configured"
            ))
            return nil
        }
        return offeringID
    }

    private func loadOfferings(for appUserID: String) async -> Offerings? {
        do {
            return try await self.offeringsProvider(appUserID)
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }

    private func resolve(_ rule: CheckpointRule, appUserID: String) async -> CheckpointResolution {
        // Deliberately the non-prewarming read: an offering workflow renders nothing, and prewarming takes
        // its fonts from `uiConfig` rather than from the workflow's screens, so it isn't free here.
        let workflowData: WorkflowDataResult
        do {
            workflowData = try await self.workflowManager.workflowData(workflowId: rule.workflowId)
        } catch {
            return Self.unservable(rule, reason: error.localizedDescription)
        }

        let workflow = workflowData.workflow
        guard let initialStep = workflow.steps[workflow.initialStepId] else {
            return Self.unservable(rule, reason: "its initial step was not found")
        }

        if initialStep.type == Self.offeringStepType {
            guard workflow.steps.count == 1 else {
                return Self.unservable(rule, reason: "an offering step cannot be mixed with other steps")
            }
            return await self.resolveOffering(rule, step: initialStep, appUserID: appUserID)
        }

        if workflow.steps.values.contains(where: { $0.type == Self.offeringStepType }) {
            return Self.unservable(rule, reason: "a UI workflow cannot contain offering steps")
        }

        return await self.resolveWorkflow(rule, workflowData: workflowData, appUserID: appUserID)
    }

    /// Serves a workflow whose only step is a terminal `offering` step as an offering the app owns.
    ///
    /// Only the offering identifier is validated. Anything else the step happens to carry is ignored rather
    /// than treated as unservable, since a step of this kind renders nothing.
    private func resolveOffering(
        _ rule: CheckpointRule,
        step: WorkflowStep,
        appUserID: String
    ) async -> CheckpointResolution {
        guard case let .string(offeringID)? = step.paramValues[Self.offeringIdentifierParam],
              offeringID.isNotEmpty else {
            return Self.unservable(rule, reason: "the offering step has no valid offering identifier")
        }
        guard let match = await self.offering(identifier: offeringID, for: rule, appUserID: appUserID) else {
            return .noAction(.configurationUnavailable)
        }

        return .matchedOffering(match.offering)
    }

    private func resolveWorkflow(
        _ rule: CheckpointRule,
        workflowData: WorkflowDataResult,
        appUserID: String
    ) async -> CheckpointResolution {
        guard let offeringID = await self.offeringID(for: rule),
              let match = await self.offering(identifier: offeringID, for: rule, appUserID: appUserID) else {
            return .noAction(.configurationUnavailable)
        }

        self.workflowManager.scheduleAssetPrewarming(for: workflowData)

        return .matchedWorkflow(
            ResolvedCheckpointWorkflow(
                workflow: workflowData.workflow,
                uiConfig: workflowData.uiConfig,
                offering: match.offering,
                offerings: match.offerings
            )
        )
    }

    /// Loads the offerings and picks `identifier` out of them, logging why the rule can't be served when it
    /// isn't there. Both resolution paths need the offering and the container it came from.
    private func offering(
        identifier: String,
        for rule: CheckpointRule,
        appUserID: String
    ) async -> (offering: Offering, offerings: Offerings)? {
        guard let offerings = await self.loadOfferings(for: appUserID) else { return nil }
        guard let offering = offerings.offering(identifier: identifier) else {
            Self.unservable(rule, reason: "offering '\(identifier)' is unavailable")
            return nil
        }

        return (offering, offerings)
    }

    @discardableResult
    private static func unservable(_ rule: CheckpointRule, reason: String) -> CheckpointResolution {
        Logger.warn(Strings.remoteConfig.checkpointWorkflowRuleSkipped(
            workflowID: rule.workflowId,
            reason: reason
        ))
        return .noAction(.configurationUnavailable)
    }

    private static let offeringStepType = "offering"
    private static let offeringIdentifierParam = "offering_identifier"

    #if DEBUG
    private static let simulatedErrorCheckpointIdentifier = "error_checkpoint"
    #endif

}

/// An audience referenced by a checkpoint rule that the SDK couldn't read, so the rule can't be evaluated.
private struct AudienceUnavailableError: Error, CustomStringConvertible {

    let audienceID: String

    var description: String {
        return "audience '\(self.audienceID)' could not be read"
    }

}
