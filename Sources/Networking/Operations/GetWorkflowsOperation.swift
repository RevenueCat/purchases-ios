//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetWorkflowsOperation.swift
//
//  Created by RevenueCat.

import Foundation

final class GetWorkflowsOperation: CacheableNetworkOperation {

    private let workflowsCallbackCache: CallbackCache<WorkflowsListCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        workflowsCallbackCache: CallbackCache<WorkflowsListCallback>
    ) -> CacheableNetworkOperationFactory<GetWorkflowsOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    workflowsCallbackCache: workflowsCallbackCache,
                    cacheKey: cacheKey
                )
            },
            individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(configuration: UserSpecificConfiguration,
                 workflowsCallbackCache: CallbackCache<WorkflowsListCallback>,
                 cacheKey: String) {
        self.configuration = configuration
        self.workflowsCallbackCache = workflowsCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getWorkflows(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetWorkflowsOperation: @unchecked Sendable {}

private extension GetWorkflowsOperation {

    func getWorkflows(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.workflowsCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()
            return
        }

        let request = HTTPRequest(method: .get, path: .getWorkflows(appUserID: appUserID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<WorkflowsListResponse>.Result) in
            defer {
                completion()
            }

            self.workflowsCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callbackObject in
                callbackObject.completion(response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
