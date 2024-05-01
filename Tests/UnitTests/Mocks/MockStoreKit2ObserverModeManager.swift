//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2ObserverModeManager.swift
//
//  Created by Will Taylor on 5/1/24.

import Foundation
@testable import RevenueCat
import StoreKit

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class MockStoreKit2ObserverModeManager: StoreKit2ObserverModeManagerType {

    init() { }

    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    weak var invokedDelegate: StoreKit2ObserverModeManagerDelegate?
    var invokedDelegateList: [StoreKit2ObserverModeManagerDelegate] = []

    var invokedBeginObservingPurchases = false
    var invokedBeginObservingPurchasesCount = 0
    func beginObservingPurchases() {
        invokedBeginObservingPurchases = true
        invokedBeginObservingPurchasesCount += 1
    }

    func set(delegate: any RevenueCat.StoreKit2ObserverModeManagerDelegate) {
        self.invokedDelegateSetter = true
        self.invokedDelegateSetterCount += 1
        self.invokedDelegate = delegate
        self.invokedDelegateList.append(delegate)
    }
}
