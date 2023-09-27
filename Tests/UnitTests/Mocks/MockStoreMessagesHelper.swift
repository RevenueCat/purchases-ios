//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreMessagesHelper.swift
//
//  Created by Antonio Rico Diez on 27/9/23.

import Foundation

class MockStoreMessagesHelper: StoreMessagesHelper {

    var deferMessagesIfNeededCalled = false
    var deferMessagesIfNeededCallCount = 0

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func deferMessagesIfNeeded() async {
        self.deferMessagesIfNeededCalled = true
        self.deferMessagesIfNeededCallCount += 1
    }

    var showStoreMessageCalled = false
    var showStoreMessageCallCount = 0

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func showStoreMessages(types: Set<StoreMessageType>) {
        self.showStoreMessageCalled = true
        self.showStoreMessageCallCount += 1
    }
}
