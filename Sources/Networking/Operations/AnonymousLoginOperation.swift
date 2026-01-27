//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnonymousLoginOperation.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

final class AnonymousLoginOperation: CacheableNetworkOperation {

    private let anonymousLoginCallbackCache: CallbackCache<AnonymousLoginCallback>
    private let configuration: UserSpecificConfiguration
    private let reference: String?

    static func createFactory(
        configuration: UserSpecificConfiguration,
        reference: String?,
        anonymousLoginCallbackCache: CallbackCache<AnonymousLoginCallback>
    ) -> CacheableNetworkOperationFactory<AnonymousLoginOperation> {
        return .init({
            .init(
                configuration: configuration,
                reference: reference,
                anonymousLoginCallbackCache: anonymousLoginCallbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: "anonymous_login_\(reference ?? "no_reference")")
    }

    private init(
        configuration: UserSpecificConfiguration,
        reference: String?,
        anonymousLoginCallbackCache: CallbackCache<AnonymousLoginCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.reference = reference
        self.anonymousLoginCallbackCache = anonymousLoginCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.performAnonymousLogin(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension AnonymousLoginOperation: @unchecked Sendable {}

private extension AnonymousLoginOperation {

    func performAnonymousLogin(completion: @escaping () -> Void) {
        let body = Body(
            method: "anonymous",
            anonymous: reference.map { Body.AnonymousDetails(reference: $0) }
        )

        let request = HTTPRequest(method: .post(body), path: .iamLogin)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<ResponseBody>.Result) in
            self.anonymousLoginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLoginResponse(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLoginResponse(
        _ result: VerifiedHTTPResponse<ResponseBody>.Result,
        completion: AnonymousLoginResponseHandler
    ) {
        let mappedResult: Result<(tokens: IAMTokens, appUserID: String), BackendError> = result
            .mapError(BackendError.networkError)
            .flatMap { response in
                let tokens = IAMTokens(
                    idToken: response.body.idToken,
                    accessToken: response.body.accessToken,
                    refreshToken: response.body.refreshToken,
                    expiresIn: response.body.expiresIn
                )

                // Extract app_user_id from id_token (JWT)
                guard let appUserID = JWTHelper.extractSubject(from: response.body.idToken) else {
                    Logger.error("Failed to extract app_user_id from id_token")
                    return .failure(.missingAppUserID())
                }

                return .success((tokens: tokens, appUserID: appUserID))
            }

        if case .success = mappedResult {
            Logger.user("IAM anonymous login successful")
        }

        completion(mappedResult)
    }

}

// MARK: - Request Body

extension AnonymousLoginOperation {

    struct Body: Encodable {

        struct AnonymousDetails: Encodable {
            let reference: String?
        }

        // swiftlint:disable:next nesting
        fileprivate enum CodingKeys: String, CodingKey {
            case method
            case anonymous
        }

        let method: String
        let anonymous: AnonymousDetails?

    }

}

extension AnonymousLoginOperation.Body: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        var content: [(key: String, value: String?)] = [
            (Self.CodingKeys.method.stringValue, self.method)
        ]

        if let reference = self.anonymous?.reference {
            content.append(("anonymous.reference", reference))
        }

        return content
    }

}

// MARK: - Response Body

extension AnonymousLoginOperation {

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

extension AnonymousLoginOperation.ResponseBody: HTTPResponseBody {}

// MARK: - Callback Types

typealias AnonymousLoginResponseHandler = @Sendable (Result<(tokens: IAMTokens, appUserID: String), BackendError>) -> Void

struct AnonymousLoginCallback: CacheKeyProviding {
    let cacheKey: String
    let completion: AnonymousLoginResponseHandler
}

extension AnonymousLoginCallback: Sendable {}
