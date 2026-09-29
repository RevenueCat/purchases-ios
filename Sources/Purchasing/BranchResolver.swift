//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BranchResolver.swift
//
//  Created by RevenueCat.

import Foundation

/// Decides where a `branch` trigger action sends someone.
///
/// The return is not optional. There is always a `fallbackStepId`, so navigation is never blocked.
@_spi(Internal) public protocol BranchResolver: AnyObject {

    /// - Returns: the step the branch routes to.
    func resolve(_ branch: WorkflowBranch) async -> String

}

extension BranchResolver {

    /// The branches a step can exit through, keyed by action id.
    func resolveBranches(in step: WorkflowStep) async -> [String: String] {
        var resolved: [String: String] = [:]
        for (actionId, action) in step.stepTriggerActions {
            guard !Task.isCancelled else { return resolved }
            guard case .branch(let branch) = action else { continue }
            resolved[actionId] = await self.resolve(branch)
        }
        return resolved
    }

}

/// Every branch takes its fallback. Goes away with `branchingEnabled` once branching ships.
@_spi(Internal) public final class DisabledBranchResolver: BranchResolver {

    /// Creates the resolver used while branching is unreleased.
    @_spi(Internal) public init() {}

    /// - Returns: the branch's `fallbackStepId`, always.
    @_spi(Internal) public func resolve(_ branch: WorkflowBranch) async -> String {
        return branch.fallbackStepId
    }

}

/// Resolves audiences in order and returns the first match.
final class DefaultBranchResolver: BranchResolver {

    private let audiencesConfigProvider: AudiencesConfigProviderType
    private let localRulesEvaluator: LocalRulesEvaluator

    init(
        audiencesConfigProvider: AudiencesConfigProviderType,
        localRulesEvaluator: LocalRulesEvaluator
    ) {
        self.audiencesConfigProvider = audiencesConfigProvider
        self.localRulesEvaluator = localRulesEvaluator
    }

    func resolve(_ branch: WorkflowBranch) async -> String {
        guard !branch.branches.isEmpty else { return branch.fallbackStepId }

        do {
            return try await self.route(branch) ?? branch.fallbackStepId
        } catch is CancellationError {
            // The step was left before this finished, so there is nothing to report.
            return branch.fallbackStepId
        } catch {
            Logger.error(Strings.remoteConfig.branchRoutedToFallback(reason: String(describing: error)))
            return branch.fallbackStepId
        }
    }

    /// The step the first matching audience picks, or `nil` when none matched.
    private func route(_ branch: WorkflowBranch) async throws -> String? {
        // One snapshot for the whole walk, so a config swap midway cannot mix two generations.
        guard let audiences = try await self.audiencesConfigProvider.configuration()?.audiences else {
            throw BranchResolutionError.noAudienceConfiguration
        }

        let unreadable = Atomic<[String]>([])
        let matched = try await self.localRulesEvaluator.match(in: branch.branches) { route in
            guard let audience = audiences[route.audienceId] else {
                unreadable.modify { $0.append(route.audienceId) }
                return Self.neverMatches
            }
            return audience.rules
        }

        // Reported even when a later audience matched, otherwise a route that silently stopped firing
        // leaves no trace at all.
        if !unreadable.value.isEmpty {
            Logger.error(Strings.remoteConfig.branchRoutedToFallback(
                reason: String(describing: BranchResolutionError.unreadableAudiences(unreadable.value))
            ))
        }
        return matched?.stepId
    }

}

private enum BranchResolutionError: Error, CustomStringConvertible {

    case noAudienceConfiguration
    case unreadableAudiences([String])

    var description: String {
        switch self {
        case .noAudienceConfiguration:
            return "no audience configuration"
        case .unreadableAudiences(let identifiers):
            return "could not read \(identifiers.joined(separator: ", "))"
        }
    }

}

private extension DefaultBranchResolver {

    /// Stands in for an audience we could not read. Thrown resolution would end the walk, and one
    /// unreadable audience must not stop a later one from winning, so it never matches instead.
    static let neverMatches = #"{"==": [1, 0]}"#

}
