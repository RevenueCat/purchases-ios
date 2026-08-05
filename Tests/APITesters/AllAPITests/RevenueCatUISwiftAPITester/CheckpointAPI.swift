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

@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI

private final class CheckpointListenerAPITester: CheckpointListener {

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        let _: String = checkpoint.identifier
        let _: CheckpointParams = checkpoint.params
    }

    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        let _: CheckpointInfo = result.checkpoint

        if let presented = result as? CheckpointPaywallPresentedResult {
            let _: CheckpointPaywallOutcome = presented.paywallOutcome
        } else if let noAction = result as? CheckpointNoActionResult {
            let _: CheckpointNoActionReason = noAction.reason
        }
    }

}

private final class CheckpointListenerDefaultsAPITester: CheckpointListener {}

func checkCheckpointAPI(_ purchases: Purchases) {
    purchases.checkpointListener = CheckpointListenerAPITester()
    let _: CheckpointListener? = purchases.checkpointListener

    let params = CheckpointParams(customProperties: [
        "name": "Rick",
        "attempts": 2,
        "score": 4.5,
        "subscriber": true
    ])
    let _: [String: CheckpointValue] = params.customProperties

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
}

func checkCheckpointPaywallOutcomeAPI(customerInfo: CustomerInfo, error: PublicError) {
    let dismissed: CheckpointPaywallOutcome = CheckpointPaywallDismissedOutcome.shared
    let purchased: CheckpointPaywallOutcome = CheckpointPaywallPurchasedOutcome(customerInfo: customerInfo)
    let restored: CheckpointPaywallOutcome = CheckpointPaywallRestoredOutcome(customerInfo: customerInfo)
    let failed: CheckpointPaywallOutcome = CheckpointPaywallErrorOutcome(error: error)

    let _: String = dismissed.description
    let _: String = purchased.description
    let _: String = restored.description
    let _: String = failed.description
    let _: Bool = dismissed == CheckpointPaywallDismissedOutcome.shared
}
