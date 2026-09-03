//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostExternalPurchaseTokenOperation.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation

final class PostExternalPurchaseTokenOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let postData: PostData
    private let externalPurchaseTokenCallbackCache: CallbackCache<ExternalPurchaseTokenCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        externalPurchaseTokenCallbackCache: CallbackCache<ExternalPurchaseTokenCallback>
    ) -> CacheableNetworkOperationFactory<PostExternalPurchaseTokenOperation> {
        let cacheKey = "\(configuration.appUserID)-\(postData.purchaseType.rawValue)-\(postData.token ?? "")"

        return CacheableNetworkOperationFactory({ cacheKey in
                    PostExternalPurchaseTokenOperation(
                        configuration: configuration,
                        postData: postData,
                        externalPurchaseTokenCallbackCache: externalPurchaseTokenCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    private init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        externalPurchaseTokenCallbackCache: CallbackCache<ExternalPurchaseTokenCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.postData = postData
        self.externalPurchaseTokenCallbackCache = externalPurchaseTokenCallbackCache

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

        let request = HTTPRequest(method: .post(self.postData),
                                  path: .postExternalPurchaseToken,
                                  isRetryable: true)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<ExternalPurchaseTokenResponse>.Result) in
            let result = response
                .map { $0.body }
                .mapError(BackendError.networkError)

            self.handleResult(result)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostExternalPurchaseTokenOperation: @unchecked Sendable {}

private extension PostExternalPurchaseTokenOperation {

    func handleResult(_ result: Result<ExternalPurchaseTokenResponse, BackendError>) {
        self.externalPurchaseTokenCallbackCache.performOnAllItemsAndRemoveFromCache(
            withCacheable: self
        ) { callback in
            callback.completion(result)
        }
    }

}

extension PostExternalPurchaseTokenOperation {

    struct PostData {

        let appUserID: String
        let purchaseType: ExternalPurchaseTokenType

        /// The StoreKit token. Omitted when StoreKit could not provide one, in which case the backend
        /// generates a stand-in so the purchase can still be registered.
        let token: String?

    }

}

// MARK: - Codable

extension PostExternalPurchaseTokenOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {

        case appUserID = "app_user_id"
        case purchaseType = "purchase_type"
        case token

    }

}

// MARK: - HTTPRequestBody

extension PostExternalPurchaseTokenOperation.PostData: HTTPRequestBody {}
