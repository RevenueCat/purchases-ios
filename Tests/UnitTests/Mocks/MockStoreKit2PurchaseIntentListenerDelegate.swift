//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2PurchaseIntentListenerDelegate.swift
//
//  Created by Will Taylor on 10/10/2024.

@testable import RevenueCat
import StoreKit

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
// swiftlint:disable:next type_name
final class MockStoreKit2PurchaseIntentListenerDelegate: StoreKit2PurchaseIntentListenerDelegate, @unchecked Sendable {

    var storeKit2PurchaseIntentListenerInvoked = false
    var storeKit2PurchaseIntentListenerInvokeCount = 0
    var storeKit2PurchaseIntentListenerPurchaseIntent: StorePurchaseIntent?
    func storeKit2PurchaseIntentListener(
        _ listener: any RevenueCat.StoreKit2PurchaseIntentListenerType,
        purchaseIntent: StorePurchaseIntent
    ) async {
        self.storeKit2PurchaseIntentListenerInvoked = true
        self.storeKit2PurchaseIntentListenerInvokeCount += 1
        self.storeKit2PurchaseIntentListenerPurchaseIntent = purchaseIntent
    }
}
