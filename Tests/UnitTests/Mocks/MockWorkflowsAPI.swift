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
    var invokedGetWorkflowParametersList: [(appUserID: String, workflowId: String, isAppBackgrounded: Bool)] = []
    var stubbedGetWorkflowResult: Result<WorkflowDataResult, BackendError>?
    /// Per-workflowId result, used when set; otherwise falls back to `stubbedGetWorkflowResult`.
    var stubbedGetWorkflowResults: [String: Result<WorkflowDataResult, BackendError>] = [:]
    /// When `true`, completions are captured instead of fired so tests can control ordering.
    var shouldStoreGetWorkflowCompletions = false
    private(set) var capturedGetWorkflowCompletions:
        [(workflowId: String, completion: WorkflowDetailResponseHandler)] = []

    override func getWorkflow(appUserID: String,
                              workflowId: String,
                              isAppBackgrounded: Bool,
                              completion: @escaping WorkflowDetailResponseHandler) {
        self.invokedGetWorkflow = true
        self.invokedGetWorkflowCount += 1
        self.invokedGetWorkflowParameters = (appUserID, workflowId, isAppBackgrounded)
        self.invokedGetWorkflowParametersList.append((appUserID, workflowId, isAppBackgrounded))

        if self.shouldStoreGetWorkflowCompletions {
            self.capturedGetWorkflowCompletions.append((workflowId, completion))
            return
        }

        completion(self.stubbedGetWorkflowResults[workflowId]
                   ?? self.stubbedGetWorkflowResult
                   ?? .failure(.missingAppUserID()))
    }

    /// Fires (and removes) the captured completion for `workflowId`. Requires
    /// `shouldStoreGetWorkflowCompletions == true`.
    func completeStoredGetWorkflow(workflowId: String,
                                   with result: Result<WorkflowDataResult, BackendError>) {
        guard let index = self.capturedGetWorkflowCompletions.firstIndex(where: { $0.workflowId == workflowId })
        else { return }
        let entry = self.capturedGetWorkflowCompletions.remove(at: index)
        entry.completion(result)
    }

    var invokedGetWorkflows = false
    var invokedGetWorkflowsCount = 0
    var invokedGetWorkflowsParameters: (appUserID: String, isAppBackgrounded: Bool, type: String?)?
    var stubbedGetWorkflowsResult: Result<WorkflowsListResponse, BackendError>?
    /// Invoked right before the `getWorkflows` completion fires, letting a test simulate an event
    /// (e.g. an identity change clearing the cache) that lands while the list fetch is in flight.
    var onGetWorkflowsBeforeCompletion: (() -> Void)?

    override func getWorkflows(appUserID: String,
                               isAppBackgrounded: Bool,
                               type: String? = nil,
                               completion: @escaping WorkflowsListResponseHandler) {
        self.invokedGetWorkflows = true
        self.invokedGetWorkflowsCount += 1
        self.invokedGetWorkflowsParameters = (appUserID, isAppBackgrounded, type)

        self.onGetWorkflowsBeforeCompletion?()
        completion(self.stubbedGetWorkflowsResult ?? .failure(.missingAppUserID()))
    }

}
