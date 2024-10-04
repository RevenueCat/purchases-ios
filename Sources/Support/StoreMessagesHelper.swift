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

    @available(iOS 16.0, tvOS 16.0, macOS 12.0, watchOS 8.0, *)
    func deferMessagesIfNeeded() async throws

    @available(iOS 16.0, tvOS 16.0, macOS 12.0, watchOS 8.0, *)
    func showStoreMessages(types: Set<StoreMessageType>) async

    #endif

}

@available(iOS 16.0, tvOS 16.0, macOS 12.0, watchOS 8.0, *)
actor StoreMessagesHelper: StoreMessagesHelperType {

    private let systemInfo: SystemInfo
    private let showStoreMessagesAutomatically: Bool
    private let storeMessagesProvider: StoreMessagesProviderType

    private var deferredMessages: [IdentifiableStoreMessage] = []

    init(systemInfo: SystemInfo,
         showStoreMessagesAutomatically: Bool,
         storeMessagesProvider: StoreMessagesProviderType = StoreMessagesProvider()) {
        self.systemInfo = systemInfo
        self.showStoreMessagesAutomatically = showStoreMessagesAutomatically
        self.storeMessagesProvider = storeMessagesProvider
    }

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    func deferMessagesIfNeeded() async throws {
        guard !self.showStoreMessagesAutomatically else {
            return
        }

        for try await message in self.storeMessagesProvider.messages {
            self.deferredMessages.append(IdentifiableStoreMessage(storeMessage: message))
        }
    }

    func showStoreMessages(types: Set<StoreMessageType>) async {
        var displayedMessages: [IdentifiableStoreMessage] = []
        for identifiableMessage in self.deferredMessages {
            if let messageType = identifiableMessage.storeMessage.reason.messageType, types.contains(messageType) {
                do {
                    try await identifiableMessage.storeMessage.display(in: self.systemInfo.currentWindowScene)
                    displayedMessages.append(identifiableMessage)
                } catch {
                    Logger.error(Strings.storeKit.error_displaying_store_message(error))
                }
            }
        }

        for message in displayedMessages {
            self.deferredMessages.removeAll(where: { $0.id == message.id })
        }
    }

    private struct IdentifiableStoreMessage: Identifiable {
        let id = UUID()
        let storeMessage: StoreMessage
    }

    #endif
}

@available(iOS 16.0, tvOS 16.0, macOS 12.0, watchOS 8.0, *)
extension StoreMessagesHelper: Sendable {}

protocol StoreMessagesProviderType: Sendable {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    var messages: AsyncStream<StoreMessage> { get }

    #endif
}

/// Abstraction over `StoreKit.Message`.
protocol StoreMessage: Sendable {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    var reason: Message.Reason { get }

    @available(iOS 16.0, *)
    @MainActor
    func display(in scene: UIWindowScene) throws

    #endif
}

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

@available(iOS 16.0, *)
extension StoreKit.Message: StoreMessage {}

#endif

private final class StoreMessagesProvider: StoreMessagesProviderType {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    var messages: AsyncStream<StoreMessage> {
        return Message.messages
            .map { $0 as StoreMessage }
            .toAsyncStream()
    }

    #endif
}
