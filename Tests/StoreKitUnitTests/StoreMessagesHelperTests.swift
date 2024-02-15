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

    func testShowMessagesAfterDeferMessagesAndNotShowingMessagesAutomaticallyShowsAllDeferredMessages() async throws {
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: .generic)
        let message2 = MockStoreMessage(reason: .priceIncreaseConsent)

        try await self.waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))

        expect(message1.displayCalled) == true
        expect(message2.displayCalled) == true
    }

    func testShowMessagesAfterDeferMessagesAndNotShowingMessagesAutomaticallyShowsSpecifiedMessages() async throws {
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: .generic)
        let message2 = MockStoreMessage(reason: .priceIncreaseConsent)

        try await self.waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: [.generic])

        expect(message1.displayCalled) == true
        expect(message2.displayCalled) == false
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

    func testShowMessagesAfterShowMessagesDoesNotCallDisplayMultipleTimes() async throws {
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: .generic)
        let message2 = MockStoreMessage(reason: .priceIncreaseConsent)

        try await self.waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))
        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))

        expect(message1.displayCallCount) == 1
        expect(message2.displayCallCount) == 1
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

    // The indirection prevents a runtime Swift crash on iOS 15
    var reason: Message.Reason { self._reason.value }
    private let _reason: Box<Message.Reason>

    init(reason: Message.Reason) {
        self._reason = .init(reason)
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

    private let _stubbedMessages: Atomic<[StoreMessage]> = .init([])
    var stubbedMessages: [StoreMessage] {
        get { return self._stubbedMessages.value }
        set { self._stubbedMessages.value = newValue }
    }

    var messages: AsyncStream<StoreMessage> {
        MockAsyncSequence(with: self.stubbedMessages).toAsyncStream()
    }
}

#endif
