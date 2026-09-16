//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowPresentation.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Everything needed to present a checkpoint workflow.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CheckpointPresentation {

    let workflow: ResolvedCheckpointWorkflow
    let customVariables: [String: CustomVariableValue]

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointExecution {
    case nothingPresented
    case completed(CheckpointFlowOutcome)
    case backedOut(CheckpointFlowOutcome)
}

/// Presents a resolved checkpoint workflow and returns its terminal execution.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol CheckpointWorkflowPresenterProtocol: AnyObject {

    func cancel()
    func present(
        _ presentation: CheckpointPresentation
    ) async throws -> CheckpointExecution

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointWorkflowPresenterProtocol {

    func cancel() {}

}
