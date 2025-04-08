//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2PurchaseIntentListener.swift
//
//  Created by Will Taylor on 10/24/24.

import Foundation

@testable import RevenueCat

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
class MockStoreKit2PurchaseIntentListener: StoreKit2PurchaseIntentListenerType {

    init() {}

    var listenForPurchaseIntentsCalled = false
    func listenForPurchaseIntents() async {
        self.listenForPurchaseIntentsCalled = true
    }

    var setDelegateCalled = false
    var lastProvidedDelegate: StoreKit2PurchaseIntentListenerDelegate?
    func set(delegate: StoreKit2PurchaseIntentListenerDelegate) async {
        self.setDelegateCalled = true
        self.lastProvidedDelegate = delegate
    }
}
