//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitMessagesHelper.swift
//
//  Created by Antonio Rico Diez on 27/9/23.

import StoreKit

class StoreKitMessagesHelper {

    private let systemInfo: SystemInfo
    private let showStoreKitMessagesAutomatically: Bool

    // TODO: Need to improve this :/
    private var deferredMessages: [Any] = []

    init(systemInfo: SystemInfo,
         showStoreKitMessagesAutomatically: Bool) {
        self.systemInfo = systemInfo
        self.showStoreKitMessagesAutomatically = showStoreKitMessagesAutomatically
    }
}

@available(iOS 16.4, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension StoreKitMessagesHelper {

    func deferMessagesIfNeeded() async {
        guard self.showStoreKitMessagesAutomatically else {
            return
        }
        for await message in StoreKit.Message.messages {
            self.deferredMessages.append(message)
        }
    }

    @MainActor
    func showStoreKitMessage(types: Set<StoreKitMessageType>) {
        for message in self.deferredMessages {
            if let message = message as? Message {
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
    }
}
