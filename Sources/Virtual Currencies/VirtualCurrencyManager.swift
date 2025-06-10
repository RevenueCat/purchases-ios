//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyManager.swift
//
//  Created by Will Taylor on 5/28/25.

import Foundation

protocol VirtualCurrencyManagerType {
    func virtualCurrencies(
        forceRefresh: Bool,
    ) async throws -> VirtualCurrencies
}

actor VirtualCurrencyManager: VirtualCurrencyManagerType, Sendable {

    private let identityManager: IdentityManager
    private let deviceCache: DeviceCache
    private let backend: Backend
    private let systemInfo: SystemInfo

    init(
        identityManager: IdentityManager,
        deviceCache: DeviceCache,
        backend: Backend,
        systemInfo: SystemInfo
    ) {
        self.identityManager = identityManager
        self.deviceCache = deviceCache
        self.backend = backend
        self.systemInfo = systemInfo
    }

    func virtualCurrencies(
        forceRefresh: Bool,
    ) async throws -> VirtualCurrencies {
        let appUserID = identityManager.currentAppUserID
        let isAppBackgrounded = await systemInfo.isApplicationBackgrounded()

        if !forceRefresh {
            if let cachedVirtualCurrencies = await fetchCachedVirtualCurrencies(
                appUserID: appUserID,
                isAppBackgrounded: isAppBackgrounded
            ) {
                return cachedVirtualCurrencies
            }
        }

        return try await fetchVirtualCurrenciesFromBackend(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded)
    }

    private func fetchCachedVirtualCurrencies(
        appUserID: String,
        isAppBackgrounded: Bool
    ) async -> VirtualCurrencies? {
        if self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded
        ) {
            // The virtual currencies cache is stale, so
            // return no cached virtual currencies.
            return nil
        }

        let cachedVirtualCurrenciesData = self.deviceCache.cachedVirtualCurrenciesData(
            forAppUserID: appUserID
        )

        guard let data = cachedVirtualCurrenciesData,
              let virtualCurrencies = try? JSONDecoder().decode(VirtualCurrencies.self, from: data) else {
            // We can't decode the cached virtual currencies, so return nil
            return nil
        }

        return virtualCurrencies
    }

    private func fetchVirtualCurrenciesFromBackend(
        appUserID: String,
        isAppBackgrounded: Bool
    ) async throws -> VirtualCurrencies {
        let virtualCurrenciesResponse = try await Async.call { completion in
            backend.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: appUserID,
                isAppBackgrounded: isAppBackgrounded
            ) { result in
                completion(result.mapError(\.asPurchasesError))
            }
        }

        return VirtualCurrencies(from: virtualCurrenciesResponse)
    }
}
