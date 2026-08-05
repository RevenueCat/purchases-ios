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
@_spi(Internal) import RevenueCatUI

private final class CheckpointListenerAPITester: CheckpointListener {

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        let _: String = checkpoint.identifier
        let _: CheckpointParams = checkpoint.params
    }

    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        let _: CheckpointInfo = result.checkpoint

        if let presented = result as? CheckpointPaywallPresentedResult {
            let _: CheckpointPaywallOutcome = presented.paywallOutcome
        } else if let noAction = result as? CheckpointNoActionResult {
            let _: CheckpointNoActionReason = noAction.reason
        }
    }

    func onCheckpointPaywallFinished(_ checkpoint: CheckpointInfo, outcome: CheckpointPaywallOutcome) {
        if let purchased = outcome as? CheckpointPaywallPurchasedOutcome {
            let _: CustomerInfo = purchased.customerInfo
        } else if let restored = outcome as? CheckpointPaywallRestoredOutcome {
            let _: CustomerInfo = restored.customerInfo
        } else if let error = outcome as? CheckpointPaywallErrorOutcome {
            let _: PublicError = error.error
        }
    }

}

private final class CheckpointListenerDefaultsAPITester: CheckpointListener {}

func checkCheckpointAPI(_ purchases: Purchases) {
    purchases.checkpointListener = CheckpointListenerAPITester()
    let _: CheckpointListener? = purchases.checkpointListener

    purchases.checkpoint(
        "test_checkpoint",
        params: CheckpointParams()
    ) { (_: Result<CheckpointResult, PublicError>) in }

    purchases.checkpoint("test_checkpoint") { (_: Result<CheckpointResult, PublicError>) in }

    Task {
        let _: CheckpointResult = try await purchases.checkpoint("test_checkpoint")
    }

    #if ENABLE_CHECKPOINTS_OBJC
    purchases.checkpoint(
        "test_checkpoint",
        params: ObjCCheckpointParams()
    ) { (result: ObjCCheckpointResult?, _: PublicError?) in
        guard let result else { return }
        let _: ObjCCheckpointInfo = result.checkpoint

        if let presented = result as? ObjCCheckpointPaywallPresentedResult {
            let outcome: ObjCCheckpointPaywallOutcome = presented.paywallOutcome
            if let purchased = outcome as? ObjCCheckpointPaywallPurchasedOutcome {
                let _: CustomerInfo = purchased.customerInfo
            } else if let restored = outcome as? ObjCCheckpointPaywallRestoredOutcome {
                let _: CustomerInfo = restored.customerInfo
            } else if let error = outcome as? ObjCCheckpointPaywallErrorOutcome {
                let _: PublicError = error.error
            } else if outcome is ObjCCheckpointPaywallDismissedOutcome {
                return
            }
        } else if let noAction = result as? ObjCCheckpointNoActionResult {
            let _: ObjCCheckpointNoActionReason = noAction.reason
            let _: String = noAction.reason.value
        }
    }

    purchases.checkpoint(
        "test_checkpoint",
        params: nil as ObjCCheckpointParams?
    ) { (_: ObjCCheckpointResult?, _: PublicError?) in }
    #endif

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
