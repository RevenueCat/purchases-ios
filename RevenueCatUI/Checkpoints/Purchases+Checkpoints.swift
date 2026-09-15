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

    /// The custom presenter used when a checkpoint selects an offering.
    ///
    /// This presenter is used when the individual ``checkpoint(_:customVariables:paywallPresenter:_:)`` call does not
    /// provide a `paywallPresenter` closure. A closure passed to a checkpoint call overrides this presenter for that
    /// call. Set this property to `nil` to use the default paywall presenter.
    @MainActor
    var paywallPresenter: PaywallPresenter? {
        get { return self.checkpointsManager.paywallPresenter }
        set { self.checkpointsManager.setPaywallPresenter(newValue) }
    }

    /// The presenter used when a checkpoint selects an ad step.
    ///
    /// Set this to let an ad mediator adapter register itself so a resolved ad step displays an ad
    /// automatically, with no per-checkpoint app code. Unlike ``paywallPresenter``, there is no built-in
    /// RevenueCat-managed UI for ads: a checkpoint that resolves to an ad step with no presenter registered
    /// presents nothing.
    @MainActor
    var adPresenter: AdPresenter? {
        get { return self.checkpointsManager.adPresenter }
        set { self.checkpointsManager.setAdPresenter(newValue) }
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
    ///   - paywallPresenter: A custom presenter used if this checkpoint selects an offering. This overrides the global
    ///     ``paywallPresenter`` for this call.
    ///   - onPassed: Called on the main actor when the checkpoint completes.
    func checkpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        paywallPresenter: PaywallPresentationHandler? = nil,
        _ onPassed: @escaping (FlowResult?) -> Void
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
        onPassed: @escaping (FlowResult?) -> Void
    ) {
        Task { @MainActor in
            switch await self.checkpointsManager.checkpointForCallback(
                identifier: identifier,
                params: .init(customVariables: customVariables, paywallPresenter: paywallPresenter)
            ) {
            case let .completed(result): onPassed(result)
            case .suppressed: break
            }
        }
    }

    @MainActor
    var checkpointsManager: CheckpointsManager {
        return self.getOrCreateCheckpointsManager {
            self.createCheckpointsManager()
        }
    }

    @MainActor
    func createCheckpointsManager() -> CheckpointsManager {
        return CheckpointsManager(
            resolveCheckpoint: { [weak self] identifier, params in
                guard let self else {
                    throw CancellationError()
                }

                return try await self.resolveCheckpoint(identifier: identifier, params: params.coreParams)
            },
            cachedCustomerInfoProvider: { [weak self] in self?.cachedCustomerInfo },
            customerInfoSynchronizer: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await self.syncPurchases()
            }
        )
    }

}

#endif
