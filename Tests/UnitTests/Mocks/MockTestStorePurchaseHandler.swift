//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTestStorePurchaseHandler.swift
//
//  Created by Antonio Pallares on 21/7/25.

import Foundation
@testable import RevenueCat

actor MockTestStorePurchaseHandler: TestStorePurchaseHandlerType {

    #if TEST_STORE

    var stubbedPurchaseResult: TestPurchaseResult = .cancel
    private var invokedPurchase: Bool = false
    private var invokedPurchaseProduct: TestStoreProduct?

    @MainActor
    func purchase(product: TestStoreProduct, completion: @escaping (TestPurchaseResult) -> Void) throws {
        Task {
            await self.didInvokePurchase(product: product)
            await completion(self.stubbedPurchaseResult)
        }
    }

    private func didInvokePurchase(product: TestStoreProduct) {
        self.invokedPurchase = true
        self.invokedPurchaseProduct = product
    }

    #endif // TEST_STORE
}
