//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetWorkflowsListOperation.swift
//
//  Created by RevenueCat.

import Foundation

final class GetWorkflowsListOperation: CacheableNetworkOperation {

    private let workflowsListCallbackCache: CallbackCache<WorkflowsListCallback>
    private let configuration: AppUserConfiguration

    static func createFactory(
        configuration: UserSpecificConfiguration,
        callbackCache: CallbackCache<WorkflowsListCallback>
    ) -> CacheableNetworkOperationFactory<GetWorkflowsListOperation> {
        return .init({ cacheKey in
                .init(
                    configuration: configuration,
                    workflowsListCallbackCache: callbackCache,
                    cacheKey: cacheKey
                )
        },
                     individualizedCacheKeyPart: configuration.appUserID)
    }

    private init(
        configuration: UserSpecificConfiguration,
        workflowsListCallbackCache: CallbackCache<WorkflowsListCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.workflowsListCallbackCache = workflowsListCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.getWorkflows(completion: completion)
    }
}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension GetWorkflowsListOperation: @unchecked Sendable {}

private extension GetWorkflowsListOperation {

    func getWorkflows(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.workflowsListCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
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

            self.workflowsListCallbackCache.performOnAllItemsAndRemoveFromCache(
                withCacheable: self
            ) { callback in
                callback.completion(
                    response
                        .map { $0.body }
                        .mapError(BackendError.networkError)
                )
            }
        }
    }
}
