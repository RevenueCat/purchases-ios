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

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        let _: String = checkpoint.identifier
        let _: CheckpointParams = checkpoint.params
    }

    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        let _: CheckpointInfo = result.checkpoint

        if let presented = result as? CheckpointPaywallPresentedResult {
            let outcome: CheckpointPaywallOutcome = presented.paywallOutcome

            if let purchased = outcome as? CheckpointPaywallPurchasedOutcome {
                let _: CustomerInfo = purchased.customerInfo
            } else if let restored = outcome as? CheckpointPaywallRestoredOutcome {
                let _: CustomerInfo = restored.customerInfo
            } else if let failed = outcome as? CheckpointPaywallErrorOutcome {
                let _: PublicError = failed.error
            } else {
                let _: Bool = outcome is CheckpointPaywallDismissedOutcome
            }

            let _: String = outcome.description
        } else if let noAction = result as? CheckpointNoActionResult {
            let _: CheckpointNoActionReason = noAction.reason
        }
    }

}

private final class CheckpointListenerDefaultsAPITester: CheckpointListener {}

func checkCheckpointAPI(_ purchases: Purchases) {
    let string: CustomVariableValue = .string("value")
    let integer: CustomVariableValue = 2
    let double: CustomVariableValue = 4.5
    let boolean: CustomVariableValue = true

    purchases.checkpointListener = CheckpointListenerAPITester()
    let _: CheckpointListener? = purchases.checkpointListener

    let params = CheckpointParams(customVariables: [
        "name": string,
        "attempts": integer,
        "score": double,
        "subscriber": boolean
    ])
    let _: [String: CustomVariableValue] = params.customVariables

    purchases.checkpoint(
        "test_checkpoint",
        params: params
    ) { (_: Result<CheckpointResult, PublicError>) in }

    purchases.checkpoint("test_checkpoint") { (_: Result<CheckpointResult, PublicError>) in }

    Task {
        let _: CheckpointResult = try await purchases.checkpoint("test_checkpoint")
    }

    let _: CheckpointNoActionReason = .noMatch
    let _: CheckpointNoActionReason = .holdout
    let _: CheckpointNoActionReason = .frequencyCapped
    let _: CheckpointNoActionReason = .configurationUnavailable
    let _: CheckpointNoActionReason = .disabled
    let _: CheckpointNoActionReason = .unknownCheckpoint
}
