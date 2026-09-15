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
    static let adUnitIdParam = "ad_unit_id"
    static let mediatorParam = "mediator"

    /// Serves a workflow whose only step is a terminal `ad` step as an ad the app owns.
    ///
    /// Only `ad_unit_id` and `mediator` are validated. Anything else the step happens to carry is ignored
    /// rather than treated as unservable, since a step of this kind renders nothing.
    static func resolveAd(_ rule: CheckpointRule, step: WorkflowStep) -> CheckpointResolution {
        guard let adUnitId = Self.stringParam(Self.adUnitIdParam, in: step), !adUnitId.isEmpty else {
            return Self.unservable(rule, reason: "the ad step has no valid ad unit identifier")
        }
        guard let mediator = Self.stringParam(Self.mediatorParam, in: step), !mediator.isEmpty else {
            return Self.unservable(rule, reason: "the ad step has no valid mediator")
        }

        return .matchedAd(ResolvedAdStep(adUnitId: adUnitId, mediator: MediatorName(rawValue: mediator)))
    }

    static func stringParam(_ key: String, in step: WorkflowStep) -> String? {
        guard case let .string(value)? = step.paramValues[key] else { return nil }
        return value
    }

}
