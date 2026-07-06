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
    private(set) var invokedGetWorkflowParameters: [String] = []

    func getWorkflow(workflowId: String) async -> WorkflowDataResult? {
        self.invokedGetWorkflowParameters.append(workflowId)
        return self.stubbedGetWorkflowResult[workflowId]
    }

}
