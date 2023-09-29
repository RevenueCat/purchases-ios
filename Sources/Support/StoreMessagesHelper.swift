//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreMessagesHelper.swift
//
//  Created by Antonio Rico Diez on 27/9/23.

import StoreKit

class StoreMessagesHelper {

    private let systemInfo: SystemInfo
    private let showStoreMessagesAutomatically: Bool
    private let storeMessagesProvider: StoreMessagesProvider

    private var deferredMessages: [StoreMessage] = []

    init(systemInfo: SystemInfo,
         showStoreMessagesAutomatically: Bool) {
        self.systemInfo = systemInfo
        self.showStoreMessagesAutomatically = showStoreMessagesAutomatically
        self.storeMessagesProvider = StoreMessagesProviderWrapper()
    }

    @available(iOS 16.0, *)
    init(systemInfo: SystemInfo,
         showStoreMessagesAutomatically: Bool,
         storeMessagesProvider: StoreMessagesProvider = StoreMessagesProviderWrapper()) {
        self.systemInfo = systemInfo
        self.showStoreMessagesAutomatically = showStoreMessagesAutomatically
        self.storeMessagesProvider = storeMessagesProvider
    }

    #if os(iOS)

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func deferMessagesIfNeeded() async throws {
        guard !self.showStoreMessagesAutomatically else {
            return
        }
        Task(priority: .background) { [weak self] in
            guard let storeMessagesProvider = self?.storeMessagesProvider else {
                return
            }
            for try await message in storeMessagesProvider.messages {
                await MainActor.run { [weak self] in
                    self?.deferredMessages.append(message)
                }
            }
        }
    }

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @MainActor
    func showStoreMessages(types: Set<StoreMessageType>) {
        for message in self.deferredMessages {
            if let messageType = message.reason.messageType {
                if types.contains(messageType) {
                    do {
                        try message.display(in: self.systemInfo.currentWindowScene)
                    } catch {
                        Logger.error("Error displaying StoreKit message: \(error)")
                    }
                }
            }
        }
    }

    #endif
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
// - It has mutable `_deferredMessages` which is necessary due to the availability annotations.
extension StoreMessagesHelper: @unchecked Sendable {}

protocol StoreMessagesProvider {

    #if os(iOS)

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var messages: any StoreMessageAsyncSequence { get }

    #endif
}

protocol StoreMessage: Sendable {

    #if os(iOS)

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var reason: Message.Reason { get }

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @MainActor func display(in scene: UIWindowScene) throws

    #endif
}

#if os(iOS)

@available(iOS 13.0, *)
@rethrows protocol StoreMessageAsyncIteratorProtocol: AsyncIteratorProtocol where Element == StoreMessage { }

@available(iOS 13.0, *)
@rethrows protocol StoreMessageAsyncSequence: AsyncSequence where AsyncIterator: StoreMessageAsyncIteratorProtocol { }

@available(iOS 16.0, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private final class StoreMessageWrapper: StoreMessage {

    private let message: Message

    init(message: Message) {
        self.message = message
    }

    var reason: Message.Reason {
        return self.message.reason
    }

    func display(in scene: UIWindowScene) throws {
        try self.message.display(in: scene)
    }
}

@available(iOS 16.0, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private struct StoreMessageSequence: StoreMessageAsyncSequence {

    struct AsyncIterator: StoreMessageAsyncIteratorProtocol {

        var iterator: StoreKit.Message.Messages.AsyncIterator

        mutating func next() async -> StoreMessage? {
            await iterator.next().map {
                StoreMessageWrapper(message: $0)
            }
        }

    }

    let underlyingSequence: Message.Messages

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(iterator: underlyingSequence.makeAsyncIterator())
    }

}

#endif

private final class StoreMessagesProviderWrapper: StoreMessagesProvider {

    #if os(iOS)

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var messages: any StoreMessageAsyncSequence {
        return StoreMessageSequence(underlyingSequence: Message.messages)
    }

    #endif
}
