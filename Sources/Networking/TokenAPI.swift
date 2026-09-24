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
    private let backendLanes: BackendLanes

    var enabled: Bool { tokenManager.enabled }

    init(backendLanes: BackendLanes) {
        self.backendLanes = backendLanes
        self.tokenManager = backendLanes[TokenLogInOperation.self].httpClient.tokenManager
        self.tokenCallbacksCache = CallbackCache<TokenCallback>()
        self.revokeCallbacksCache = CallbackCache<TokenRevokeCallback>()
    }

    func logIn(currentAppUserID: String, identity: Identity, completion: @escaping TokenResponseHandler) {
        let backendConfig = self.backendLanes[TokenLogInOperation.self]
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                appUserID: currentAppUserID)

        let linkToID = tokenManager.idToken(for: currentAppUserID)
        let factory = TokenLogInOperation.createFactory(configuration: config,
                                                        token: identity.authToken,
                                                        linkToIDToken: linkToID,
                                                        tokenCallbackCache: self.tokenCallbacksCache)

        let tokenCallback = TokenCallback(cacheKey: factory.cacheKey) { result in
            if case .success(let (token, userID)) = result {
                self.tokenManager.saveTokens(refreshToken: token.refreshToken,
                                             accessToken: token.accessToken,
                                             idToken: token.idToken,
                                             for: userID)
            }

            completion(result)
        }
        let cacheStatus = self.tokenCallbacksCache.add(tokenCallback)

        backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
    }

    func revokeTokens(for appUserID: String, completion: @escaping (BackendError?) -> Void) {
        if let refreshToken = tokenManager.currentRefreshToken {
            let backendConfig = self.backendLanes[TokenRevocationOperation.self]
            let config = NetworkOperation.UserSpecificConfiguration(httpClient: backendConfig.httpClient,
                                                                    appUserID: appUserID)

            let factory = TokenRevocationOperation.createFactory(configuration: config,
                                                                 refreshToken: refreshToken,
                                                                 appUserID: appUserID,
                                                                 callbackCache: self.revokeCallbacksCache)

            let revokeCallback = TokenRevokeCallback(cacheKey: factory.cacheKey) { error in
                if error == nil {
                    self.tokenManager.deleteTokens(for: appUserID)
                }
                completion(error)
            }
            let cacheStatus = self.revokeCallbacksCache.add(revokeCallback)

            backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
        } else {
            tokenManager.deleteTokens(for: appUserID)
            completion(nil)
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TokenAPI: @unchecked Sendable {}
