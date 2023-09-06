//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsManager.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

final class PaywallEventsManager {

    private let internalAPI: InternalAPI
    private let userProvider: CurrentUserProvider
    private let store: PaywallEventStoreType

    init(
        internalAPI: InternalAPI,
        userProvider: CurrentUserProvider,
        store: PaywallEventStoreType
    ) {
        self.internalAPI = internalAPI
        self.userProvider = userProvider
        self.store = store
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func track(paywallEvent: PaywallEvent) async {
        await self.store.store(.init(event: paywallEvent, userID: self.userProvider.currentAppUserID))
    }

    

}
