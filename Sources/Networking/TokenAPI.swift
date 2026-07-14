//
//  TokenAPI.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

class TokenAPI {
    typealias TokenResult = Result<(TokenResponse, String), BackendError>
    typealias TokenResponseHandler = (TokenResult) -> Void

    private let tokenCallbacksCache: CallbackCache<TokenCallback>
    private let revokeCallbacksCache: CallbackCache<TokenRevokeCallback>

    private let tokenManager: TokenManager
    private let backendConfig: BackendConfiguration

    var enabled: Bool { tokenManager.enabled }

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.tokenManager = backendConfig.httpClient.tokenManager
        self.tokenCallbacksCache = CallbackCache<TokenCallback>()
        self.revokeCallbacksCache = CallbackCache<TokenRevokeCallback>()
    }

    func logIn(currentAppUserID: String, token: ExternalToken, completion: @escaping TokenResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: currentAppUserID)

        let factory = TokenLogInOperation.createFactory(configuration: config,
                                                        token: token.authToken,
                                                        tokenCallbackCache: self.tokenCallbacksCache)

        let tokenCallback = TokenCallback(cacheKey: factory.cacheKey) { result in
            if case .success(let token, let userID) = result {
                self.tokenManager.saveTokens(refreshToken: token.refreshToken,
                                             accessToken: token.accessToken,
                                             idToken: token.idToken,
                                             for: userID)
            }

            completion(result)
        }
        let cacheStatus = self.tokenCallbacksCache.add(tokenCallback)

        self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
    }

    func revokeTokens(for appUserID: String, completion: @escaping (BackendError?) -> Void) {
        if let refreshToken = tokenManager.currentRefreshToken {
            let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                    appUserID: appUserID)

            let factory = TokenRevocationOperation.createFactory(configuration: config,
                                                                 refreshToken: refreshToken,
                                                                 appUserID: appUserID,
                                                                 callbackCache: self.revokeCallbacksCache)

            let revokeCallback = TokenCallback(cacheKey: factory.cacheKey) { result in
                // regardless of whether the server request was successful or not,
                // we should still delete the tokens from the client, because the client
                // was explicitly asked to log out
                completion(result.error)
            }
            let cacheStatus = self.tokenCallbacksCache.add(revokeCallback)

            self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
        } else {
            tokenManager.deleteTokens(for: appUserID)
            completion(nil)
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TokenAPI: @unchecked Sendable {}
