//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TokenTokenLogInOperation.swift
//

import Foundation

final class TokenLogInOperation: CacheableNetworkOperation {

    private let tokenCallbackCache: CallbackCache<TokenCallback>
    private let configuration: UserSpecificConfiguration
    private let token: ExternalAuthToken

    static func createFactory(
        configuration: UserSpecificConfiguration,
        token: ExternalAuthToken,
        tokenCallbackCache: CallbackCache<TokenCallback>
    ) -> CacheableNetworkOperationFactory<TokenLogInOperation> {
        return .init({
            .init(
                configuration: configuration,
                token: token,
                tokenCallbackCache: tokenCallbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: token.cacheIdentifier)
    }

    private init(
        configuration: UserSpecificConfiguration,
        token: ExternalAuthToken,
        tokenCallbackCache: CallbackCache<TokenCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.token = token
        self.tokenCallbackCache = tokenCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.logIn(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension TokenLogInOperation: @unchecked Sendable {}

private extension TokenLogInOperation {

    func logIn(completion: @escaping () -> Void) {
        guard self.token.tokenData.isEmpty == false else {
            self.tokenCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let body: Body
        switch token {
        case .oidc(let token):
            body = Body(method: "oidc",
                        scope: "openid offline_access",
                        idToken: token.asString,
                        linkToID: self.configuration.appUserID)
        }

        let request = HTTPRequest(method: .post(body), path: .logIn)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<TokenResponse>.Result) in
            self.tokenCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: VerifiedHTTPResponse<TokenResponse>.Result,
                     completion: TokenAPI.TokenResponseHandler) {
        let result: Result<TokenResponse, BackendError> = result
            .map { response in
                response.body
            }
            .mapError(BackendError.networkError)

        if case .success = result {
            Logger.user(Strings.identity.login_success)
        }

        completion(result)
    }
}

extension TokenLogInOperation {

    struct Body: Encodable {

        // Note: These keys need to be explicitly declared using snake_case
        // because the CodingKeys are also used for request signing via `contentForSignature`.
        // swiftlint:disable:next nesting
        fileprivate enum CodingKeys: String, CodingKey {
            case method = "app_user_id"
            case scope = "scope"
            case idToken = "id_token"
            case linkToID = "link_to_id"
        }

        let method: String
        let scope: String
        let idToken: String?
        let linkToID: String?

    }

}

extension TokenLogInOperation.Body: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        return [
            (Self.CodingKeys.method.stringValue, self.method),
            (Self.CodingKeys.scope.stringValue, self.scope),
            (Self.CodingKeys.idToken.stringValue, self.idToken),
            (Self.CodingKeys.linkToID.stringValue, self.linkToID),
        ]
    }

}
