//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberDimensionsProvider.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

import Foundation

enum SubscriberDimensionsProviderError: Error, Equatable, Sendable {

    case configurationUnavailable

}

/// Supplies the fresher config or purchase-response subscriber dimensions as root-level rule values.
struct SubscriberDimensionsProvider: DimensionProvider {

    let name = "subscriber_dimensions"

    private let store: any SubscriberDimensionsStoreType
    private let currentUserProvider: any CurrentUserProvider
    private let configProvider: any SubscriberDimensionsConfigProviderType

    init(
        store: any SubscriberDimensionsStoreType,
        currentUserProvider: CurrentUserProvider,
        configProvider: any SubscriberDimensionsConfigProviderType
    ) {
        self.store = store
        self.currentUserProvider = currentUserProvider
        self.configProvider = configProvider
    }

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        let appUserID = self.currentUserProvider.currentAppUserID
        let stored = self.store.dimensions(appUserID: appUserID)
        let configResolution = try await self.configProvider.dimensions()

        switch configResolution {
        case .resolved(let configured):
            guard let stored, configured.asOf > stored.asOf else {
                return stored?.values ?? configured.values
            }
            self.store.discard(appUserID: appUserID, ifNotNewerThan: stored.asOf)
            return configured.values
        case .notConfigured:
            return stored?.values ?? [:]
        case .unavailable:
            throw SubscriberDimensionsProviderError.configurationUnavailable
        }
    }

}
