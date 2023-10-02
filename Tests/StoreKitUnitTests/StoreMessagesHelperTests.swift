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

@available(iOS 15.0, *)
class StoreMessagesHelperTests: TestCase {

    private var systemInfo: MockSystemInfo!
    private var storeMessagesProvider: MockStoreMessagesProvider!

    private var helper: StoreMessagesHelper!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo = MockSystemInfo(finishTransactions: true)
        self.storeMessagesProvider = MockStoreMessagesProvider()
    }

    @available(iOS 16.4, *)
    func testShowMessagesAfterDeferMessagesAndNotShowingMessagesAutomaticallyShowsAllDeferredMessages() async throws {
        try AvailabilityChecks.iOS16_4APIAvailableOrSkipTest()
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: Message.Reason.billingIssue)
        let message2 = MockStoreMessage(reason: Message.Reason.priceIncreaseConsent)

        try await waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))

        expect(message1.displayCalled) == true
        expect(message2.displayCalled) == true
    }

    @available(iOS 16.4, *)
    func testShowMessagesAfterDeferMessagesAndNotShowingMessagesAutomaticallyShowsSpecifiedMessages() async throws {
        try AvailabilityChecks.iOS16_4APIAvailableOrSkipTest()
        self.createHelper(showStoreMessagesAutomatically: false)

        let message1 = MockStoreMessage(reason: Message.Reason.billingIssue)
        let message2 = MockStoreMessage(reason: Message.Reason.priceIncreaseConsent)

        try await waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: [StoreMessageType.billingIssue])

        expect(message1.displayCalled) == true
        expect(message2.displayCalled) == false
    }

    @available(iOS 16.4, *)
    func testShowMessagesAfterDeferMessagesAndShowingMessagesAutomaticallyDoesNotShowMessages() async throws {
        try AvailabilityChecks.iOS16_4APIAvailableOrSkipTest()
        self.createHelper(showStoreMessagesAutomatically: true)

        let message1 = MockStoreMessage(reason: Message.Reason.billingIssue)
        let message2 = MockStoreMessage(reason: Message.Reason.priceIncreaseConsent)

        try await waitForDeferredMessages(messages: [message1, message2])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))

        expect(message1.displayCalled) == false
        expect(message2.displayCalled) == false
    }

    @available(iOS 16.4, *)
    func testShowMessagesAfterDeferMessagesAndNoMessagesDoesNothing() async throws {
        try AvailabilityChecks.iOS16_4APIAvailableOrSkipTest()
        self.createHelper(showStoreMessagesAutomatically: true)

        try await waitForDeferredMessages(messages: [])

        await self.helper.showStoreMessages(types: Set(StoreMessageType.allCases))
    }

    @available(iOS 16.4, *)
    private func createHelper(showStoreMessagesAutomatically: Bool) {
        self.helper = StoreMessagesHelper(systemInfo: self.systemInfo,
                                          showStoreMessagesAutomatically: showStoreMessagesAutomatically,
                                          storeMessagesProvider: self.storeMessagesProvider)
    }

    @available(iOS 16.4, *)
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

@available(iOS 15.0, *)
private final class MockStoreMessagesProvider: StoreMessagesProviderType {

    var stubbedMessages: [StoreMessage] = []

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var messages: AsyncStream<StoreMessage> {
        MockAsyncSequence(with: self.stubbedMessages).toAsyncStream()
    }
}

#endif
