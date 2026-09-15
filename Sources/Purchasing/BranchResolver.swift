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
@_spi(Internal) public protocol BranchResolver: Sendable {

    /// Returns the matching step, or the fallback when resolution fails.
    func resolve(_ branch: WorkflowBranch) async -> String

}

/// Used when remote config is off, so there is nothing to evaluate audiences against.
final class DisabledBranchResolver: BranchResolver {

    func resolve(_ branch: WorkflowBranch) async -> String {
        return branch.fallbackStepId
    }

}

/// Resolves audiences in order and returns the first match. Mirrors how checkpoint rules resolve
/// theirs, including the walk: a failure does not stop a later audience from winning.
final class DefaultBranchResolver: BranchResolver {

    private let audiencesConfigProvider: any AudiencesConfigProviderType & Sendable
    private let localRulesEvaluator: LocalRulesEvaluator

    init(
        audiencesConfigProvider: any AudiencesConfigProviderType & Sendable,
        localRulesEvaluator: LocalRulesEvaluator
    ) {
        self.audiencesConfigProvider = audiencesConfigProvider
        self.localRulesEvaluator = localRulesEvaluator
    }

    func resolve(_ branch: WorkflowBranch) async -> String {
        guard !branch.branches.isEmpty else { return branch.fallbackStepId }

        let unreadable = Atomic<[String]>([])

        do {
            guard let configuration = try await self.audiencesConfigProvider.configuration() else {
                return branch.fallbackStepId
            }
            let matched = try await self.localRulesEvaluator.match(in: branch.branches) { route in
                guard let audience = configuration.audiences[route.audienceId] else {
                    // Not thrown: `match` ends the walk on a resolution failure, and an audience we
                    // cannot read must not stop a later one from winning. Never matches instead.
                    unreadable.modify { $0.append(route.audienceId) }
                    return Self.neverMatches
                }

                return audience.rules
            }

            guard self.audiencesConfigProvider.isCurrent(configuration) else {
                return branch.fallbackStepId
            }
            if let matched { return matched.stepId }

            if !unreadable.value.isEmpty {
                Logger.error(Strings.remoteConfig.branchRoutedToFallback(
                    reason: "could not read \(unreadable.value.joined(separator: ", "))"
                ))
            }

            return branch.fallbackStepId
        } catch {
            // Nothing matched and something went wrong on the way. Logged because it is
            // indistinguishable from a clean non-match once we route.
            Logger.error(Strings.remoteConfig.branchRoutedToFallback(
                reason: String(describing: error)
            ))
            return branch.fallbackStepId
        }
    }

}

private extension DefaultBranchResolver {

    /// Stands in for an audience we could not read, so the walk continues to the next one.
    static let neverMatches = #"{"==": [1, 0]}"#

}
