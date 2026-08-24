//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockInternalAuthenticatorDelegate.swift
//
//  Created by RevenueCat on 8/13/26.

@testable import RevenueCat

final class MockInternalAuthenticatorDelegate: InternalAuthenticatorDelegate {

    private(set) var invokedAuthenticatorDidLogIn = false
    private(set) var invokedAuthenticatorDidLogInCount = 0
    private(set) var invokedAuthenticatorDidLogInParametersList: [CustomerInfo] = []

    func authenticatorDidLogIn(info: CustomerInfo) {
        self.invokedAuthenticatorDidLogIn = true
        self.invokedAuthenticatorDidLogInCount += 1
        self.invokedAuthenticatorDidLogInParametersList.append(info)
    }

    private(set) var invokedAuthenticatorDidLogOut = false
    private(set) var invokedAuthenticatorDidLogOutCount = 0

    /// The result that will be handed to the completion passed to ``authenticatorDidLogOut(completion:)``.
    /// If left `nil`, the completion is never invoked, to make it easy to test that a caller correctly
    /// waits for this delegate callback.
    var stubbedAuthenticatorDidLogOutResult: Result<CustomerInfo, PublicError>?

    func authenticatorDidLogOut(completion: @escaping (Result<CustomerInfo, PublicError>) -> Void) {
        self.invokedAuthenticatorDidLogOut = true
        self.invokedAuthenticatorDidLogOutCount += 1

        if let result = self.stubbedAuthenticatorDidLogOutResult {
            completion(result)
        }
    }

}
