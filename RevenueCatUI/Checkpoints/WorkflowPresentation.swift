//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPresentation.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Everything needed to present a checkpoint workflow.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPresentationRequest {

    let workflow: ResolvedCheckpointWorkflow
    let customVariables: [String: CustomVariableValue]
    let initialActiveEntitlementIdentifiers: Set<String>?

    init(
        workflow: ResolvedCheckpointWorkflow,
        customVariables: [String: CustomVariableValue],
        initialActiveEntitlementIdentifiers: Set<String>? = nil
    ) {
        self.workflow = workflow
        self.customVariables = customVariables
        self.initialActiveEntitlementIdentifiers = initialActiveEntitlementIdentifiers
    }

}

/// Everything needed to present a checkpoint ad workflow.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AdWorkflowPresentationRequest {

    let workflow: ResolvedAdWorkflow
    let checkpointIdentifier: String
    let customVariables: [String: CustomVariableValue]

    @MainActor
    func params(for step: ResolvedAdStep) -> AdPresentationParams {
        return AdPresentationParams(
            checkpointIdentifier: self.checkpointIdentifier,
            customVariables: self.customVariables,
            adIdentifier: step.adIdentifier,
            mediator: step.mediator,
            adFormat: step.adFormat
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointPresentationOutcome {
    case nothingPresented
    case completed(customerInfo: CustomerInfo?)
    case adPresented(CheckpointAdOutcome)
    case backedOut
    case failed

    var hasCustomerInfo: Bool {
        guard case .completed(.some) = self else { return false }
        return true
    }
}

/// Presents a resolved checkpoint workflow and returns its terminal execution.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol WorkflowPresenterType: AnyObject {

    func present(
        _ presentation: WorkflowPresentationRequest
    ) async throws -> CheckpointPresentationOutcome

}
