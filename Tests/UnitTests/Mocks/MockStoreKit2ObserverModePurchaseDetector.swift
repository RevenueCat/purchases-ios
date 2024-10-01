//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2ObserverModePurchaseDetector.swift
//
//  Created by Will Taylor on 5/1/24.

import Foundation
@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
// swiftlint:disable type_name
final actor MockStoreKit2ObserverModePurchaseDetector: StoreKit2ObserverModePurchaseDetectorType {

    var detectUnobservedTransactionsCalled = false
    var detectUnobservedTransactionsCalledCount = 0

    func detectUnobservedTransactions(delegate: (any StoreKit2ObserverModePurchaseDetectorDelegate)) async {
        detectUnobservedTransactionsCalled = true
        detectUnobservedTransactionsCalledCount += 1
    }
}
