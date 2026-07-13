//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IdentityAPI.swift
//
//  Created by Joshua Liebowitz on 6/15/22.

import Foundation

class IdentityAPI {

    struct LogInRequest: Equatable {
        enum Kind: Equatable {
            case identifyAs(newAppUserID: String)
            case switchTo(ExternalToken)
        }

        let currentAppUserID: String
        let kind: Kind
    }

    typealias LogInResponse = Result<(info: CustomerInfo, created: Bool), BackendError>
    typealias LogInResponseHandler = (LogInResponse) -> Void

    private let logInCallbacksCache: CallbackCache<LogInCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.logInCallbacksCache = CallbackCache<LogInCallback>()
    }

    func logIn(_ request: LogInRequest, completion: @escaping LogInResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: request.currentAppUserID)

        switch request.kind {
        case .identifyAs(newAppUserID: let newAppUserID):
            let factory = LogInOperation.createFactory(configuration: config,
                                                       newAppUserID: newAppUserID,
                                                       loginCallbackCache: self.logInCallbacksCache)

            let loginCallback = LogInCallback(cacheKey: factory.cacheKey, completion: completion)
            let cacheStatus = self.logInCallbacksCache.add(loginCallback)

            self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
        case .switchTo(let token):
            let factory = TokenLogInOperation.createFactory(configuration: config,
                                                            token: token.authToken,
                                                            loginCallbackCache: self.logInCallbacksCache)

            let loginCallback = LogInCallback(cacheKey: factory.cacheKey, completion: completion)
            let cacheStatus = self.logInCallbacksCache.add(loginCallback)

            self.backendConfig.operationQueue.addCacheableOperation(with: factory, cacheStatus: cacheStatus)
        }
    }

    #warning("DAVE: STILL USED BY UNIT TESTS: BackendLoginTests.swift")
    func logIn(currentAppUserID: String,
               newAppUserID: String,
               completion: @escaping LogInResponseHandler) {
        let request = LogInRequest(currentAppUserID: currentAppUserID, kind: .identifyAs(newAppUserID: newAppUserID))
        self.logIn(request, completion: completion)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension IdentityAPI: @unchecked Sendable {}
