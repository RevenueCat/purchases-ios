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
    ) { (_: CheckpointFlowResult?) in }

    purchases.checkpoint("test_checkpoint") { (_: CheckpointFlowResult?) in }
    purchases.checkpoint("test_checkpoint", customVariables: explicitCustomVariables)

    let entitlement: CheckpointObtainedEntitlement? = nil
    let _: EntitlementInfo? = entitlement?.entitlement
    let result: CheckpointFlowResult? = nil
    let _: Set<CheckpointObtainedEntitlement>? = result?.obtainedEntitlements

    let _: CheckpointNoActionReason = .noMatch
    let _: CheckpointNoActionReason = .holdout
    let _: CheckpointNoActionReason = .frequencyCapped
    let _: CheckpointNoActionReason = .configurationUnavailable
    let _: CheckpointNoActionReason = .unknownCheckpoint
    let _: CheckpointNoActionReason = .invalidCheckpointIdentifier
}

private func checkCheckpointResultAPI(_ result: CheckpointResult) {
    let _: String = result.description

    if let presented = result as? CheckpointResult.PaywallPresented {
        let outcome: CheckpointPaywallOutcome = presented.paywallOutcome
        let _: String = outcome.description

        if let purchased = outcome as? CheckpointPaywallOutcome.Purchased {
            let _: StoreTransaction? = purchased.transaction
            let _: CustomerInfo = purchased.customerInfo
        } else if let restored = outcome as? CheckpointPaywallOutcome.Restored {
            let _: CustomerInfo = restored.customerInfo
        } else if let failed = outcome as? CheckpointPaywallOutcome.Error {
            let _: PublicError = failed.error
        } else if outcome is CheckpointPaywallOutcome.WebCheckoutOpened {
            let _: Bool = outcome is CheckpointPaywallOutcome.WebCheckoutOpened
        } else {
            let _: Bool = outcome is CheckpointPaywallOutcome.Dismissed
        }
    } else if let receivedOffering = result as? CheckpointResult.ReceivedOffering {
        let _: Offering = receivedOffering.offering
    } else if let noAction = result as? CheckpointResult.NoAction {
        let _: CheckpointNoActionReason = noAction.reason
    }
}
