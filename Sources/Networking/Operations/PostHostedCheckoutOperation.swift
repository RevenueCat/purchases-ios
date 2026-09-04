//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostHostedCheckoutOperation.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

final class PostHostedCheckoutOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let postData: PostData
    private let hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>
    ) -> CacheableNetworkOperationFactory<PostHostedCheckoutOperation> {
        // Each call creates a checkout session, so repeated taps of the same button while one is in
        // flight join the request already running rather than opening a second session.
        let cacheKey = [
            configuration.appUserID,
            postData.packageID,
            postData.presentedOfferingIdentifier
        ].joined(separator: "\n")

        return CacheableNetworkOperationFactory({ cacheKey in
                    PostHostedCheckoutOperation(
                        configuration: configuration,
                        postData: postData,
                        hostedCheckoutCallbackCache: hostedCheckoutCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    private init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.postData = postData
        self.hostedCheckoutCallbackCache = hostedCheckoutCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        guard self.configuration.appUserID.isNotEmpty else {
            self.handleResult(.failure(.missingAppUserID()))
            completion()
            return
        }

        // Not retried: a request the server may have already handled would leave behind a checkout
        // session nobody goes on to use.
        let request = HTTPRequest(method: .post(self.postData),
                                  path: .postHostedCheckout,
                                  isRetryable: false)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HostedCheckoutResponse>.Result) in
            let result = response
                .map { $0.body }
                .mapError(BackendError.networkError)

            self.handleResult(result)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostHostedCheckoutOperation: @unchecked Sendable {}

private extension PostHostedCheckoutOperation {

    func handleResult(_ result: Result<HostedCheckoutResponse, BackendError>) {
        self.hostedCheckoutCallbackCache.performOnAllItemsAndRemoveFromCache(
            withCacheable: self
        ) { callback in
            callback.completion(result)
        }
    }

}

extension PostHostedCheckoutOperation {

    struct PostData {

        let appUserID: String
        let packageID: String
        let presentedOfferingIdentifier: String

    }

}

// MARK: - Codable

extension PostHostedCheckoutOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {

        case appUserID = "app_user_id"
        case packageID = "package_id"
        case presentedOfferingIdentifier = "presented_offering_identifier"

    }

}

// MARK: - HTTPRequestBody

extension PostHostedCheckoutOperation.PostData: HTTPRequestBody {}
