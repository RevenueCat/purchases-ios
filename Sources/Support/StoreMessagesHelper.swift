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

protocol StoreMessagesHelperType {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func deferMessagesIfNeeded() async throws

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showStoreMessages(types: Set<StoreMessageType>) async

    #endif

}

actor StoreMessagesHelper: StoreMessagesHelperType {

    private let systemInfo: SystemInfo
    private let showStoreMessagesAutomatically: Bool
    private let storeMessagesProvider: StoreMessagesProviderType

    private var deferredMessages: [StoreMessage] = []

    init(systemInfo: SystemInfo,
         showStoreMessagesAutomatically: Bool,
         storeMessagesProvider: StoreMessagesProviderType = StoreMessagesProvider()) {
        self.systemInfo = systemInfo
        self.showStoreMessagesAutomatically = showStoreMessagesAutomatically
        self.storeMessagesProvider = storeMessagesProvider
    }

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func deferMessagesIfNeeded() async throws {
        guard !self.showStoreMessagesAutomatically else {
            return
        }

        for try await message in self.storeMessagesProvider.messages {
            self.deferredMessages.append(message)
        }
    }

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showStoreMessages(types: Set<StoreMessageType>) async {
        for message in self.deferredMessages {
            if let messageType = message.reason.messageType, types.contains(messageType) {
                do {
                    try await message.display(in: self.systemInfo.currentWindowScene)
                } catch {
                    Logger.error("Error displaying StoreKit message: \(error)")
                }
            }
        }
    }

    #endif
}

extension StoreMessagesHelper: Sendable {}

protocol StoreMessagesProviderType {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var messages: AsyncStream<StoreMessage> { get }

    #endif
}

/// Abstraction over `StoreKit.Message`.
protocol StoreMessage: Sendable {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

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

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

@available(iOS 16.0, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension StoreKit.Message: StoreMessage {}

#endif

private final class StoreMessagesProvider: StoreMessagesProviderType {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var messages: AsyncStream<StoreMessage> {
        return Message.messages
            .map { $0 as StoreMessage }
            .toAsyncStream()
    }

    #endif
}
