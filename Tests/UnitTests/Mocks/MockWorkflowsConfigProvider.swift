//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWorkflowsConfigProvider.swift
//
//  Created by RevenueCat.

import Foundation
@_spi(Internal) @testable import RevenueCat

final class MockWorkflowsConfigProvider: WorkflowsConfigProviderType, @unchecked Sendable {

    var stubbedWorkflowIdForOfferingId: [String: String] = [:]
    private(set) var invokedWorkflowIdForOfferingIdParameters: [String] = []

    func workflowId(forOfferingId offeringId: String) async -> String? {
        self.invokedWorkflowIdForOfferingIdParameters.append(offeringId)
        return self.stubbedWorkflowIdForOfferingId[offeringId]
    }

    var stubbedGetWorkflowResult: [String: WorkflowDataResult] = [:]
    var stubbedGetWorkflowError: [String: WorkflowResolutionError] = [:]
    private(set) var invokedGetWorkflowParameters: [String] = []

    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        self.invokedGetWorkflowParameters.append(workflowId)
        return self.workflowResult(workflowId: workflowId)
    }

    private(set) var invokedDecodeCachedWorkflowForAssetPrewarmingParameters: [String] = []

    func decodeCachedWorkflowForAssetPrewarming(
        workflowId: String
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        self.invokedDecodeCachedWorkflowForAssetPrewarmingParameters.append(workflowId)
        return self.workflowResult(workflowId: workflowId)
    }

    private func workflowResult(workflowId: String) -> Result<WorkflowDataResult, WorkflowResolutionError> {
        if let error = self.stubbedGetWorkflowError[workflowId] {
            return .failure(error)
        }
        if let result = self.stubbedGetWorkflowResult[workflowId] {
            return .success(result)
        }
        return .failure(.notFound)
    }

    private(set) var invokedCachePrefetchedWorkflowBodyDataCount = 0
    private(set) var invokedCachePrefetchedWorkflowBodyDataParameters: [String?] = []
    var stubbedWorkflowIDsWithCachedBodyData: [String] = []

    func cachePrefetchedWorkflowBodyData(includingOfferingId: String?) async -> [String] {
        self.invokedCachePrefetchedWorkflowBodyDataCount += 1
        self.invokedCachePrefetchedWorkflowBodyDataParameters.append(includingOfferingId)
        return self.stubbedWorkflowIDsWithCachedBodyData
    }

    var stubbedCachedWorkflowResult: [String: WorkflowDataResult] = [:]
    private(set) var invokedCachedWorkflowParameters: [String] = []

    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? {
        self.invokedCachedWorkflowParameters.append(offeringId)
        return self.stubbedCachedWorkflowResult[offeringId]
    }

}

final class MockWorkflowAssetPrewarmer: WorkflowAssetPrewarmingType, @unchecked Sendable {

    private(set) var invokedPrefetchedAssetPrewarmingParameters: [String?] = []

    func scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: String?) async {
        self.invokedPrefetchedAssetPrewarmingParameters.append(includingOfferingId)
    }

}
