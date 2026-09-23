//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointAPI.swift
//
//  Created by Rick van der Linden.
//

import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI

func checkCheckpointAPI(_ purchases: Purchases) {
    let literalCustomVariables: [String: CustomVariableValue] = [
        "name": "Rick",
        "points": 120,
        "score": 4.5,
        "subscriber": true
    ]
    let explicitCustomVariables: [String: CustomVariableValue] = [
        "name": .string("Rick"),
        "points": .number(120),
        "score": .number(4.5),
        "subscriber": .bool(true)
    ]

    purchases.checkpoint(
        "test_checkpoint",
        customVariables: literalCustomVariables
    ) { (_: FlowResult?) in }

    purchases.checkpoint("test_checkpoint") { (_: FlowResult?) in }
    purchases.checkpoint("test_checkpoint", customVariables: explicitCustomVariables) { _ in }

    let entitlement: ObtainedEntitlement? = nil
    let _: EntitlementInfo? = entitlement?.entitlementInfo
    let result: FlowResult? = nil
    let _: Set<ObtainedEntitlement>? = result?.obtainedEntitlements
}

@MainActor
private func checkPaywallPresentationAPI(
    _ purchases: Purchases
) {
    let globalPresenter = CheckpointAPIPaywallPresenter()
    purchases.paywallPresenter = globalPresenter
    let _: PaywallPresenter? = purchases.paywallPresenter

    let presenter: PaywallPresentationHandler = { params, completion in
        let _: String = params.checkpointIdentifier
        let _: [String: CustomVariableValue] = params.customVariables
        let _: Offering = params.offering
        completion(.continued)
    }

    purchases.checkpoint("test_checkpoint", paywallPresenter: presenter) { _ in }

    let _: PaywallPresentationResult = .continued
    let _: PaywallPresentationResult = .closed
    let _: PaywallPresentationResult = .navigatedBack
}

@MainActor
private final class CheckpointAPIPaywallPresenter: PaywallPresenter {

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        completion(.continued)
    }

}

@MainActor
private func checkAdPresentationAPI(
    _ purchases: Purchases
) {
    let presenter = CheckpointAPIAdPresenter()
    purchases.adPresenter = presenter
    let _: AdPresenter? = purchases.adPresenter

    let error: PublicError = NSError(domain: "", code: 0)
    let _: AdPresentationResult = .shown
    let _: AdPresentationResult = .rewarded(reward: .noReward)
    let _: AdPresentationResult = .rewarded(reward: .noReward, moreRewards: [.unsupportedReward])
    let _: AdPresentationResult = .rewardVerificationFailed
    let _: AdPresentationResult = .failed(error: error)
    let _: Bool = AdPresentationResult.shown == AdPresentationResult.shown
}

@MainActor
private final class CheckpointAPIAdPresenter: AdPresenter {

    func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        let _: String = params.checkpointIdentifier
        let _: [String: CustomVariableValue] = params.customVariables
        let _: String = params.adIdentifier
        let _: MediatorName = params.mediator
        completion(.shown)
    }

}
