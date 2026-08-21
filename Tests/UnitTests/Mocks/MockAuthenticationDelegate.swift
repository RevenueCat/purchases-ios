//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockAuthenticationDelegate.swift
//
//  Created by RevenueCat on 8/13/26.

import Foundation

@_spi(Internal) @testable import RevenueCat

final class MockAuthenticationDelegate: NSObject, AuthenticationDelegate {

    private(set) var invokedAuthenticatorDidEncounterError = false
    private(set) var invokedAuthenticatorDidEncounterErrorCount = 0
    private(set) var invokedAuthenticatorDidEncounterErrorParametersList: [PublicError] = []

    func authenticatorDidEncounterError(_ error: PublicError) {
        self.invokedAuthenticatorDidEncounterError = true
        self.invokedAuthenticatorDidEncounterErrorCount += 1
        self.invokedAuthenticatorDidEncounterErrorParametersList.append(error)
    }

}
