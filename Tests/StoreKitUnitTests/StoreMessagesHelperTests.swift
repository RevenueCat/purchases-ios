//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreMessagesHelperTests.swift
//
//  Created by Antonio Rico Diez on 28/9/23.

import Combine
import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

@available(iOS 16.0, *)
class StoreMessagesHelperTests: TestCase {

    private var systemInfo: MockSystemInfo!
    private var storeMessagesProvider: MockStoreMessagesProvider!

    private var helper: StoreMessagesHelper!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.systemInfo = MockSystemInfo(finishTransactions: true)
        self.storeMessagesProvider = MockStoreMessagesProvider()
    }

    func testShowMessagesAfterDeferMessagesAndNotShowingMessagesAutomaticallyShowsFirstDeferredMessage() async throws {
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: .generic)
        let message2 = MockStoreMessage(reason: .priceIncreaseConsent)

        try await self.waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))

        expect(message1.displayCalled) == true
        expect(message2.displayCalled) == false
    }

    func testShowMessagesAfterDeferMessagesAndNotShowingMessagesAutomaticallyShowsSpecifiedMessages() async throws {
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: .generic)
        let message2 = MockStoreMessage(reason: .priceIncreaseConsent)

        try await self.waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: [.priceIncreaseConsent])

        expect(message1.displayCalled) == false
        expect(message2.displayCalled) == true
    }

    func testShowMessagesAfterDeferMessagesAndShowingMessagesAutomaticallyDoesNotShowMessages() async throws {
        self.createHelper(showStoreMessagesAutomatically: true)

        let message1 = MockStoreMessage(reason: .generic)
        let message2 = MockStoreMessage(reason: .priceIncreaseConsent)

        try await self.waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))

        expect(message1.displayCalled) == false
        expect(message2.displayCalled) == false
    }

    func testShowMessagesAfterDeferMessagesAndNoMessagesDoesNothing() async throws {
        self.createHelper(showStoreMessagesAutomatically: true)

        try await self.waitForDeferredMessages(messages: [])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))
    }

}

@available(iOS 16.0, *)
private extension StoreMessagesHelperTests {

    private func createHelper(showStoreMessagesAutomatically: Bool) {
        self.helper = StoreMessagesHelper(systemInfo: self.systemInfo,
                                          showStoreMessagesAutomatically: showStoreMessagesAutomatically,
                                          storeMessagesProvider: self.storeMessagesProvider)
    }

    private func waitForDeferredMessages(messages: [StoreMessage]) async throws {
        self.storeMessagesProvider.stubbedMessages = messages

        try await self.helper.deferMessagesIfNeeded()
    }

}

@available(iOS 16.0, *)
private final class MockStoreMessage: StoreMessage {

    let reason: Message.Reason

    init(reason: Message.Reason) {
        self.reason = reason
    }

    private let _displayCalled: Atomic<Bool> = false
    private let _displayCallCount: Atomic<Int> = .init(0)

    var displayCalled: Bool { return self._displayCalled.value }
    var displayCallCount: Int { return self._displayCallCount.value }

    @MainActor
    func display(in scene: UIWindowScene) throws {
        self._displayCalled.value = true
        self._displayCallCount.modify { $0 += 1 }
    }

}

@available(iOS 16.0, *)
private final class MockStoreMessagesProvider: StoreMessagesProviderType {

    var stubbedMessages: [StoreMessage] = []

    var messages: AsyncStream<StoreMessage> {
        MockAsyncSequence(with: self.stubbedMessages).toAsyncStream()
    }
}

#endif
