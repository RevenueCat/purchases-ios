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

    private(set) var invokedAuthenticatorDidChangeIdentity = false
    private(set) var invokedAuthenticatorDidChangeIdentityCount = 0

    /// The result that will be handed to the completion passed to ``authenticatorDidChangeIdentity(completion:)``.
    /// If left `nil`, the completion is never invoked, to make it easy to test that a caller correctly
    /// waits for this delegate callback.
    var stubbedAuthenticatorDidChangeIdentityResult: Result<CustomerInfo, PublicError>?

    func authenticatorDidChangeIdentity(completion: @escaping (Result<CustomerInfo, PublicError>) -> Void) {
        self.invokedAuthenticatorDidChangeIdentity = true
        self.invokedAuthenticatorDidChangeIdentityCount += 1

        if let result = self.stubbedAuthenticatorDidChangeIdentityResult {
            completion(result)
        }
    }

}
