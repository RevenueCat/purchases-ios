//
//  TokenAPI.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/13/26.
//

import Foundation

class TokenAPI {

    typealias TokenResult = Result<TokenResponse, BackendError>
    typealias TokenResponseHandler = (TokenResult) -> Void

    private let tokenCallbacksCache: CallbackCache<TokenCallback>

    private let tokenManager: TokenManager
    private let backendConfig: BackendConfiguration

    var enabled: Bool { tokenManager.enabled }

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.tokenManager = backendConfig.httpClient.tokenManager
        self.tokenCallbacksCache = CallbackCache<TokenCallback>()
    }

    func logIn(currentAppUserID: String?, token: ExternalToken, completion: @escaping TokenResponseHandler) {
        #warning("DAVE: What if we don't have a user id")
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: currentAppUserID ?? "")

        let factory = TokenLogInOperation.createFactory(configuration: config,
                                                        token: token.authToken,
                                                        tokenCallbackCache: self.tokenCallbacksCache)

        let tokenCallback = TokenCallback(cacheKey: factory.cacheKey) { response in
            // TODO: use the completion()
            switch response {
            case .success(let token):
                #warning("DAVE: Save the token")

            case .failure(let error):
                completion(.failure(error))
            }
        }
        let cacheStatus = self.tokenCallbacksCache.add(tokenCallback)

        self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)

    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TokenAPI: @unchecked Sendable {}
