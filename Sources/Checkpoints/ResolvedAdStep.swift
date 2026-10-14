//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ResolvedAdStep.swift
//
//  Created by RevenueCat.

import Foundation

/// An ad step resolved for a checkpoint, with no RevenueCat-managed UI to present. A registered ad
/// presenter decides how to show it.
@_spi(Internal) public struct ResolvedAdStep: Equatable, Sendable {

    /// Identifies the ad to load for this step, in whatever form ``mediator`` expects (an AdMob ad unit id, for
    /// example).
    public let adIdentifier: String

    /// The mediation network configured to serve ``adIdentifier``.
    public let mediator: MediatorName

    /// The ad format ``adIdentifier`` was created for. Ads are format-locked, so a presenter must load
    /// this ad through the matching format's loader.
    public let adFormat: AdFormat

    /// The step to continue to once this ad has finished, however it finished. `nil` ends the workflow.
    public let nextStepId: String?

    /// Creates a resolved ad step.
    @_spi(Internal) public init(
        adIdentifier: String,
        mediator: MediatorName,
        adFormat: AdFormat,
        nextStepId: String? = nil
    ) {
        self.adIdentifier = adIdentifier
        self.mediator = mediator
        self.adFormat = adFormat
        self.nextStepId = nextStepId
    }

    /// The single trigger action an ad step chains from. Every ad outcome follows it, so the dashboard mints
    /// one connection per ad step, like an offering step's `on_offering`.
    @_spi(Internal) public static let triggerActionId = "on_ad"

}

/// An ad-only workflow resolved for a checkpoint: one or more ad steps presented in sequence, with no
/// RevenueCat-managed UI to present.
@_spi(Internal) public struct ResolvedAdWorkflow: Equatable, Sendable {

    /// The step to present first.
    public let initialStep: ResolvedAdStep

    /// Every step in the workflow, keyed by step id.
    public let steps: [String: ResolvedAdStep]

    /// Creates a resolved ad workflow.
    @_spi(Internal) public init(initialStep: ResolvedAdStep, steps: [String: ResolvedAdStep]) {
        self.initialStep = initialStep
        self.steps = steps
    }

    /// The step that follows `step`, or `nil` when `step` ends the workflow.
    public func nextStep(after step: ResolvedAdStep) -> ResolvedAdStep? {
        return step.nextStepId.flatMap { self.steps[$0] }
    }

}
