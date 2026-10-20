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

@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, *)
public extension Purchases {

    /// The custom presenter used when a checkpoint selects an offering.
    ///
    /// This presenter is used when the individual
    /// ``checkpoint(_:customVariables:presentationMode:paywallPresenter:errorPresenter:_:)`` call does not provide a
    /// `paywallPresenter` closure. A closure passed to a checkpoint call overrides this presenter for that call. Set
    /// this property to `nil` to use the default paywall presenter.
    @MainActor
    var paywallPresenter: PaywallPresenter? {
        get { return self.checkpointsManager.paywallPresenter }
        set { self.checkpointsManager.setPaywallPresenter(newValue) }
    }

    /// The custom presenter used when the SDK presents a checkpoint error, including failures before a flow is shown.
    ///
    /// This presenter is used when the individual
    /// ``checkpoint(_:customVariables:presentationMode:paywallPresenter:errorPresenter:_:)`` call does not provide an
    /// `errorPresenter` closure. A closure passed to a checkpoint call overrides this presenter for that call. When
    /// neither is set, the SDK handles error presentation by default. A checkpoint call made while another checkpoint
    /// flow owns presentation is ignored without invoking an error presenter.
    @MainActor
    var errorPresenter: ErrorPresenter? {
        get { return self.checkpointsManager.errorPresenter }
        set { self.checkpointsManager.setErrorPresenter(newValue) }
    }

    /// Passes a checkpoint and calls `onPassed` when the app can continue past it.
    ///
    /// The callback receives a result with an optional flow result and the customer's information. The flow result is
    /// `nil` when the checkpoint had nothing to present: it is not configured, or no rule matched. A completed flow
    /// reports the entitlements and products obtained while it was presented. The customer's information is always
    /// included: synced with what they obtained when the flow ended with a purchase or restore, the latest known
    /// otherwise. If post-flow synchronization fails, the SDK presents the error before calling back with the latest
    /// known information. The callback is not called if the checkpoint could not be served (this includes the cases
    /// where the customer's information could not be read), if another checkpoint flow already owns presentation, or
    /// if the user backs out.
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard. It must start with a letter,
    ///     contain only ASCII letters, numbers, underscores, and hyphens, and be no more than 255 characters.
    ///   - customVariables: Values usable in checkpoint targeting rules, feature events, and the presented flow.
    ///   - presentationMode: How the SDK presents a matching workflow or its own paywall. Defaults to a sheet.
    ///   - paywallPresenter: A custom presenter used if this checkpoint selects an offering. This overrides the global
    ///     ``paywallPresenter`` for this call.
    ///   - errorPresenter: A custom presenter used when the SDK presents errors from this checkpoint, including
    ///     failures before a flow is presented. This overrides the global ``errorPresenter`` for this call.
    ///   - onPassed: Called on the main actor when the checkpoint passes.
    func checkpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        presentationMode: FlowPresentationMode = .default,
        paywallPresenter: PaywallPresentationHandler? = nil,
        errorPresenter: ErrorPresentationHandler? = nil,
        _ onPassed: @escaping (CheckpointResult) -> Void
    ) {
        let params = CheckpointCallParams(
            customVariables: customVariables,
            presentationMode: presentationMode,
            paywallPresenter: paywallPresenter,
            errorPresenter: errorPresenter
        )
        self.performCheckpoint(identifier, params: params, onPassed: onPassed)
    }

}

@available(iOS 15.0, *)
private extension Purchases {

    func performCheckpoint(
        _ identifier: String,
        params: CheckpointCallParams,
        onPassed: @escaping (CheckpointResult) -> Void
    ) {
        Task { @MainActor in
            switch await self.checkpointsManager.checkpointForCallback(
                identifier: identifier,
                params: params
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
            customerInfoProvider: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await self.customerInfo(fetchPolicy: .cachedOrFetched)
            },
            cachedCustomerInfoProvider: { [weak self] in self?.cachedCustomerInfo },
            preferredUILocaleProvider: { [weak self] in self?.preferredLocaleOverride },
            customerInfoSynchronizer: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await self.syncPurchases()
            }
        )
    }

}

#endif
