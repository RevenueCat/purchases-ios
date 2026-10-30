//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ResolvedCheckpointWorkflow.swift
//

import Foundation

/// A workflow resolved from RevenueCat configuration and ready for RevenueCatUI to present.
@_spi(Internal) public final class ResolvedCheckpointWorkflow: @unchecked Sendable {

    /// The workflow to render.
    public let workflow: PublishedWorkflow
    /// UI configuration used to render the workflow.
    public let uiConfig: UIConfig
    /// All offerings available while executing the workflow.
    public let offerings: Offerings
    /// The `blob_ref` of the config item the workflow came from.
    public let workflowBlobRef: String?
    /// Shared by the checkpoint hit and every event of the workflow run it starts.
    public let traceId: String

    init(
        workflow: PublishedWorkflow,
        uiConfig: UIConfig,
        offerings: Offerings,
        workflowBlobRef: String? = nil,
        traceId: String = UUID().uuidString
    ) {
        self.workflow = workflow
        self.uiConfig = uiConfig
        self.offerings = offerings
        self.workflowBlobRef = workflowBlobRef
        self.traceId = traceId
    }

}
