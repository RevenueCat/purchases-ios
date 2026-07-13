//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockIdentityAPI.swift
//
//  Created by Joshua Liebowitz on 6/16/22.

import Foundation
@testable import RevenueCat

class MockIdentityAPI: IdentityAPI {

    public convenience init() {
        self.init(backendConfig: MockBackendConfiguration())
    }

    var invokedLogIn = false
    var invokedLogInCount = 0
    var invokedLogInParameters: IdentityAPI.LogInRequest?
    var invokedLogInParametersList = [IdentityAPI.LogInRequest]()
    var stubbedLogInCompletionResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

    override func logIn(_ request: IdentityAPI.LogInRequest,
                        completion: @escaping IdentityAPI.LogInResponseHandler) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = request
        invokedLogInParametersList.append(request)
        if let result = stubbedLogInCompletionResult {
            completion(result)
        }
    }

}

extension MockIdentityAPI: @unchecked Sendable {}
