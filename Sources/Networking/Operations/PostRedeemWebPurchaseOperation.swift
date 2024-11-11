//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// PostRedeeemWebPurchaseOperation.swift
//
// Created by Antonio Rico Diez on 2024-10-17.

import Foundation

final class PostRedeemWebPurchaseOperation: CacheableNetworkOperation {

    private let postData: PostData
    private let configuration: AppUserConfiguration
    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    ) -> CacheableNetworkOperationFactory<PostRedeemWebPurchaseOperation> {
        return Self.createFactory(
            configuration: configuration,
            postData: postData,
            customerInfoResponseHandler: .init(
                offlineCreator: nil,
                userID: configuration.appUserID,
                failIfInvalidSubscriptionKeyDetectedInDebug: true
            ),
            customerInfoCallbackCache: customerInfoCallbackCache
        )
    }

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoResponseHandler: CustomerInfoResponseHandler,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    ) -> CacheableNetworkOperationFactory<PostRedeemWebPurchaseOperation> {
        /// Cache key comprises of the following:
        /// - `appUserID`
        /// - `redemptionToken`
        let cacheKey = "\(configuration.appUserID)-\(postData.redemptionToken)"

        return CacheableNetworkOperationFactory({ cacheKey in
                    PostRedeemWebPurchaseOperation(
                        configuration: configuration,
                        postData: postData,
                        customerInfoResponseHandler: customerInfoResponseHandler,
                        customerInfoCallbackCache: customerInfoCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    private init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoResponseHandler: CustomerInfoResponseHandler,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
        cacheKey: String
    ) {
        self.customerInfoResponseHandler = customerInfoResponseHandler
        self.customerInfoCallbackCache = customerInfoCallbackCache
        self.postData = postData
        self.configuration = configuration

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.postData),
                                  path: .postRedeemWebPurchase,
                                  isRetryable: true)

        self.httpClient.perform(
            request
        ) { (response: VerifiedHTTPResponse<CustomerInfoResponseHandler.Response>.Result) in
            self.customerInfoResponseHandler.handle(customerInfoResponse: response) { result in
                self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(
                    withCacheable: self
                ) { callbackObject in
                    callbackObject.completion(result)
                }
            }

            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostRedeemWebPurchaseOperation: @unchecked Sendable {}

extension PostRedeemWebPurchaseOperation {

    struct PostData {

        let appUserID: String
        let redemptionToken: String
    }

}

// MARK: - Private
// MARK: - Codable

extension PostRedeemWebPurchaseOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {

        case appUserID = "app_user_id"
        case redemptionToken = "redemption_token"

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encode(self.redemptionToken, forKey: .redemptionToken)
    }

}

// MARK: - HTTPRequestBody

extension PostRedeemWebPurchaseOperation.PostData: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (Self.CodingKeys.appUserID.stringValue, self.appUserID),
            (Self.CodingKeys.redemptionToken.stringValue, self.redemptionToken)
        ]
    }

}
