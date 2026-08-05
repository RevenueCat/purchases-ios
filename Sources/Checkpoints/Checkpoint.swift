//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoint.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Parameters passed from RevenueCatUI into the checkpoint engine.
@_spi(Internal) public struct CheckpointEngineParams {

    public let customProperties: [String: Any]

    public init(customProperties: [String: Any]) {
        self.customProperties = customProperties
    }

}

/// Checkpoint information used across the RevenueCat and RevenueCatUI module boundary.
@_spi(Internal) public struct CheckpointEngineInfo {

    public let identifier: String
    public let params: CheckpointEngineParams

    public init(identifier: String, params: CheckpointEngineParams) {
        self.identifier = identifier
        self.params = params
    }

}

/// Internal representation of why a checkpoint did not run anything.
@_spi(Internal) public struct CheckpointEngineNoActionReason: Equatable, Sendable {

    public let value: String

    public static let noMatch = Self(value: "NO_MATCH")
    public static let holdout = Self(value: "HOLDOUT")
    public static let frequencyCapped = Self(value: "FREQUENCY_CAPPED")
    public static let configurationUnavailable = Self(value: "CONFIGURATION_UNAVAILABLE")
    public static let disabled = Self(value: "DISABLED")

    public init(value: String) {
        self.value = value
    }

}

/// Internal checkpoint result returned to RevenueCatUI for conversion into its public result hierarchy.
@_spi(Internal) public enum CheckpointEngineResult {

    case paywallPresented(checkpoint: CheckpointEngineInfo, outcome: CheckpointEnginePaywallOutcome)
    case noAction(checkpoint: CheckpointEngineInfo, reason: CheckpointEngineNoActionReason)

    public var checkpoint: CheckpointEngineInfo {
        switch self {
        case let .paywallPresented(checkpoint, _), let .noAction(checkpoint, _):
            return checkpoint
        }
    }

}

/// Internal terminal result of a checkpoint-presented paywall.
@_spi(Internal) public enum CheckpointEnginePaywallOutcome {

    case dismissed
    case purchased(CustomerInfo)
    case restored(CustomerInfo)
    case error(PublicError)

}

/// Input supplied by the core checkpoint engine to RevenueCatUI for presentation.
@_spi(Internal) public class CheckpointEnginePresentation {

    public let checkpoint: CheckpointEngineInfo

    public init(checkpoint: CheckpointEngineInfo) {
        self.checkpoint = checkpoint
    }

}

/// Presentation capability supplied directly by RevenueCatUI when a checkpoint API is called.
@MainActor
@_spi(Internal) public protocol CheckpointEnginePresenter: AnyObject {

    func present(
        callID: String,
        presentation: CheckpointEnginePresentation,
        delegate: CheckpointEnginePresenterDelegate
    )

}

/// Receives terminal results from the RevenueCatUI presenter.
@_spi(Internal) public protocol CheckpointEnginePresenterDelegate: AnyObject {

    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointEnginePaywallOutcome)

}

/// Receives checkpoint engine events for conversion into the RevenueCatUI public listener API.
@_spi(Internal) public protocol CheckpointEngineListener: AnyObject {

    func onCheckpointHit(_ checkpoint: CheckpointEngineInfo)
    func onCheckpointResolved(_ checkpoint: CheckpointEngineInfo, result: CheckpointEngineResult)
    func onCheckpointPaywallFinished(
        _ checkpoint: CheckpointEngineInfo,
        outcome: CheckpointEnginePaywallOutcome
    )

}
