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

    func onCheckpointHit(_ context: CheckpointHitContext) {
        let _: CheckpointContext = context
        let _: String = context.identifier
        let _: [String: CustomVariableValue] = context.customVariables
    }

    func onCheckpointCompleted(_ context: CheckpointCompletedContext) {
        let _: CheckpointContext = context
        let _: String = context.identifier
        let _: [String: CustomVariableValue] = context.customVariables
        let result: CheckpointResult = context.result

        if let presented = result as? CheckpointPaywallPresentedResult {
            let outcome: CheckpointPaywallOutcome = presented.paywallOutcome

            if let purchased = outcome as? CheckpointPaywallOutcome.Purchased {
                let _: StoreTransaction? = purchased.transaction
                let _: CustomerInfo = purchased.customerInfo
            } else if let restored = outcome as? CheckpointPaywallOutcome.Restored {
                let _: CustomerInfo = restored.customerInfo
            } else if let failed = outcome as? CheckpointPaywallOutcome.Error {
                let _: PublicError = failed.error
            } else if outcome is CheckpointPaywallOutcome.WebCheckoutOpened {
                let _: String = outcome.description
            } else {
                let _: Bool = outcome is CheckpointPaywallOutcome.Dismissed
            }

            let _: String = outcome.description
        } else if let receivedOffering = result as? CheckpointReceivedOfferingResult {
            let _: Offering = receivedOffering.offering
        } else if let noAction = result as? CheckpointNoActionResult {
            let _: CheckpointNoActionReason = noAction.reason
            let _: String = noAction.reason.description
        }
    }

}

private final class CheckpointListenerDefaultsAPITester: CheckpointListener {}

func checkCheckpointAPI(_ purchases: Purchases) {
    purchases.checkpointListener = CheckpointListenerAPITester()
    let _: CheckpointListener? = purchases.checkpointListener

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
    ) { (_: Result<CheckpointResult, PublicError>) in }

    purchases.checkpoint("test_checkpoint") { (_: Result<CheckpointResult, PublicError>) in }

    Task {
        let _: CheckpointResult = try await purchases.checkpoint(
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
