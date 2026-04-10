//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsAPI.swift
//
//  Created by RevenueCat.

import Foundation

class WorkflowsAPI {

    typealias WorkflowsListResponseHandler = Backend.ResponseHandler<WorkflowsListResponse>
    typealias WorkflowDetailResponseHandler = Backend.ResponseHandler<WorkflowFetchResult>

    private let workflowsListCallbackCache: CallbackCache<WorkflowsListCallback>
    private let workflowDetailCallbackCache: CallbackCache<WorkflowDetailCallback>
    private let backendConfig: BackendConfiguration
    private let detailProcessor: WorkflowDetailProcessor

    init(backendConfig: BackendConfiguration,
         cdnFetch: WorkflowCdnFetch? = nil) {
        self.backendConfig = backendConfig
        self.workflowsListCallbackCache = .init()
        self.workflowDetailCallbackCache = .init()
        self.detailProcessor = WorkflowDetailProcessor(
            cdnFetch: cdnFetch ?? Self.defaultCdnFetch(httpClient: backendConfig.httpClient)
        )
    }

    private static func defaultCdnFetch(httpClient: HTTPClient) -> WorkflowCdnFetch {
        return { cdnUrl, completion in
            guard let url = URL(string: cdnUrl) else {
                completion(.failure(URLError(.badURL)))
                return
            }
            httpClient.fetchRawData(from: url, completion: completion)
        }
    }

    func getWorkflows(appUserID: String,
                      isAppBackgrounded: Bool,
                      completion: @escaping WorkflowsListResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWorkflowsOperation.createFactory(
            configuration: config,
            workflowsCallbackCache: self.workflowsListCallbackCache
        )

        let callback = WorkflowsListCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.workflowsListCallbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

    func getWorkflow(appUserID: String,
                     workflowId: String,
                     isAppBackgrounded: Bool,
                     completion: @escaping WorkflowDetailResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWorkflowOperation.createFactory(
            configuration: config,
            workflowId: workflowId,
            detailProcessor: self.detailProcessor,
            workflowDetailCallbackCache: self.workflowDetailCallbackCache
        )

        let callback = WorkflowDetailCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.workflowDetailCallbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WorkflowsAPI: @unchecked Sendable {}
