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

private final class CheckpointListenerAPITester: CheckpointListener {

    func onCheckpointHit(_ context: CheckpointContext.Hit) {
        let _: CheckpointContext = context
        let _: String = context.identifier
        let _: [String: CustomVariableValue] = context.customVariables
    }

    func onCheckpointCompleted(_ context: CheckpointContext.Completed) {
        let _: CheckpointContext = context
        let _: String = context.identifier
        let _: [String: CustomVariableValue] = context.customVariables
        let result: CheckpointResult = context.result

        if let presented = result as? CheckpointResult.PaywallPresented {
            let outcome: CheckpointPaywallOutcome = presented.paywallOutcome

            if let purchased = outcome as? CheckpointPaywallOutcome.Purchased {
                let _: StoreTransaction? = purchased.transaction
                let _: CustomerInfo = purchased.customerInfo
            } else if let restored = outcome as? CheckpointPaywallOutcome.Restored {
                let _: CustomerInfo = restored.customerInfo
            } else if let finished = outcome as? CheckpointPaywallOutcome.Finished {
                let _: CustomerInfo = finished.customerInfo
            } else if let failed = outcome as? CheckpointPaywallOutcome.Error {
                let _: PublicError = failed.error
            } else if outcome is CheckpointPaywallOutcome.WebCheckoutOpened {
                let _: String = outcome.description
            } else {
                let _: Bool = outcome is CheckpointPaywallOutcome.Dismissed
            }

            let _: String = outcome.description
        } else if let receivedOffering = result as? CheckpointResult.ReceivedOffering {
            let _: Offering = receivedOffering.offering
        } else if let noAction = result as? CheckpointResult.NoAction {
            let _: CheckpointNoActionReason = noAction.reason
            let _: String = noAction.reason.description
        }
    }

}

private final class CheckpointListenerDefaultsAPITester: CheckpointListener {}

@MainActor
private final class CheckpointPaywallPresenterAPITester: CheckpointPaywallPresenter {

    func present(offering: Offering, completion: CheckpointPaywallCompletion) throws {
        let _: Offering = offering
        let _: CheckpointPaywallCompletion = completion
        completion.finished()
        completion.failed()
    }

}

@MainActor
func checkCheckpointAPI(_ purchases: Purchases) {
    purchases.checkpointListener = CheckpointListenerAPITester()
    let _: CheckpointListener? = purchases.checkpointListener

    purchases.checkpointPaywallPresenter = CheckpointPaywallPresenterAPITester()
    let _: CheckpointPaywallPresenter? = purchases.checkpointPaywallPresenter
    purchases.checkpointPaywallPresenter = nil

    purchases.checkpoint(
        "test_checkpoint",
        paywallPresenter: CheckpointPaywallPresenterAPITester()
    ) { (_: CheckpointGateResult) in }

    Task {
        let _: CheckpointGateResult = await purchases.checkpoint(
            "test_checkpoint",
            paywallPresenter: CheckpointPaywallPresenterAPITester()
        )
    }

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
    ) { (result: CheckpointGateResult) in
        let _: [EntitlementGrant] = result.entitlements
        let _: CheckpointNoActionReason? = result.noActionReason
        let _: PublicError? = result.error
    }

    purchases.checkpoint("test_checkpoint") { (_: CheckpointGateResult) in }

    Task {
        let _: CheckpointGateResult = await purchases.checkpoint(
            "test_checkpoint",
            customVariables: explicitCustomVariables
        )
    }

    let _: CheckpointNoActionReason = .noMatch
    let _: CheckpointNoActionReason = .holdout
    let _: CheckpointNoActionReason = .frequencyCapped
    let _: CheckpointNoActionReason = .configurationUnavailable
    let _: CheckpointNoActionReason = .unknownCheckpoint
    let _: CheckpointNoActionReason = .invalidCheckpointIdentifier
}
