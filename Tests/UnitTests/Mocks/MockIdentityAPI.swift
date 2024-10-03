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
    var invokedLogInParameters: (currentAppUserID: String, newAppUserID: String)?
    var invokedLogInParametersList = [(currentAppUserID: String, newAppUserID: String)]()
    var stubbedLogInCompletionResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

    override func logIn(currentAppUserID: String,
                        newAppUserID: String,
                        completion: @escaping LogInResponseHandler) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = (currentAppUserID, newAppUserID)
        invokedLogInParametersList.append((currentAppUserID, newAppUserID))
        if let result = stubbedLogInCompletionResult {
            completion(result)
        }
    }

}

extension MockIdentityAPI: @unchecked Sendable {}
