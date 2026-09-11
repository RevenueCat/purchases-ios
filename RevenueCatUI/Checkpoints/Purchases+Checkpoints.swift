//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+Checkpoints.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS) && !targetEnvironment(macCatalyst)

@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
public extension Purchases {

    /// Presents checkpoint-selected paywalls using a custom presenter.
    @MainActor
    var checkpointPaywallPresenter: PaywallPresenter? {
        get { return self.checkpointsManager.paywallPresenter }
        set { self.checkpointsManager.setPaywallPresenter(newValue) }
    }

    /// Passes a checkpoint without observing its completion.
    ///
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard. It must start with a letter,
    ///     contain only ASCII letters, numbers, underscores, and hyphens, and be no more than 255 characters.
    ///   - customVariables: Values usable in checkpoint targeting rules, feature events, and the presented flow.
    ///   - paywallPresenter: A custom presenter used if this checkpoint selects an offering. This overrides
    ///     ``checkpointPaywallPresenter`` for this call.
    func checkpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        paywallPresenter: PaywallPresentationHandler? = nil
    ) {
        self.performCheckpoint(
            identifier,
            customVariables: customVariables,
            paywallPresenter: paywallPresenter,
            onPassed: nil
        )
    }

    /// Passes a checkpoint and calls `onPassed` after a matching flow finishes.
    ///
    /// The callback receives `nil` when the checkpoint has no matching flow or the flow cannot complete. If the user
    /// backs out of the workflow, the callback is not called. A completed flow returns a result that may contain
    /// entitlements obtained while it was presented.
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard. It must start with a letter,
    ///     contain only ASCII letters, numbers, underscores, and hyphens, and be no more than 255 characters.
    ///   - customVariables: Values usable in checkpoint targeting rules, feature events, and the presented flow.
    ///   - paywallPresenter: A custom presenter used if this checkpoint selects an offering. This overrides
    ///     ``checkpointPaywallPresenter`` for this call.
    ///   - onPassed: Called when the checkpoint completes.
    func checkpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        paywallPresenter: PaywallPresentationHandler? = nil,
        _ onPassed: @escaping (CheckpointFlowResult?) -> Void
    ) {
        self.performCheckpoint(
            identifier,
            customVariables: customVariables,
            paywallPresenter: paywallPresenter,
            onPassed: onPassed
        )
    }

}

@available(iOS 15.0, *)
private extension Purchases {

    func performCheckpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue],
        paywallPresenter: PaywallPresentationHandler?,
        onPassed: ((CheckpointFlowResult?) -> Void)?
    ) {
        Task { @MainActor in
            switch await self.checkpointsManager.checkpointForCallback(
                identifier: identifier,
                params: .init(customVariables: customVariables, paywallPresenter: paywallPresenter)
            ) {
            case let .completed(result): onPassed?(result)
            case .suppressed: break
            }
        }
    }

    var checkpointsManager: CheckpointsManager {
        return self.getOrCreateCheckpointsManager {
            self.createCheckpointsManager()
        }
    }

    func createCheckpointsManager() -> CheckpointsManager {
        return CheckpointsManager(
            resolveCheckpoint: { [weak self] identifier, params in
                guard let self else { throw CancellationError() }
                return try await self.resolveCheckpoint(identifier: identifier, params: params.coreParams)
            },
            fetchCustomerInfo: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await self.customerInfo(fetchPolicy: .fetchCurrent)
            }
        )
    }

}

#endif
