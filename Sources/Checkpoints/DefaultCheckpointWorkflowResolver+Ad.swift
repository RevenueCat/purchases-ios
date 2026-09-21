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

    /// Serves a workflow whose only step is a terminal `ad` step as an ad the app owns.
    ///
    /// Only `ad_identifier` and `mediator` are validated. Anything else the step happens to carry is ignored
    /// rather than treated as unservable, since a step of this kind renders nothing.
    static func resolveAd(_ rule: CheckpointRule, step: WorkflowStep) -> CheckpointResolution {
        guard let adIdentifier = Self.stringParam(Self.adIdentifierParam, in: step), !adIdentifier.isEmpty else {
            return Self.unservable(rule, reason: "the ad step has no valid ad identifier")
        }
        guard let mediator = Self.stringParam(Self.mediatorParam, in: step), !mediator.isEmpty else {
            return Self.unservable(rule, reason: "the ad step has no valid mediator")
        }

        return .matchedAd(ResolvedAdStep(adIdentifier: adIdentifier, mediator: Self.normalizedMediator(mediator)))
    }

    static func stringParam(_ key: String, in step: WorkflowStep) -> String? {
        guard case let .string(value)? = step.paramValues[key] else { return nil }
        return value
    }

    /// The backend serializes mediators in lowercase (`admob`) while the SDK's canonical constants are
    /// mixed case (`AdMob`), and `MediatorName` equality is case-sensitive. Map known mediators onto their
    /// canonical instance so presenters can match on them; anything unknown passes through untouched.
    private static let knownMediators: [MediatorName] = [.adMob, .appLovin]

    private static func normalizedMediator(_ rawValue: String) -> MediatorName {
        return Self.knownMediators.first { known in
            known.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame
        } ?? MediatorName(rawValue: rawValue)
    }

}
