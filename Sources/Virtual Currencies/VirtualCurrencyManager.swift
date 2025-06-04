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
    private let systemInfo: SystemInfo

    init(
        identityManager: IdentityManager,
        deviceCache: DeviceCache,
        systemInfo: SystemInfo
    ) {
        self.identityManager = identityManager
        self.deviceCache = deviceCache
        self.systemInfo = systemInfo
    }

    func virtualCurrencies(
        forceRefresh: Bool,
    ) async throws -> VirtualCurrencies {
        let appUserID = identityManager.currentAppUserID

        if !forceRefresh {
            if let cachedVirtualCurrencies = await fetchCachedVirtualCurrencies(appUserID: appUserID) {
                return cachedVirtualCurrencies
            }
        }

        return try await fetchVirtualCurrenciesFromBackend()
    }

    private func fetchCachedVirtualCurrencies(
        appUserID: String
    ) async -> VirtualCurrencies? {
        return await withCheckedContinuation { continuation in
            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                if self.deviceCache.isVirtualCurrenciesCacheStale(
                    appUserID: appUserID,
                    isAppBackgrounded: isAppBackgrounded
                ) {
                    // The virtual currencies cache is stale, so
                    // return no cached virtual currencies.
                    continuation.resume(returning: nil)
                    return
                }

                let cachedVirtualCurrenciesData = self.deviceCache.cachedVirtualCurrenciesData(
                    forAppUserID: appUserID
                )

                guard let data = cachedVirtualCurrenciesData,
                      let virtualCurrencies = try? JSONDecoder().decode(VirtualCurrencies.self, from: data) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: virtualCurrencies)
            }
        }
    }

    private func fetchVirtualCurrenciesFromBackend() async throws -> VirtualCurrencies {
        #warning("TODO: implement fetchVirtualCurrenciesFromBackend")
        return VirtualCurrencies(virtualCurrencies: [:])
    }

}
