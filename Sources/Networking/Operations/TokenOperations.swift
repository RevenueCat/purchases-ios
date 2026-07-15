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
        guard self.token.validate() else {
            self.tokenCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                #warning("DAVE: this could use a better failure reason")
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let body: any HTTPRequestBody
        switch token {
        case .oidc(let token):
            body = StandardBody(method: "oidc",
                                scope: "openid offline_access",
                                idToken: token.asString,
                                linkToID: self.configuration.appUserID)
        case .google(let token):
            body = StandardBody(method: "google",
                                scope: "openid offline_access",
                                idToken: token.asString,
                                linkToID: self.configuration.appUserID)
        case .siwa(let token):
            body = StandardBody(method: "apple",
                                scope: "openid offline_access",
                                idToken: token.asString,
                                linkToID: self.configuration.appUserID)
        case .facebook(let token, let email):
            body = FacebookBody(method: "facebook",
                                scope: "openid offline_access",
                                idToken: token.asString,
                                email: email,
                                linkToID: self.configuration.appUserID)
        case .firebase(let token):
            body = StandardBody(method: "firebase",
                                scope: "openid offline_access",
                                idToken: token.asString,
                                linkToID: self.configuration.appUserID)
        }

        let request = HTTPRequest(method: .post(body), path: .tokenLogin)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<TokenResponse>.Result) in
            self.tokenCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: VerifiedHTTPResponse<TokenResponse>.Result,
                     completion: TokenAPI.TokenResponseHandler) {
        let finalResult: TokenAPI.TokenResult

        switch result {
        case .success(let response):
            do {
                let jwt = try JWT(from: response.body.accessToken)
                guard let userID = jwt.appUserID else {
                    throw BackendError.unexpectedBackendResponse(.loginResponseDecoding,
                                                                 extraContext: "JWT missing RC user ID")
                }

                finalResult = .success((response.body, userID))
                Logger.user(Strings.identity.login_success)
            } catch let error as BackendError {
                finalResult = .failure(error)
            } catch {
                finalResult = .failure(BackendError.unexpectedBackendResponse(.loginResponseDecoding))
            }
        case .failure(let networkError):
            finalResult = .failure(BackendError.networkError(networkError))
        }

        completion(finalResult)
    }
}

final class TokenRevocationOperation: CacheableNetworkOperation, @unchecked Sendable {

    private let callbackCache: CallbackCache<TokenRevokeCallback>
    private let configuration: UserSpecificConfiguration
    private let refreshToken: String
    private let appUserID: String

    static func createFactory(
        configuration: UserSpecificConfiguration,
        refreshToken: String,
        appUserID: String,
        callbackCache: CallbackCache<TokenRevokeCallback>
    ) -> CacheableNetworkOperationFactory<TokenRevocationOperation> {
        return .init({
            .init(
                configuration: configuration,
                refreshToken: refreshToken,
                appUserID: appUserID,
                callbackCache: callbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: appUserID)
    }

    private init(
        configuration: UserSpecificConfiguration,
        refreshToken: String,
        appUserID: String,
        callbackCache: CallbackCache<TokenRevokeCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.refreshToken = refreshToken
        self.appUserID = appUserID
        self.callbackCache = callbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        guard self.refreshToken.isNotEmpty else {
            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(BackendError.missingAppUserID())
            }
            completion()

            return
        }

        let body = Body(token: refreshToken, tokenTypeHint: "refresh_token")

        let request = HTTPRequest(method: .post(body), path: .tokenLogOut)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<Data>.Result) in
            self.callbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                let mappedResponse = response.mapError(BackendError.networkError)
                callbackObject.completion(mappedResponse.error)
            }

            completion()
        }
    }
}

// MARK: - Request Bodies

extension TokenLogInOperation {

    struct StandardBody: Encodable, HTTPRequestBody {

        // Note: These keys need to be explicitly declared using snake_case
        // because the CodingKeys are also used for request signing via `contentForSignature`.
        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case method = "app_user_id"
            case scope = "scope"
            case idToken = "id_token"
            case linkToID = "link_to_id"
        }

        let method: String
        let scope: String
        let idToken: String
        let linkToID: String?

        var contentForSignature: [(key: String, value: String?)] {
            return [
                (Self.CodingKeys.method.stringValue, self.method),
                (Self.CodingKeys.scope.stringValue, self.scope),
                (Self.CodingKeys.idToken.stringValue, self.idToken),
                (Self.CodingKeys.linkToID.stringValue, self.linkToID)
            ]
        }

    }

    struct FacebookBody: Encodable, HTTPRequestBody {

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case method = "app_user_id"
            case scope = "scope"
            case idToken = "id_token"
            case email = "email"
            case linkToID = "link_to_id"
        }

        let method: String
        let scope: String
        let idToken: String
        let email: String?
        let linkToID: String?

        var contentForSignature: [(key: String, value: String?)] {
            return [
                (Self.CodingKeys.method.stringValue, self.method),
                (Self.CodingKeys.scope.stringValue, self.scope),
                (Self.CodingKeys.idToken.stringValue, self.idToken),
                (Self.CodingKeys.email.stringValue, self.email),
                (Self.CodingKeys.linkToID.stringValue, self.linkToID)
            ]
        }

    }

}

// this is an enum because "TokenRefreshOperations" don't exist like the TokenLogInOperation.
// token refreshing happens directly in the TokenManager. This enum exists for
// namespacing consistency and recognizability.
enum TokenRefreshOperation {

    struct Body: Encodable, HTTPRequestBody {
        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case grantType = "grant_type"
            case refreshToken = "refresh_token"
        }

        let grantType: String
        let refreshToken: String

        var contentForSignature: [(key: String, value: String?)] {
            return [
                (Self.CodingKeys.grantType.stringValue, self.grantType),
                (Self.CodingKeys.refreshToken.stringValue, self.refreshToken)
            ]
        }
    }

}

extension TokenRevocationOperation {

    struct Body: Encodable, HTTPRequestBody {

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case token = "token"
            case tokenTypeHint = "token_type_hint"
        }

        let token: String
        let tokenTypeHint: String

        var contentForSignature: [(key: String, value: String?)] {
            return [
                (Self.CodingKeys.token.stringValue, self.token),
                (Self.CodingKeys.tokenTypeHint.stringValue, self.tokenTypeHint)
            ]
        }

    }

}
