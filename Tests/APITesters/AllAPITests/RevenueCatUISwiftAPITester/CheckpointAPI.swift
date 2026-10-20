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
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI

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
    ) { (_: CheckpointResult) in }

    purchases.checkpoint("test_checkpoint") { (_: CheckpointResult) in }
    purchases.checkpoint("test_checkpoint", customVariables: explicitCustomVariables) { _ in }
    purchases.checkpoint("test_checkpoint", presentationMode: .modalFullScreen) { _ in }

    let _: FlowPresentationMode = .default
    let _: FlowPresentationMode = .modalFullScreen
    let _: FlowPresentationMode = .modalSheet

    let entitlement: ObtainedEntitlement? = nil
    let _: EntitlementInfo? = entitlement?.entitlementInfo
    let product: ObtainedProduct? = nil
    let _: StoreProduct? = product?.product
}

private func checkCheckpointResultAPI(_ result: CheckpointResult) {
    let _: FlowResult? = result.flow
    let _: CustomerInfo = result.customer
    let _: ObtainedEntitlement? = result.obtainedEntitlement("pro")
    let _: Bool = result.didObtainEntitlement("pro")
    let _: ObtainedProduct? = result.obtainedProduct("monthly")
    let _: Bool = result.didObtainProduct("monthly")
    let _: Bool = result.hasEntitlement("pro")
}

private func checkFlowResultAPI(_ result: FlowResult) {
    let _: Set<ObtainedEntitlement> = result.obtainedEntitlements
    let _: Set<ObtainedProduct> = result.obtainedProducts
    let _: ObtainedEntitlement? = result.obtainedEntitlement("pro")
    let _: Bool = result.didObtainEntitlement("pro")
    let _: ObtainedProduct? = result.obtainedProduct("monthly")
    let _: Bool = result.didObtainProduct("monthly")
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
        let _: FlowPresentationMode = params.presentationMode
        let _: Offering = params.offering
        completion(.continued)
    }

    purchases.checkpoint("test_checkpoint", paywallPresenter: presenter) { _ in }

    let _: PaywallPresentationResult = .continued
    let _: PaywallPresentationResult = .closed
    let _: PaywallPresentationResult = .navigatedBack
}

@MainActor
private func checkErrorPresentationAPI(_ purchases: Purchases) {
    let globalPresenter = CheckpointAPIErrorPresenter()
    purchases.errorPresenter = globalPresenter
    let _: ErrorPresenter? = purchases.errorPresenter

    let presenter: ErrorPresentationHandler = { params, completion in
        let _: String = params.checkpointIdentifier
        let _: any Error = params.error
        let _: [String: CustomVariableValue] = params.customVariables
        let _: CheckpointFailureKind = params.kind
        completion.complete()
    }

    let _: CheckpointFailureKind = .flowCouldNotBeShown
    let _: CheckpointFailureKind = .flowActionFailed
    let _: CheckpointFailureKind = .flowResultSyncFailed
    let _: ErrorPresentationHandler = presenter
    purchases.checkpoint("test_checkpoint", errorPresenter: presenter) { _ in }
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
private final class CheckpointAPIErrorPresenter: ErrorPresenter {

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        completion.complete()
    }

}
