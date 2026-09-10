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

/// Registers a StoreKit external purchase token with RevenueCat, for a purchase made outside of
/// Apple's in-app purchase system.
final class PostExternalPurchaseTokenOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let postData: PostData
    private let externalPurchaseTokenCallbackCache: CallbackCache<ExternalPurchaseTokenCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        externalPurchaseTokenCallbackCache: CallbackCache<ExternalPurchaseTokenCallback>
    ) -> CacheableNetworkOperationFactory<PostExternalPurchaseTokenOperation> {
        let cacheKey = "\(configuration.appUserID)-\(postData.purchaseType.rawValue)-\(postData.tokenID)"

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
            self.handleResult(.missingAppUserID())
            completion()
            return
        }

        let request = HTTPRequest(method: .post(self.postData),
                                  path: .postExternalPurchaseToken,
                                  isRetryable: true)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
            self.handleResult(response.mapError(BackendError.networkError).error)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostExternalPurchaseTokenOperation: @unchecked Sendable {}

private extension PostExternalPurchaseTokenOperation {

    func handleResult(_ error: BackendError?) {
        self.externalPurchaseTokenCallbackCache.performOnAllItemsAndRemoveFromCache(
            withCacheable: self
        ) { callback in
            callback.completion(error)
        }
    }

}

extension PostExternalPurchaseTokenOperation {

    struct PostData {

        let appUserID: String
        let purchaseType: ExternalPurchaseTokenType

        /// The identifier the SDK generated for this registration.
        let tokenID: String

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
        case tokenID = "rc_public_id"
        case token

    }

}

// MARK: - HTTPRequestBody

extension PostExternalPurchaseTokenOperation.PostData: HTTPRequestBody {}
