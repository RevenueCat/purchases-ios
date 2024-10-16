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
    private let operationDispatcher: OperationDispatcher
    private let api: OfflineEntitlementsAPI
    private let systemInfo: SystemInfo

    init(deviceCache: DeviceCache,
         operationDispatcher: OperationDispatcher,
         api: OfflineEntitlementsAPI,
         systemInfo: SystemInfo) {
        self.deviceCache = deviceCache
        self.operationDispatcher = operationDispatcher
        self.api = api
        self.systemInfo = systemInfo
    }

    func updateProductsEntitlementsCacheIfStale(
        isAppBackgrounded: Bool,
        completion: (@MainActor @Sendable (Result<(), Error>) -> Void)?
    ) {
        guard #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
              self.systemInfo.supportsOfflineEntitlements else {
            Logger.debug(Strings.offlineEntitlements.product_entitlement_mapping_unavailable)

            self.dispatchCompletionOnMainThreadIfPossible(completion, result: .failure(.notAvailable))
            return
        }

        guard self.deviceCache.isProductEntitlementMappingCacheStale else {
            self.dispatchCompletionOnMainThreadIfPossible(completion, result: .success(()))
            return
        }

        Logger.debug(Strings.offlineEntitlements.product_entitlement_mapping_stale_updating)

        self.api.getProductEntitlementMapping(isAppBackgrounded: isAppBackgrounded) { result in
            switch result {
            case let .success(response):
                self.handleProductEntitlementMappingBackendResult(with: response)

            case let .failure(error):
                self.handleProductsEntitlementsUpdateError(error)
            }

            self.dispatchCompletionOnMainThreadIfPossible(
                completion,
                result: result
                    .map { _ in () }
                    .mapError(Error.backend)
            )
        }
    }

    func shouldComputeOfflineCustomerInfo(appUserID: String) -> Bool {
        return self.deviceCache.cachedCustomerInfoData(appUserID: appUserID) == nil
    }

}

extension OfflineEntitlementsManager {

    enum Error: Swift.Error {

        case backend(BackendError)
        /// Offline entitlements require iOS 15+, and not available for custom entitlements computation
        case notAvailable

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

private extension OfflineEntitlementsManager {

    func dispatchCompletionOnMainThreadIfPossible<Value, Error: Swift.Error>(
        _ completion: (@MainActor @Sendable (Result<Value, Error>) -> Void)?,
        result: Result<Value, Error>
    ) {
        if let completion = completion {
            self.operationDispatcher.dispatchOnMainActor {
                completion(result)
            }
        }
    }

}
