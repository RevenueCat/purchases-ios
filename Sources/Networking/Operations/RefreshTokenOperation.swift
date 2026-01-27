//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RefreshTokenOperation.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

final class RefreshTokenOperation: CacheableNetworkOperation {

    private let refreshTokenCallbackCache: CallbackCache<RefreshTokenCallback>
    private let configuration: UserSpecificConfiguration
    private let refreshToken: String

    static func createFactory(
        configuration: UserSpecificConfiguration,
        refreshToken: String,
        refreshTokenCallbackCache: CallbackCache<RefreshTokenCallback>
    ) -> CacheableNetworkOperationFactory<RefreshTokenOperation> {
        return .init({
            .init(
                configuration: configuration,
                refreshToken: refreshToken,
                refreshTokenCallbackCache: refreshTokenCallbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: "refresh_token")
    }

    private init(
        configuration: UserSpecificConfiguration,
        refreshToken: String,
        refreshTokenCallbackCache: CallbackCache<RefreshTokenCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.refreshToken = refreshToken
        self.refreshTokenCallbackCache = refreshTokenCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.performTokenRefresh(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension RefreshTokenOperation: @unchecked Sendable {}

private extension RefreshTokenOperation {

    func performTokenRefresh(completion: @escaping () -> Void) {
        let body = Body(
            grantType: "refresh_token",
            refreshToken: self.refreshToken
        )

        let request = HTTPRequest(method: .post(body), path: .iamToken)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<ResponseBody>.Result) in
            self.refreshTokenCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleRefreshResponse(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleRefreshResponse(
        _ result: VerifiedHTTPResponse<ResponseBody>.Result,
        completion: RefreshTokenResponseHandler
    ) {
        let mappedResult: Result<IAMTokens, BackendError> = result
            .mapError(BackendError.networkError)
            .map { response in
                IAMTokens(
                    idToken: response.body.idToken,
                    accessToken: response.body.accessToken,
                    refreshToken: response.body.refreshToken,
                    expiresIn: response.body.expiresIn
                )
            }

        if case .success = mappedResult {
            Logger.debug("IAM token refresh successful")
        } else if case .failure(let error) = mappedResult {
            Logger.error("IAM token refresh failed: \(error)")
        }

        completion(mappedResult)
    }

}

// MARK: - Request Body

extension RefreshTokenOperation {

    struct Body: Encodable {

        // swiftlint:disable:next nesting
        fileprivate enum CodingKeys: String, CodingKey {
            case grantType = "grant_type"
            case refreshToken = "refresh_token"
        }

        let grantType: String
        let refreshToken: String

    }

}

extension RefreshTokenOperation.Body: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (Self.CodingKeys.grantType.stringValue, self.grantType),
            (Self.CodingKeys.refreshToken.stringValue, self.refreshToken)
        ]
    }

}

// MARK: - Response Body

extension RefreshTokenOperation {

    struct ResponseBody: Decodable {

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case idToken = "id_token"
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }

        let idToken: String
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int?

    }

}

extension RefreshTokenOperation.ResponseBody: HTTPResponseBody {}

// MARK: - Callback Types

typealias RefreshTokenResponseHandler = @Sendable (Result<IAMTokens, BackendError>) -> Void

struct RefreshTokenCallback: CacheKeyProviding {
    let cacheKey: String
    let completion: RefreshTokenResponseHandler
}

extension RefreshTokenCallback: Sendable {}
