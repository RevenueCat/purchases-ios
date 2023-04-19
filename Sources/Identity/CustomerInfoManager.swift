//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoManager.swift
//
//  Created by Joshua Liebowitz on 8/5/21.

import Foundation

class CustomerInfoManager {

    typealias CustomerInfoCompletion = @MainActor @Sendable (Result<CustomerInfo, BackendError>) -> Void

    var lastSentCustomerInfo: CustomerInfo? { return self.data.value.lastSentCustomerInfo }

    private let operationDispatcher: OperationDispatcher
    private let backend: Backend
    private let systemInfo: SystemInfo
    /// Underlying synchronized data.
    private let data: Atomic<Data>

    init(operationDispatcher: OperationDispatcher,
         deviceCache: DeviceCache,
         backend: Backend,
         systemInfo: SystemInfo) {
        self.operationDispatcher = operationDispatcher
        self.backend = backend
        self.systemInfo = systemInfo
        self.data = .init(.init(deviceCache: deviceCache))
    }

    func fetchAndCacheCustomerInfo(appUserID: String,
                                   isAppBackgrounded: Bool,
                                   completion: CustomerInfoCompletion?) {
        self.backend.getCustomerInfo(appUserID: appUserID,
                                     withRandomDelay: isAppBackgrounded) { result in
            switch result {
            case let .failure(error):
                self.withData { $0.deviceCache.clearCustomerInfoCacheTimestamp(appUserID: appUserID) }
                Logger.warn(Strings.customerInfo.customerinfo_updated_from_network_error(error))

            case let .success(info):
                self.cache(customerInfo: info, appUserID: appUserID)
                Logger.rcSuccess(Strings.customerInfo.customerinfo_updated_from_network)
            }

            if let completion = completion {
                self.operationDispatcher.dispatchOnMainActor {
                    completion(result)
                }
            }

        }
    }

    func fetchAndCacheCustomerInfoIfStale(appUserID: String,
                                          isAppBackgrounded: Bool,
                                          completion: CustomerInfoCompletion?) {
        let cachedCustomerInfo = self.cachedCustomerInfo(appUserID: appUserID)
        let isCacheStale = self.withData {
            $0.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded)
        }

        guard !isCacheStale, let customerInfo = cachedCustomerInfo else {
            Logger.debug(isAppBackgrounded
                            ? Strings.customerInfo.customerinfo_stale_updating_in_background
                            : Strings.customerInfo.customerinfo_stale_updating_in_foreground)
            self.fetchAndCacheCustomerInfo(appUserID: appUserID,
                                           isAppBackgrounded: isAppBackgrounded,
                                           completion: completion)
            return
        }

        if let completion = completion {
            self.operationDispatcher.dispatchOnMainActor {
                completion(.success(customerInfo))
            }
        }
    }

    func sendCachedCustomerInfoIfAvailable(appUserID: String) {
        guard let info = self.cachedCustomerInfo(appUserID: appUserID) else {
            return
        }

        self.sendUpdateIfChanged(customerInfo: info)
    }

    // swiftlint:disable:next function_body_length
    func customerInfo(
        appUserID: String,
        fetchPolicy: CacheFetchPolicy,
        completion: CustomerInfoCompletion?
    ) {
        switch fetchPolicy {
        case .fromCacheOnly:
            self.operationDispatcher.dispatchOnMainActor {
                completion?(
                    Result(self.cachedCustomerInfo(appUserID: appUserID), .missingCachedCustomerInfo())
                )
            }

        case .fetchCurrent:
            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.fetchAndCacheCustomerInfo(appUserID: appUserID,
                                               isAppBackgrounded: isAppBackgrounded,
                                               completion: completion)
            }

        case .cachedOrFetched:
            let infoFromCache = self.cachedCustomerInfo(appUserID: appUserID)
            var completionCalled = false

            if let infoFromCache = infoFromCache {
                Logger.debug(Strings.customerInfo.vending_cache)
                if let completion = completion {
                    completionCalled = true
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(.success(infoFromCache))
                    }
                }
            }

            // Prevent calling completion twice.
            let completionIfNotCalledAlready = completionCalled ? nil : completion

            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                      isAppBackgrounded: isAppBackgrounded,
                                                      completion: completionIfNotCalledAlready)
            }

        case .notStaleCachedOrFetched:
            let infoFromCache = self.cachedCustomerInfo(appUserID: appUserID)

            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                let isCacheStale = self.withData {
                    $0.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded)
                }

                if let infoFromCache = infoFromCache, !isCacheStale {
                    Logger.debug(Strings.customerInfo.vending_cache)
                    if let completion = completion {
                        self.operationDispatcher.dispatchOnMainActor {
                            completion(.success(infoFromCache))
                        }
                    }
                } else {
                    self.fetchAndCacheCustomerInfo(appUserID: appUserID,
                                                   isAppBackgrounded: isAppBackgrounded,
                                                   completion: completion)
                }
            }
        }
    }

    func cachedCustomerInfo(appUserID: String) -> CustomerInfo? {
        let cachedCustomerInfoData = self.withData {
            $0.deviceCache.cachedCustomerInfoData(appUserID: appUserID)
        }
        guard let customerInfoData = cachedCustomerInfoData else { return nil }

        do {
            let info: CustomerInfo = try JSONDecoder.default.decode(jsonData: customerInfoData)

            if info.schemaVersionIsCompatible {
                return info
            } else {
                return nil
            }
        } catch {
            Logger.error("Error loading customer info from cache:\n \(error.localizedDescription)")
            return nil
        }
    }

    func cache(customerInfo: CustomerInfo, appUserID: String) {
        do {
            let jsonData = try JSONEncoder.default.encode(customerInfo)
            self.withData { $0.deviceCache.cache(customerInfo: jsonData, appUserID: appUserID) }
            self.sendUpdateIfChanged(customerInfo: customerInfo)
        } catch {
            Logger.error(Strings.customerInfo.error_encoding_customerinfo(error))
        }
    }

    func clearCustomerInfoCache(forAppUserID appUserID: String) {
        self.modifyData {
            $0.deviceCache.clearCustomerInfoCache(appUserID: appUserID)
            $0.lastSentCustomerInfo = nil
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    var customerInfoStream: AsyncStream<CustomerInfo> {
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            if let lastSentCustomerInfo = self.lastSentCustomerInfo {
                continuation.yield(lastSentCustomerInfo)
            }

            let disposable = self.monitorChanges { continuation.yield($0) }

            continuation.onTermination = { @Sendable _ in disposable() }
        }
    }

    /// Allows monitoring changes to the active `CustomerInfo`.
    /// - Returns: closure that removes the created observation.
    func monitorChanges(_ changes: @escaping (CustomerInfo) -> Void) -> () -> Void {
        self.modifyData {
            let lastIdentifier = $0.customerInfoObserversByIdentifier.keys
                .sorted()
                .last
            let nextIdentifier = lastIdentifier
                .map { $0 + 1 } // Next index
            ?? 0 // Or default to 0

            $0.customerInfoObserversByIdentifier[nextIdentifier] = changes

            return { [weak self] in
                self?.removeObserver(with: nextIdentifier)
            }
        }
    }

    private func removeObserver(with identifier: Int) {
        self.modifyData {
            $0.customerInfoObserversByIdentifier.removeValue(forKey: identifier)
        }
    }

    private func sendUpdateIfChanged(customerInfo: CustomerInfo) {
        self.modifyData {
            guard !$0.customerInfoObserversByIdentifier.isEmpty,
                  $0.lastSentCustomerInfo != customerInfo else {
                      return
                  }

            if $0.lastSentCustomerInfo != nil {
                Logger.debug(Strings.customerInfo.sending_updated_customerinfo_to_delegate)
            } else {
                Logger.debug(Strings.customerInfo.sending_latest_customerinfo_to_delegate)
            }

            $0.lastSentCustomerInfo = customerInfo

            // This must be async to prevent deadlocks if the observer calls a method that ends up reading
            // this class' data. By making it async, the closure is invoked outside of the lock.
            self.operationDispatcher.dispatchAsyncOnMainThread { [observers = $0.customerInfoObserversByIdentifier] in
                for closure in observers.values {
                    closure(customerInfo)
                }
            }
        }
    }

}

extension CustomerInfoManager {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfo(
        appUserID: String,
        fetchPolicy: CacheFetchPolicy
    ) async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            return self.customerInfo(appUserID: appUserID,
                                     fetchPolicy: fetchPolicy,
                                     completion: { @Sendable in continuation.resume(with: $0) })
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension CustomerInfoManager: @unchecked Sendable {}

// MARK: -

private extension CustomerInfoManager {

    /// Underlying data for `CustomerInfoManager`.
    struct Data {

        let deviceCache: DeviceCache
        var lastSentCustomerInfo: CustomerInfo?
        /// Observers keyed by a monotonically increasing identifier.
        /// This allows cancelling observations by deleting them from this dictionary.
        /// These observers are used both for ``Purchases/customerInfoStream`` and
        /// `PurchasesDelegate/purchases(_:receivedUpdated:)``.
        var customerInfoObserversByIdentifier: [Int: (CustomerInfo) -> Void]

        init(deviceCache: DeviceCache) {
            self.deviceCache = deviceCache
            self.lastSentCustomerInfo = nil
            self.customerInfoObserversByIdentifier = [:]
        }

    }

    func withData<Result>(_ action: (Data) -> Result) -> Result {
        return self.data.withValue(action)
    }

    @discardableResult
    func modifyData<Result>(_ action: (inout Data) -> Result) -> Result {
        return self.data.modify(action)
    }
}
