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

    let checkpointIdentifier: String
    let workflow: ResolvedCheckpointWorkflow
    let customVariables: [String: CustomVariableValue]
    let presentationMode: FlowPresentationMode
    let initialActiveEntitlementIdentifiers: Set<String>
    let errorPresentationHandler: ErrorPresentationHandler
    let presentationContext: PresentationContext?

    init(
        checkpointIdentifier: String,
        workflow: ResolvedCheckpointWorkflow,
        customVariables: [String: CustomVariableValue],
        presentationMode: FlowPresentationMode,
        initialActiveEntitlementIdentifiers: Set<String>,
        errorPresentationHandler: @escaping ErrorPresentationHandler,
        presentationContext: PresentationContext? = nil
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.workflow = workflow
        self.customVariables = customVariables
        self.presentationMode = presentationMode
        self.initialActiveEntitlementIdentifiers = initialActiveEntitlementIdentifiers
        self.errorPresentationHandler = errorPresentationHandler
        self.presentationContext = presentationContext
    }

}

/// Everything needed to present a checkpoint ad step.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AdPresentationRequest {

    let params: AdPresentationParams
    let customVariables: [String: CustomVariableValue]
    let errorPresentationHandler: ErrorPresentationHandler

    init(
        params: AdPresentationParams,
        customVariables: [String: CustomVariableValue],
        errorPresentationHandler: @escaping ErrorPresentationHandler
    ) {
        self.params = params
        self.customVariables = customVariables
        self.errorPresentationHandler = errorPresentationHandler
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointPresentationOutcome {
    case nothingPresented
    case completed(customerInfo: CustomerInfo?)
    case backedOut
    case failed
    case synchronizationFailed(any Error)

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
