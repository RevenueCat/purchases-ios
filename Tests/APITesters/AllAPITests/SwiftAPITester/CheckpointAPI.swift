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

func checkCheckpointCoreAPI(_ purchases: Purchases) {
    Task {
        let resolution: CheckpointResolution = try await purchases.resolveCheckpoint(
            identifier: "test_checkpoint",
            params: .init()
        )

        switch resolution {
        case let .workflow(workflow):
            checkResolvedCheckpointWorkflowAPI(workflow)
        case let .noAction(reason):
            checkCheckpointResolutionReasonAPI(reason)
        @unknown default:
            break
        }
    }
}

func checkCheckpointResolutionReasonAPI(_ reason: CheckpointResolutionReason) {
    let _: String = reason.value
    let _: CheckpointResolutionReason = .noMatch
    let _: CheckpointResolutionReason = .configurationUnavailable
    let _: CheckpointResolutionReason = .disabled

    switch reason {
    case .noMatch, .configurationUnavailable, .disabled:
        break
    @unknown default:
        break
    }
}

func checkResolvedCheckpointWorkflowAPI(_ resolvedWorkflow: ResolvedCheckpointWorkflow) {
    let _: PublishedWorkflow = resolvedWorkflow.workflow
    let _: UIConfig = resolvedWorkflow.uiConfig
    let _: Offering = resolvedWorkflow.offering
}
