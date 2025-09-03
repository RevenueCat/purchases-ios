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
    func virtualCurrencies() async throws -> VirtualCurrencies

    func cachedVirtualCurrencies() -> VirtualCurrencies?

    func invalidateVirtualCurrenciesCache()
}

class VirtualCurrencyManager: VirtualCurrencyManagerType {

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

    func virtualCurrencies() async throws -> VirtualCurrencies {
        let appUserID = identityManager.currentAppUserID
        let isAppBackgrounded = systemInfo.isAppBackgroundedState

        if let cachedVirtualCurrencies = fetchCachedVirtualCurrencies(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded
        ) {
            Logger.debug(Strings.virtualCurrencies.vending_from_cache)
            return cachedVirtualCurrencies
        }

        let virtualCurrencies = try await fetchVirtualCurrenciesFromBackend(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded
        )

        cacheVirtualCurrencies(virtualCurrencies, appUserID: appUserID)

        return virtualCurrencies
    }

    func cachedVirtualCurrencies() -> VirtualCurrencies? {
        let appUserID = identityManager.currentAppUserID
        if let cachedVirtualCurrencies = fetchCachedVirtualCurrencies(
            appUserID: appUserID,
            isAppBackgrounded: systemInfo.isAppBackgroundedState,
            allowStaleCache: true
        ) {
            Logger.debug(Strings.virtualCurrencies.vending_from_cache)
            return cachedVirtualCurrencies
        } else {
            return nil
        }
    }

    func invalidateVirtualCurrenciesCache() {
        Logger.debug(Strings.virtualCurrencies.invalidating_virtual_currencies_cache)
        let appUserID = identityManager.currentAppUserID
        deviceCache.clearVirtualCurrenciesCache(appUserID: appUserID)
    }

    private func cacheVirtualCurrencies(
        _ virtualCurrencies: VirtualCurrencies,
        appUserID: String
    ) {
        guard let virtualCurrenciesData = try? JSONEncoder().encode(virtualCurrencies) else {
            return
        }

        self.deviceCache.cache(virtualCurrencies: virtualCurrenciesData, appUserID: appUserID)
    }

    private func fetchCachedVirtualCurrencies(
        appUserID: String,
        isAppBackgrounded: Bool,
        allowStaleCache: Bool = false
    ) -> VirtualCurrencies? {
        if !allowStaleCache && self.deviceCache.isVirtualCurrenciesCacheStale(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded
        ) {
            // The virtual currencies cache is stale and we don't want to fetch stale data,
            // so return no cached virtual currencies.
            Logger.debug(Strings.virtualCurrencies.virtual_currencies_stale_updating_from_network)
            return nil
        }

        let cachedVirtualCurrenciesData = self.deviceCache.cachedVirtualCurrenciesData(
            forAppUserID: appUserID
        )

        guard let data = cachedVirtualCurrenciesData else {
            Logger.debug(Strings.virtualCurrencies.no_cached_virtual_currencies)
            return nil
        }

        do {
            let virtualCurrencies = try JSONDecoder().decode(VirtualCurrencies.self, from: data)
            return virtualCurrencies
        } catch {
            Logger.warn(Strings.virtualCurrencies.error_decoding_cached_virtual_currencies(error))
            // We can't decode the cached virtual currencies, so return nil and refresh
            // from the network.
            return nil
        }

    }

    private func fetchVirtualCurrenciesFromBackend(
        appUserID: String,
        isAppBackgrounded: Bool
    ) async throws -> VirtualCurrencies {

        do {
            let virtualCurrenciesResponse = try await Async.call { completion in
                backend.virtualCurrenciesAPI.getVirtualCurrencies(
                    appUserID: appUserID,
                    isAppBackgrounded: isAppBackgrounded
                ) { result in
                    completion(result.mapError(\.asPurchasesError))
                }
            }

            Logger.debug(Strings.virtualCurrencies.virtual_currencies_updated_from_network)
            return VirtualCurrencies(from: virtualCurrenciesResponse)
        } catch {
            Logger.error(Strings.virtualCurrencies.virtual_currencies_updated_from_network_error(error))

            throw error
        }
    }
}
