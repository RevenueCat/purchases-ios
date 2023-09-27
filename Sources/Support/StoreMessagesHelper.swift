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

    private var _deferredMessages: [Any] = []

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    private var deferredMessages: [Message] {
        // swiftlint:disable:next force_cast
        return _deferredMessages as! [Message]
    }

    init(systemInfo: SystemInfo,
         showStoreMessagesAutomatically: Bool) {
        self.systemInfo = systemInfo
        self.showStoreMessagesAutomatically = showStoreMessagesAutomatically
    }

    @available(iOS 16.4, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func deferMessagesIfNeeded() async {
        guard self.showStoreMessagesAutomatically else {
            return
        }
        for await message in StoreKit.Message.messages {
            self._deferredMessages.append(message)
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
}
