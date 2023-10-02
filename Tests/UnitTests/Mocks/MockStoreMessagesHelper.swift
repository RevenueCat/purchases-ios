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

class MockStoreMessagesHelper: StoreMessagesHelperType {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    var deferMessagesIfNeededCalled = false
    var deferMessagesIfNeededCallCount = 0

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func deferMessagesIfNeeded() {
        self.deferMessagesIfNeededCalled = true
        self.deferMessagesIfNeededCallCount += 1
    }

    var showStoreMessageCalled = false
    var showStoreMessageCallCount = 0

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showStoreMessages(types: Set<StoreMessageType>) {
        self.showStoreMessageCalled = true
        self.showStoreMessageCallCount += 1
    }

    #endif
}
