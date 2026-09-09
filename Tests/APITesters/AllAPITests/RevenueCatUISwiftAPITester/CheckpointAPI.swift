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
