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

    private let deviceCache: DeviceCache

    init(
        deviceCache: DeviceCache
    ) {
        self.deviceCache = deviceCache
    }

    func virtualCurrencies(
        forceRefresh: Bool,
    ) async throws -> VirtualCurrencies {
        if !forceRefresh {
            if let cachedVirtualCurrencies = fetchCachedVirtualCurrencies() {
                return cachedVirtualCurrencies
            }
        }

        return try await fetchVirtualCurrenciesFromBackend()
    }

    private func fetchCachedVirtualCurrencies() -> VirtualCurrencies? {
        #warning("TODO: Implement fetchCachedVirtualCurrencies")
        return nil
    }

    private func fetchVirtualCurrenciesFromBackend() async throws -> VirtualCurrencies {
        #warning("TODO: implement fetchVirtualCurrenciesFromBackend")
        throw NSError(domain: "", code: -1)
    }

}
