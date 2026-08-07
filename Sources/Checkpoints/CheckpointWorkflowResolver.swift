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
    case workflow(ResolvedCheckpointWorkflow)
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

/// Resolves checkpoints through the ordered rules served by the `checkpoint_rules` remote-config topic.
///
/// Audience evaluation is not available yet. Until it is, the first rule supplied by the backend is treated as
/// the match.
final class DefaultCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    private let checkpointsConfigProvider: CheckpointsConfigProviderType
    private let workflowManager: WorkflowManager
    private let offeringsProvider: () async throws -> Offerings

    init(
        checkpointsConfigProvider: CheckpointsConfigProviderType,
        workflowManager: WorkflowManager,
        offeringsProvider: @escaping () async throws -> Offerings
    ) {
        self.checkpointsConfigProvider = checkpointsConfigProvider
        self.workflowManager = workflowManager
        self.offeringsProvider = offeringsProvider
    }

    func resolve(identifier: String, params _: CheckpointParams) async throws -> CheckpointResolution {
        #if DEBUG
        // Temporary CheckpointTester escape hatch. Config-backed resolution has no natural throwing case yet.
        if identifier == Self.simulatedErrorCheckpointIdentifier {
            throw ErrorUtils.configurationError(
                message: "Simulated error: checkpoint workflow not presentable."
            )
        }
        #endif

        return await self.resolveConfiguredWorkflow(identifier: identifier)
    }

    private func resolveConfiguredWorkflow(identifier: String) async -> CheckpointResolution {
        let ruleSet: CheckpointRuleSet
        do {
            guard let rules = try await self.checkpointsConfigProvider.rules(for: identifier) else {
                return .noAction(.noMatch)
            }
            ruleSet = rules
        } catch CheckpointRulesProviderError.remoteConfigDisabled {
            return .noAction(.disabled)
        } catch {
            return .noAction(.configurationUnavailable)
        }

        guard let rule = self.matchingRule(in: ruleSet.rules) else { return .noAction(.noMatch) }
        guard let offeringID = await self.offeringID(for: rule) else {
            return .noAction(.configurationUnavailable)
        }

        guard let offerings = await self.loadOfferings() else {
            return .noAction(.configurationUnavailable)
        }

        return await self.resolve(rule, offeringID: offeringID, offerings: offerings)
    }

    private func matchingRule(in rules: [CheckpointRule]) -> CheckpointRule? {
        // Audience rules will be evaluated here later. Until then, the first backend-ordered rule always matches.
        return rules.first
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

    private func loadOfferings() async -> Offerings? {
        do {
            return try await self.offeringsProvider()
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }

    private func resolve(
        _ rule: CheckpointRule,
        offeringID: String,
        offerings: Offerings
    ) async -> CheckpointResolution {
        guard let offering = offerings.offering(identifier: offeringID) else {
            Logger.warn(Strings.remoteConfig.checkpointWorkflowRuleSkipped(
                workflowID: rule.workflowId,
                reason: "offering '\(offeringID)' is unavailable"
            ))
            return .noAction(.configurationUnavailable)
        }

        do {
            let workflowData = try await self.workflowManager.getWorkflow(workflowId: rule.workflowId)
            return .workflow(
                ResolvedCheckpointWorkflow(
                    workflow: workflowData.workflow,
                    uiConfig: workflowData.uiConfig,
                    offering: offering,
                    offerings: offerings
                )
            )
        } catch {
            Logger.warn(Strings.remoteConfig.checkpointWorkflowRuleSkipped(
                workflowID: rule.workflowId,
                reason: error.localizedDescription
            ))
            return .noAction(.configurationUnavailable)
        }
    }

    #if DEBUG
    private static let simulatedErrorCheckpointIdentifier = "error_checkpoint"
    #endif

}
