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

    typealias LogInParameters = (
        currentAppUserID: String,
        newAppUserID: String,
        attributes: SubscriberAttribute.Dictionary,
        previousUnsyncedAttributes: SubscriberAttribute.Dictionary
    )

    var invokedLogIn = false
    var invokedLogInCount = 0
    var invokedLogInParameters: LogInParameters?
    var invokedLogInParametersList = [LogInParameters]()
    var stubbedLogInCompletionResult: IdentityAPI.LogInResponse?

    override func logIn(currentAppUserID: String,
                        newAppUserID: String,
                        attributes: SubscriberAttribute.Dictionary,
                        previousUnsyncedAttributes: SubscriberAttribute.Dictionary,
                        completion: @escaping LogInResponseHandler) {
        invokedLogIn = true
        invokedLogInCount += 1
        invokedLogInParameters = (currentAppUserID, newAppUserID, attributes, previousUnsyncedAttributes)
        invokedLogInParametersList.append(
            (currentAppUserID, newAppUserID, attributes, previousUnsyncedAttributes)
        )
        if let result = stubbedLogInCompletionResult {
            completion(result)
        }
    }

}

extension MockIdentityAPI: @unchecked Sendable {}
