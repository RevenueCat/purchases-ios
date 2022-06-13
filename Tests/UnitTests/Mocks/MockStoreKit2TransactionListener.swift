//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2TransactionListener.swift
//
//  Created by Andrés Boedo on 23/9/21.

import Foundation
@testable import RevenueCat
import StoreKit

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *)
class MockStoreKit2TransactionListener: StoreKit2TransactionListener {

    convenience init() {
        self.init(delegate: nil)
    }

    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    weak var invokedDelegate: StoreKit2TransactionListenerDelegate?
    var invokedDelegateList = [StoreKit2TransactionListenerDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    weak var stubbedDelegate: StoreKit2TransactionListenerDelegate!

    // `StoreKit.Transaction` can't be stored directly as a property.
    // See https://openradar.appspot.com/radar?id=4970535809187840 / https://bugs.swift.org/browse/SR-15825
    var mockTransaction: Box<StoreKit.Transaction?> = .init(nil)

    override var delegate: StoreKit2TransactionListenerDelegate? {
        get {
            invokedDelegateGetter = true
            invokedDelegateGetterCount += 1
            return stubbedDelegate
        }
        set {
            invokedDelegateSetter = true
            invokedDelegateSetterCount += 1
            invokedDelegate = newValue
            invokedDelegateList.append(newValue)
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
    // `purchaseResult` can't be stored directly as a property.
    // See https://openradar.appspot.com/radar?id=4970535809187840
    var invokedHandleParameters: (purchaseResult: Box<StoreKit.Product.PurchaseResult>, Void)?
    var invokedHandleParametersList = [(purchaseResult: Box<StoreKit.Product.PurchaseResult>, Void)]()

    override func handle(
        purchaseResult: StoreKit.Product.PurchaseResult
    ) async throws -> ResultData {
        invokedHandle = true
        invokedHandleCount += 1
        invokedHandleParameters = (.init(purchaseResult), ())
        invokedHandleParametersList.append((.init(purchaseResult), ()))

        return (false, mockTransaction.value)
    }
}

// Workaround for https://openradar.appspot.com/radar?id=4970535809187840 / https://bugs.swift.org/browse/SR-15825
final class Box<T> {

    var value: T

    init(_ value: T) { self.value = value }

}
