//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostWillPurchaseBeBlockedByRestoreBehaviorOperation.swift
//
//  Created by Will Taylor on 02/03/2026.

import Foundation

// swiftlint:disable:next type_name
final class PostWillPurchaseBeBlockedByRestoreBehaviorOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let postData: PostData
    private let restoreEligibilityCallbackCache: CallbackCache<RestoreEligibilityCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        restoreEligibilityCallbackCache: CallbackCache<RestoreEligibilityCallback>
    ) -> CacheableNetworkOperationFactory<PostWillPurchaseBeBlockedByRestoreBehaviorOperation> {
        let cacheKey = "\(configuration.appUserID)-\(postData.transactionJWS)"

        return CacheableNetworkOperationFactory({ cacheKey in
                    PostWillPurchaseBeBlockedByRestoreBehaviorOperation(
                        configuration: configuration,
                        postData: postData,
                        restoreEligibilityCallbackCache: restoreEligibilityCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        restoreEligibilityCallbackCache: CallbackCache<RestoreEligibilityCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.postData = postData
        self.restoreEligibilityCallbackCache = restoreEligibilityCallbackCache

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
            path: .restoreEligibility(appUserID: self.configuration.appUserID)
        )

        // swiftlint:disable:next line_length
        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<WillPurchaseBeBlockedByRestoreBehaviorResponse>.Result) in
            let result = response
                .map { $0.body }
                .mapError(BackendError.networkError)

            self.handleResult(result)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostWillPurchaseBeBlockedByRestoreBehaviorOperation: @unchecked Sendable {}

private extension PostWillPurchaseBeBlockedByRestoreBehaviorOperation {

    func handleResult(_ result: Result<WillPurchaseBeBlockedByRestoreBehaviorResponse, BackendError>) {
        self.restoreEligibilityCallbackCache.performOnAllItemsAndRemoveFromCache(
            withCacheable: self
        ) { callback in
            callback.completion(result)
        }
    }

}

extension PostWillPurchaseBeBlockedByRestoreBehaviorOperation {

    struct PostData {
        let transactionJWS: String
    }

}

// MARK: - Codable

extension PostWillPurchaseBeBlockedByRestoreBehaviorOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {
        case transactionJWS = "fetch_token"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.transactionJWS, forKey: .transactionJWS)
    }

}

// MARK: - HTTPRequestBody

extension PostWillPurchaseBeBlockedByRestoreBehaviorOperation.PostData: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (CodingKeys.transactionJWS.stringValue, self.transactionJWS)
        ]
    }

}
