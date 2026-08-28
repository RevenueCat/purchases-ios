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

    private(set) var invokedAuthenticatorDidChangeIdentity = false
    private(set) var invokedAuthenticatorDidChangeIdentityCount = 0
    private(set) var invokedAuthenticatorDidChangeIdentityParametersList: [IdentityChangeReason] = []

    /// The result that will be handed to the `didHandle` closure passed to
    /// ``authenticatorDidChangeIdentity(reason:didHandle:)``.
    /// If left `nil`, `didHandle` is invoked with `nil`, mirroring the real delegate's behavior when there
    /// isn't a more specific `CustomerInfo` to hand back (e.g. after a `.logIn`, where the SDK falls back
    /// to the `CustomerInfo` it already has).
    var stubbedAuthenticatorDidChangeIdentityResult: Result<CustomerInfo, PublicError>?

    func authenticatorDidChangeIdentity(reason: IdentityChangeReason,
                                        didHandle: @escaping (Result<CustomerInfo, PublicError>?) -> Void) {
        self.invokedAuthenticatorDidChangeIdentity = true
        self.invokedAuthenticatorDidChangeIdentityCount += 1
        self.invokedAuthenticatorDidChangeIdentityParametersList.append(reason)

        didHandle(self.stubbedAuthenticatorDidChangeIdentityResult)
    }

}
