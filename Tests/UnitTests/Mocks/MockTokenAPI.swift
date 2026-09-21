//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTokenAPI.swift
//
//  Created by RevenueCat on 8/18/26.

import Foundation
@testable @_spi(Internal) import RevenueCat

class MockTokenAPI: TokenAPI {

    public convenience init() {
        self.init(backendConfig: MockBackendConfiguration())
    }

    // MARK: - logIn(currentAppUserID:identity:completion:)

    var invokedLogIn = false
    var invokedLogInCount = 0
    var invokedLogInParameters: (currentAppUserID: String, identity: Identity)?
    var invokedLogInParametersList: [(currentAppUserID: String, identity: Identity)] = []
    var stubbedLogInCompletionResult: TokenResult?

    override func logIn(currentAppUserID: String, identity: Identity, completion: @escaping TokenResponseHandler) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = (currentAppUserID, identity)
        invokedLogInParametersList.append((currentAppUserID, identity))
        if let result = stubbedLogInCompletionResult {
            completion(result)
        }
    }

    // MARK: - revokeTokens(for:completion:)

    var invokedRevokeTokens = false
    var invokedRevokeTokensCount = 0
    var invokedRevokeTokensParametersList: [String] = []
    var stubbedRevokeTokensResult: BackendError?

    override func revokeTokens(for appUserID: String, completion: @escaping (BackendError?) -> Void) {
        invokedRevokeTokens = true
        invokedRevokeTokensCount += 1
        invokedRevokeTokensParametersList.append(appUserID)
        completion(stubbedRevokeTokensResult)
    }

}

extension MockTokenAPI: @unchecked Sendable {}
