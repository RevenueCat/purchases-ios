//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2Listener.swift
//
//  Created by Andrés Boedo on 23/9/21.

import Foundation
@testable import RevenueCat
import StoreKit

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *)
class MockStoreKit2Listener: StoreKit2TransactionListener {

    convenience init() {
        self.init(delegate: nil)
    }

    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    var invokedDelegate: StoreKit2TransactionListenerDelegate?
    var invokedDelegateList = [StoreKit2TransactionListenerDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    var stubbedDelegate: StoreKit2TransactionListenerDelegate!

    override var delegate: StoreKit2TransactionListenerDelegate? {
        set {
            invokedDelegateSetter = true
            invokedDelegateSetterCount += 1
            invokedDelegate = newValue
            invokedDelegateList.append(newValue)
        }
        get {
            invokedDelegateGetter = true
            invokedDelegateGetterCount += 1
            return stubbedDelegate
        }
    }

    var invokedListenForTransactions = false
    var invokedListenForTransactionsCount = 0

    override func listenForTransactions() {
        invokedListenForTransactions = true
        invokedListenForTransactionsCount += 1
    }

    var invokedHandle = false
    var invokedHandleCount = 0
    var invokedHandleParameters: (purchaseResult: StoreKit.Product.PurchaseResult, Void)?
    var invokedHandleParametersList = [(purchaseResult: StoreKit.Product.PurchaseResult, Void)]()

    override func handle(purchaseResult: StoreKit.Product.PurchaseResult) async {
        invokedHandle = true
        invokedHandleCount += 1
        invokedHandleParameters = (purchaseResult, ())
        invokedHandleParametersList.append((purchaseResult, ()))
    }
}
