//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWorkflowsAPI.swift
//
//  Created by RevenueCat.

import Foundation
@_spi(Internal) @testable import RevenueCat

class MockWorkflowsAPI: WorkflowsAPI, @unchecked Sendable {

    init() {
        super.init(backendConfig: MockBackendConfiguration())
    }

    var invokedGetWorkflow = false
    var invokedGetWorkflowCount = 0
    var invokedGetWorkflowParameters: (appUserID: String, workflowId: String, isAppBackgrounded: Bool)?
    var stubbedGetWorkflowResult: Result<WorkflowDataResult, BackendError>?

    override func getWorkflow(appUserID: String,
                              workflowId: String,
                              isAppBackgrounded: Bool,
                              completion: @escaping WorkflowDetailResponseHandler) {
        self.invokedGetWorkflow = true
        self.invokedGetWorkflowCount += 1
        self.invokedGetWorkflowParameters = (appUserID, workflowId, isAppBackgrounded)

        completion(self.stubbedGetWorkflowResult ?? .failure(.missingAppUserID()))
    }

    var invokedGetWorkflows = false
    var invokedGetWorkflowsCount = 0
    var invokedGetWorkflowsParameters: (appUserID: String, isAppBackgrounded: Bool, type: String?)?
    var stubbedGetWorkflowsResult: Result<WorkflowsListResponse, BackendError>?

    override func getWorkflows(appUserID: String,
                               isAppBackgrounded: Bool,
                               type: String? = nil,
                               completion: @escaping WorkflowsListResponseHandler) {
        self.invokedGetWorkflows = true
        self.invokedGetWorkflowsCount += 1
        self.invokedGetWorkflowsParameters = (appUserID, isAppBackgrounded, type)

        completion(self.stubbedGetWorkflowsResult ?? .failure(.missingAppUserID()))
    }

}
