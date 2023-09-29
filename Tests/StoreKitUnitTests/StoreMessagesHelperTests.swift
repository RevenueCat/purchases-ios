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

#if os(iOS)

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
    func testShowMessagesAfterDeferMessagesAndShowingMessagesAutomaticallyDoesNotShowsMessages() async throws {
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
        try await self.helper.deferMessagesIfNeeded()

        try await Task.sleep(nanoseconds: DispatchTimeInterval.milliseconds(50).nanoseconds)

        for message in messages {
            self.storeMessagesProvider.updatesPublisher.send(message)

            try await Task.sleep(nanoseconds: DispatchTimeInterval.milliseconds(50).nanoseconds)
        }
    }
}

@available(iOS 16.0, *)
private final class MockStoreMessage: @unchecked Sendable, StoreMessage {

    let reason: Message.Reason

    init(reason: Message.Reason) {
        self.reason = reason
    }

    var displayCalled = false
    var displayCallCount = 0
    @MainActor func display(in scene: UIWindowScene) throws {
        self.displayCalled = true
        self.displayCallCount += 1
    }
}

@available(iOS 15.0, *)
extension AsyncPublisher<PassthroughSubject<StoreMessage, Never>>.Iterator: StoreMessageAsyncIteratorProtocol {}

@available(iOS 15.0, *)
private struct MockStoreMessagesAsyncSequence: StoreMessageAsyncSequence {

    let publisher: PassthroughSubject<StoreMessage, Never>

    typealias AsyncIterator = AsyncPublisher<PassthroughSubject<StoreMessage, Never>>.Iterator

    func makeAsyncIterator() -> AsyncIterator {
        self.publisher.values.makeAsyncIterator()
    }

}

@available(iOS 15.0, *)
private final class MockStoreMessagesProvider: StoreMessagesProvider {

    let updatesPublisher = PassthroughSubject<StoreMessage, Never>()

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var messages: any StoreMessageAsyncSequence {
        MockStoreMessagesAsyncSequence(publisher: self.updatesPublisher)
    }
}

#endif
