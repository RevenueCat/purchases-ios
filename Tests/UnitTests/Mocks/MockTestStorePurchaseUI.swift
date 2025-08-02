//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTestStorePurchaseUI.swift
//
//  Created by Antonio Pallares on 1/8/25.

import Foundation
@testable import RevenueCat

final class MockTestStorePurchaseUI: TestStorePurchaseUI {

    // Wrapping a closure instead of the TestStorePurchaseUIResult directly to allow for async stubbing
    let stubbedPurchaseResult: Atomic<() async -> TestStorePurchaseUIResult> = .init({ return .simulateSuccess })
    let invokedPresentPurchaseUI: Atomic<Bool> = .init(false)
    let invokedPresentPurchaseUICount: Atomic<Int> = .init(0)
    let invokedPresentPurchaseUIProduct: Atomic<TestStoreProduct?> = .init(nil)

    func presentPurchaseUI(for product: TestStoreProduct) async -> TestStorePurchaseUIResult {
        self.invokedPresentPurchaseUI.value = true
        self.invokedPresentPurchaseUICount.value += 1
        self.invokedPresentPurchaseUIProduct.value = product
        return await self.stubbedPurchaseResult.value()
    }

}
