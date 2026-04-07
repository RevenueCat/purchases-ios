//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetWorkflowOperation.swift
//
//  Created by RevenueCat.

import Foundation

final class GetWorkflowOperation: CacheableNetworkOperation {

    private let workflowDetailCallbackCache: CallbackCache<WorkflowDetailCallback>
    private let configuration: AppUserConfiguration
    private let workflowId: String
    private let detailProcessor: WorkflowDetailProcessor

    static func createFactory(
        configuration: UserSpecificConfiguration,
        workflowId: String,
        detailProcessor: WorkflowDetailProcessor,
        workflowDetailCallbackCache: CallbackCache<WorkflowDetailCallback>
    ) -> CacheableNetworkOperationFactory<GetWorkflowOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    workflowId: workflowId,
                    detailProcessor: detailProcessor,
                    workflowDetailCallbackCache: workflowDetailCallbackCache,
                    cacheKey: cacheKey
                )
            },
            individualizedCacheKeyPart: "\(configuration.appUserID) \(workflowId)")
    }

    private init(configuration: UserSpecificConfiguration,
                 workflowId: String,
                 detailProcessor: WorkflowDetailProcessor,
                 workflowDetailCallbackCache: CallbackCache<WorkflowDetailCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.workflowId = workflowId
        self.detailProcessor = detailProcessor
        self.workflowDetailCallbackCache = workflowDetailCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getWorkflow(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetWorkflowOperation: @unchecked Sendable {}

private extension GetWorkflowOperation {

    func getWorkflow(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.workflowDetailCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()
            return
        }

        let request = HTTPRequest(
            method: .get,
            path: .getWorkflow(appUserID: appUserID, workflowId: self.workflowId)
        )

        httpClient.perform(request) { (response: VerifiedHTTPResponse<Data>.Result) in
            switch response {
            case .failure(let networkError):
                self.workflowDetailCallbackCache.performOnAllItemsAndRemoveFromCache(
                    withCacheable: self
                ) { callbackObject in
                    callbackObject.completion(.failure(BackendError.networkError(networkError)))
                }
                completion()

            case .success(let verifiedResponse):
                Task {
                    let result: Result<WorkflowFetchResult, BackendError>
                    do {
                        let processed = try await self.detailProcessor.process(verifiedResponse.body)
                        let workflow = try PublishedWorkflow.create(with: processed.workflowData)
                        result = .success(WorkflowFetchResult(
                            workflow: workflow,
                            enrolledVariants: processed.enrolledVariants
                        ))
                    } catch WorkflowDetailProcessingError.cdnFetchFailed(let underlyingError) {
                        result = .failure(BackendError.networkError(
                            NetworkError.networkError(underlyingError)
                        ))
                    } catch {
                        result = .failure(BackendError.networkError(
                            NetworkError.decoding(error, verifiedResponse.body)
                        ))
                    }

                    self.workflowDetailCallbackCache.performOnAllItemsAndRemoveFromCache(
                        withCacheable: self
                    ) { callbackObject in
                        callbackObject.completion(result)
                    }
                    completion()
                }
            }
        }
    }

}
