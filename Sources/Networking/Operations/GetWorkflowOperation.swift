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

import Foundation

final class GetWorkflowOperation: CacheableNetworkOperation {

    struct Configuration: AppUserConfiguration, NetworkConfiguration {

        let httpClient: HTTPClient
        let appUserID: String
        let workflowID: String

    }

    private let workflowCallbackCache: CallbackCache<WorkflowCallback>
    private let configuration: Configuration

    static func createFactory(
        configuration: Configuration,
        workflowCallbackCache: CallbackCache<WorkflowCallback>
    ) -> CacheableNetworkOperationFactory<GetWorkflowOperation> {
        return CacheableNetworkOperationFactory<GetWorkflowOperation>({ cacheKey in
                    .init(
                        configuration: configuration,
                        workflowCallbackCache: workflowCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: "\(configuration.appUserID)_\(configuration.workflowID)")
    }

    private init(
        configuration: Configuration,
        workflowCallbackCache: CallbackCache<WorkflowCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.workflowCallbackCache = workflowCallbackCache

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
        let workflowID = self.configuration.workflowID

        guard appUserID.isNotEmpty else {
            self.workflowCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()
            return
        }

        let request = HTTPRequest(method: .get, path: .getWorkflow(appUserID: appUserID, workflowID: workflowID))

        httpClient.perform(request) { (response: VerifiedHTTPResponse<WorkflowResponse>.Result) in
            defer {
                completion()
            }

            self.workflowCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                callbackObject.completion(response
                    .map(\.body)
                    .mapError(BackendError.networkError)
                )
            }
        }
    }

}
