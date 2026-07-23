//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineEntitlementsManager.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation

class OfflineEntitlementsManager {

    private let deviceCache: DeviceCache
    private let api: OfflineEntitlementsAPI
    private let systemInfo: SystemInfo

    private var productEntitlementMappingTopicProvider: EntitlementMappingTopicProviderType?
    private let productEntitlementMappingLock = Lock()
    private var productEntitlementMappingTask: Task<Void, Never>?
    private var isClosed = false

    init(deviceCache: DeviceCache,
         api: OfflineEntitlementsAPI,
         systemInfo: SystemInfo) {
        self.deviceCache = deviceCache
        self.api = api
        self.systemInfo = systemInfo
    }

    // Late-bound to break the OfflineEntitlementsManager → IdentityManager → RemoteConfigManager dependency cycle.
    func setProductEntitlementMappingTopicProvider(_ provider: EntitlementMappingTopicProviderType) {
        self.productEntitlementMappingTopicProvider = provider
    }

    func updateProductsEntitlementsCacheIfStale(isAppBackgrounded: Bool) {
        guard #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
              self.systemInfo.supportsOfflineEntitlements else {
            Logger.debug(Strings.offlineEntitlements.product_entitlement_mapping_unavailable)
            return
        }

        guard self.deviceCache.isProductEntitlementMappingCacheStale else { return }

        Logger.debug(Strings.offlineEntitlements.product_entitlement_mapping_stale_updating)

        guard let provider = self.productEntitlementMappingTopicProvider,
              provider.isAvailable else {
            self.productEntitlementMappingLock.perform {
                guard !self.isClosed else { return }
                self.fetchLegacyProductEntitlementMapping(isAppBackgrounded: isAppBackgrounded)
            }
            return
        }

        self.productEntitlementMappingLock.perform {
            guard !self.isClosed, self.productEntitlementMappingTask == nil else { return }

            self.productEntitlementMappingTask = Task { [weak self, provider] in
                let remoteResult = await provider.getProductEntitlementMapping()
                guard let self else { return }

                await self.completeProductEntitlementMappingUpdate(
                    remoteResult: remoteResult, isAppBackgrounded: isAppBackgrounded
                )
            }
        }
    }

    func close() {
        let task = self.productEntitlementMappingLock.perform {
            self.isClosed = true
            let task = self.productEntitlementMappingTask
            self.productEntitlementMappingTask = nil
            return task
        }
        task?.cancel()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func completeProductEntitlementMappingUpdate(
        remoteResult: ProductEntitlementMappingResult?,
        isAppBackgrounded: Bool
    ) async {
        if let remoteResult {
            let didCacheRemoteResult = self.productEntitlementMappingLock.perform {
                guard !self.isClosed, !Task.isCancelled else { return false }
                guard remoteResult.useIfCurrent({
                    self.handleProductEntitlementMappingBackendResult(with: $0)
                }) else { return false }

                self.productEntitlementMappingTask = nil
                return true
            }
            if didCacheRemoteResult { return }
        }

        guard self.productEntitlementMappingLock.perform({
            !self.isClosed && !Task.isCancelled
        }) else {
            return
        }

        let result = await self.fetchLegacyProductEntitlementMappingResult(isAppBackgrounded: isAppBackgrounded)
        self.productEntitlementMappingLock.perform {
            guard !self.isClosed, !Task.isCancelled else { return }
            switch result {
            case let .success(response):
                self.handleProductEntitlementMappingBackendResult(with: response)

            case let .failure(error):
                self.handleProductsEntitlementsUpdateError(error)
            }

            self.productEntitlementMappingTask = nil
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func fetchLegacyProductEntitlementMapping(isAppBackgrounded: Bool) {
        self.api.getProductEntitlementMapping(isAppBackgrounded: isAppBackgrounded) { result in
            switch result {
            case let .success(response):
                self.handleProductEntitlementMappingBackendResult(with: response)

            case let .failure(error):
                self.handleProductsEntitlementsUpdateError(error)
            }
        }
    }

    private func fetchLegacyProductEntitlementMappingResult(
        isAppBackgrounded: Bool
    ) async -> Result<ProductEntitlementMappingResponse, BackendError> {
        return await withCheckedContinuation { continuation in
            self.api.getProductEntitlementMapping(isAppBackgrounded: isAppBackgrounded) {
                continuation.resume(returning: $0)
            }
        }
    }

    func shouldComputeOfflineCustomerInfo(appUserID: String) -> Bool {
        return self.isOfflineEntitlementsEnabled() &&
        self.deviceCache.cachedCustomerInfoData(appUserID: appUserID) == nil
    }

    // We diable offline entitlements for the Test Store since there's no store where to store the client's purchases
    private func isOfflineEntitlementsEnabled() -> Bool {
        return !self.systemInfo.isSimulatedStoreAPIKey
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension OfflineEntitlementsManager {

    func handleProductEntitlementMappingBackendResult(with response: ProductEntitlementMappingResponse) {
        Logger.debug(Strings.offlineEntitlements.product_entitlement_mapping_updated_from_network)

        self.deviceCache.store(productEntitlementMapping: response.toMapping())
    }

    func handleProductsEntitlementsUpdateError(_ error: BackendError) {
        Logger.error(Strings.offlineEntitlements.product_entitlement_mapping_fetching_error(error))
    }

}
