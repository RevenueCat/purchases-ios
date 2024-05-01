//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockAllTransactionsProvider.swift
//
//  Created by Will Taylor on 5/1/24.

import Foundation
@testable import RevenueCat
import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class MockAllTransactionsProvider: AllTransactionsProviderType {

    private let mockedTransactions: [StoreKit.VerificationResult<StoreKit.Transaction>]

    init(
        mockedTransactions: [StoreKit.VerificationResult<StoreKit.Transaction>]
    ) {
        self.mockedTransactions = mockedTransactions
    }

    func getAllTransactions() async -> [StoreKit.VerificationResult<StoreKit.Transaction>] {
        return mockedTransactions
    }
}
