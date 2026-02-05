//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostIsPurchaseAllowedByRestoreBehaviorOperation.swift
//
//  Created by Will Taylor on 02/03/2026.

import Foundation

// swiftlint:disable:next type_name
final class PostIsPurchaseAllowedByRestoreBehaviorOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let postData: PostData
    private let isPurchaseAllowedByRestoreBehaviorCallbackCache:
    CallbackCache<IsPurchaseAllowedByRestoreBehaviorCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        isPurchaseAllowedByRestoreBehaviorCallbackCache: CallbackCache<IsPurchaseAllowedByRestoreBehaviorCallback>
    ) -> CacheableNetworkOperationFactory<PostIsPurchaseAllowedByRestoreBehaviorOperation> {
        let cacheKey = "\(configuration.appUserID)-\(postData.transactionJWS)"

        return CacheableNetworkOperationFactory({ cacheKey in
                    PostIsPurchaseAllowedByRestoreBehaviorOperation(
                        configuration: configuration,
                        postData: postData,
                        // swiftlint:disable:next line_length
                        isPurchaseAllowedByRestoreBehaviorCallbackCache: isPurchaseAllowedByRestoreBehaviorCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        isPurchaseAllowedByRestoreBehaviorCallbackCache: CallbackCache<IsPurchaseAllowedByRestoreBehaviorCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.postData = postData
        self.isPurchaseAllowedByRestoreBehaviorCallbackCache = isPurchaseAllowedByRestoreBehaviorCallbackCache

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

        guard self.postData.transactionJWS.isNotEmpty else {
            self.handleResult(.failure(.missingTransactionJWS()))
            completion()
            return
        }

        let request = HTTPRequest(
            method: .post(self.postData),
            path: .isPurchaseAllowedByRestoreBehavior(appUserID: self.configuration.appUserID)
        )

        // swiftlint:disable:next line_length
        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<IsPurchaseAllowedByRestoreBehaviorResponse>.Result) in
            let result = response
                .map { $0.body }
                .mapError(BackendError.networkError)

            self.handleResult(result)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostIsPurchaseAllowedByRestoreBehaviorOperation: @unchecked Sendable {}

private extension PostIsPurchaseAllowedByRestoreBehaviorOperation {

    func handleResult(_ result: Result<IsPurchaseAllowedByRestoreBehaviorResponse, BackendError>) {
        self.isPurchaseAllowedByRestoreBehaviorCallbackCache.performOnAllItemsAndRemoveFromCache(
            withCacheable: self
        ) { callback in
            callback.completion(result)
        }
    }

}

extension PostIsPurchaseAllowedByRestoreBehaviorOperation {

    struct PostData {
        let transactionJWS: String
    }

}

// MARK: - Codable

extension PostIsPurchaseAllowedByRestoreBehaviorOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {
        case transactionJWS = "fetch_token"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.transactionJWS, forKey: .transactionJWS)
    }

}

// MARK: - HTTPRequestBody

extension PostIsPurchaseAllowedByRestoreBehaviorOperation.PostData: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (CodingKeys.transactionJWS.stringValue, self.transactionJWS)
        ]
    }

}
