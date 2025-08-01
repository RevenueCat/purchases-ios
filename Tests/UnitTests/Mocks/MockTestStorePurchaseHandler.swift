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

    let stubbedPurchaseResult: Atomic<TestPurchaseResult> = .init(.cancel)
    private let invokedPurchase: Atomic<Bool> = .init(false)
    private let invokedPurchaseProduct: Atomic<TestStoreProduct?> = .init(nil)

    @MainActor
    func purchase(product: TestStoreProduct) async -> TestPurchaseResult {
        self.invokedPurchase.value = true
        self.invokedPurchaseProduct.value = product
        return self.stubbedPurchaseResult.value
    }

    #endif // TEST_STORE
}
