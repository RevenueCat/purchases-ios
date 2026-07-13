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

    private let loginCallbackCache: CallbackCache<LogInCallback>
    private let configuration: UserSpecificConfiguration
    private let token: ExternalAuthToken

    static func createFactory(
        configuration: UserSpecificConfiguration,
        token: ExternalAuthToken,
        loginCallbackCache: CallbackCache<LogInCallback>
    ) -> CacheableNetworkOperationFactory<TokenLogInOperation> {
        return .init({
            .init(
                configuration: configuration,
                token: token,
                loginCallbackCache: loginCallbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: token.cacheIdentifier)
    }

    private init(
        configuration: UserSpecificConfiguration,
        token: ExternalAuthToken,
        loginCallbackCache: CallbackCache<LogInCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.token = token
        self.loginCallbackCache = loginCallbackCache

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
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
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

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<CustomerInfo>.Result) in
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: VerifiedHTTPResponse<CustomerInfo>.Result,
                     completion: IdentityAPI.LogInResponseHandler) {
        let result: Result<(info: CustomerInfo, created: Bool), BackendError> = result
            .map { response in
                (
                    response.body.copy(with: response.verificationResult,
                                       httpResponseOriginalSource: response.originalSource),
                    created: response.httpStatusCode == .createdSuccess
                )
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
            case scope = "new_app_user_id"
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
