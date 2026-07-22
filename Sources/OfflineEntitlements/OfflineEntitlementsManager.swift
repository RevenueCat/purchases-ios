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

    private var productEntitlementMappingTopicProvider: EntitlementMappingTopicProviderType?
    private let productEntitlementMappingTasksLock = Lock()
    private var productEntitlementMappingTasks: [UUID: Task<Void, Never>] = [:]
    private var completedProductEntitlementMappingTaskIDs: Set<UUID> = []
    private var isClosed = false

    init(deviceCache: DeviceCache,
         operationDispatcher: OperationDispatcher,
         api: OfflineEntitlementsAPI,
         systemInfo: SystemInfo) {
        self.deviceCache = deviceCache
        self.operationDispatcher = operationDispatcher
        self.api = api
        self.systemInfo = systemInfo
    }

    // Late-bound to break the OfflineEntitlementsManager → IdentityManager → RemoteConfigManager dependency cycle.
    func setProductEntitlementMappingTopicProvider(_ provider: EntitlementMappingTopicProviderType) {
        self.productEntitlementMappingTopicProvider = provider
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

        guard self.productEntitlementMappingTasksLock.perform({ !self.isClosed }) else { return }

        Logger.debug(Strings.offlineEntitlements.product_entitlement_mapping_stale_updating)

        guard let provider = self.productEntitlementMappingTopicProvider,
              provider.isAvailable else {
            self.productEntitlementMappingTasksLock.perform {
                guard !self.isClosed else { return }
                self.fetchLegacyProductEntitlementMapping(
                    isAppBackgrounded: isAppBackgrounded,
                    completion: completion
                )
            }
            return
        }

        let taskID = UUID()
        let task = Task { [weak self] in
            defer { self?.productEntitlementMappingTaskDidFinish(taskID) }
            guard let self else { return }

            if let result = await provider.getProductEntitlementMapping(),
               self.productEntitlementMappingTasksLock.perform({
                   guard !self.isClosed, !Task.isCancelled else { return false }
                   guard result.useIfCurrent({
                       self.handleProductEntitlementMappingBackendResult(with: $0)
                   }) else { return false }
                   self.dispatchCompletionOnMainThreadIfPossible(completion, result: .success(()))
                   return true
               }) {
                return
            }

            self.productEntitlementMappingTasksLock.perform {
                guard !self.isClosed, !Task.isCancelled else { return }
                self.fetchLegacyProductEntitlementMapping(
                    isAppBackgrounded: isAppBackgrounded,
                    completion: completion
                )
            }
        }
        self.registerProductEntitlementMappingTask(task, id: taskID)
    }

    func close() {
        let tasks = self.productEntitlementMappingTasksLock.perform {
            self.isClosed = true
            let tasks = Array(self.productEntitlementMappingTasks.values)
            self.productEntitlementMappingTasks.removeAll()
            self.completedProductEntitlementMappingTaskIDs.removeAll()
            return tasks
        }
        tasks.forEach { $0.cancel() }
    }

    private func registerProductEntitlementMappingTask(_ task: Task<Void, Never>, id: UUID) {
        let shouldCancel = self.productEntitlementMappingTasksLock.perform {
            if self.isClosed {
                self.completedProductEntitlementMappingTaskIDs.remove(id)
                return true
            }
            if self.completedProductEntitlementMappingTaskIDs.remove(id) != nil {
                return false
            }

            self.productEntitlementMappingTasks[id] = task
            return false
        }
        if shouldCancel {
            task.cancel()
        }
    }

    private func productEntitlementMappingTaskDidFinish(_ id: UUID) {
        self.productEntitlementMappingTasksLock.perform {
            if self.productEntitlementMappingTasks.removeValue(forKey: id) == nil, !self.isClosed {
                self.completedProductEntitlementMappingTaskIDs.insert(id)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func fetchLegacyProductEntitlementMapping(
        isAppBackgrounded: Bool,
        completion: (@MainActor @Sendable (Result<(), Error>) -> Void)?
    ) {
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
        return self.isOfflineEntitlementsEnabled() &&
        self.deviceCache.cachedCustomerInfoData(appUserID: appUserID) == nil
    }

    // We diable offline entitlements for the Test Store since there's no store where to store the client's purchases
    private func isOfflineEntitlementsEnabled() -> Bool {
        return !self.systemInfo.isSimulatedStoreAPIKey
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
