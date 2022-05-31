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

    private(set) var lastSentCustomerInfo: CustomerInfo?
    private let operationDispatcher: OperationDispatcher
    private let deviceCache: DeviceCache
    private let backend: Backend
    private let systemInfo: SystemInfo
    private let customerInfoCacheLock = Lock()

    init(operationDispatcher: OperationDispatcher,
         deviceCache: DeviceCache,
         backend: Backend,
         systemInfo: SystemInfo) {
        self.operationDispatcher = operationDispatcher
        self.deviceCache = deviceCache
        self.backend = backend
        self.systemInfo = systemInfo
    }

    func fetchAndCacheCustomerInfo(appUserID: String,
                                   isAppBackgrounded: Bool,
                                   completion: ((Result<CustomerInfo, BackendError>) -> Void)?) {
        deviceCache.setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: appUserID)
        operationDispatcher.dispatchOnWorkerThread(withRandomDelay: isAppBackgrounded) {
            self.backend.getCustomerInfo(appUserID: appUserID) { result in
                switch result {
                case let .failure(error):
                    self.deviceCache.clearCustomerInfoCacheTimestamp(appUserID: appUserID)
                    Logger.warn(Strings.customerInfo.customerinfo_updated_from_network_error(error: error))

                case let .success(info):
                    self.cache(customerInfo: info, appUserID: appUserID)
                    Logger.rcSuccess(Strings.customerInfo.customerinfo_updated_from_network)
                }

                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(result)
                    }
                }

            }
        }
    }

    func fetchAndCacheCustomerInfoIfStale(appUserID: String,
                                          isAppBackgrounded: Bool,
                                          completion: ((Result<CustomerInfo, BackendError>) -> Void)?) {
        let cachedCustomerInfo = cachedCustomerInfo(appUserID: appUserID)
        let isCacheStale = deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                                isAppBackgrounded: isAppBackgrounded)

        guard !isCacheStale, let customerInfo = cachedCustomerInfo else {
            Logger.debug(isAppBackgrounded
                            ? Strings.customerInfo.customerinfo_stale_updating_in_background
                            : Strings.customerInfo.customerinfo_stale_updating_in_foreground)
            fetchAndCacheCustomerInfo(appUserID: appUserID,
                                      isAppBackgrounded: isAppBackgrounded,
                                      completion: completion)
            return
        }

        if let completion = completion {
            operationDispatcher.dispatchOnMainThread {
                completion(.success(customerInfo))
            }
        }
    }

    func sendCachedCustomerInfoIfAvailable(appUserID: String) {
        guard let info = cachedCustomerInfo(appUserID: appUserID) else {
            return
        }

        sendUpdateIfChanged(customerInfo: info)
    }

    func customerInfo(appUserID: String, completion: ((Result<CustomerInfo, BackendError>) -> Void)?) {
        let infoFromCache = cachedCustomerInfo(appUserID: appUserID)
        var completionCalled = false

        if let infoFromCache = infoFromCache {
            Logger.debug(Strings.customerInfo.vending_cache)
            if let completion = completion {
                completionCalled = true
                operationDispatcher.dispatchOnMainThread {
                    completion(.success(infoFromCache))
                }
            }
        }

        // Prevent calling completion twice.
        let completionIfNotCalledAlready = completionCalled ? nil : completion

        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                  isAppBackgrounded: isAppBackgrounded,
                                                  completion: completionIfNotCalledAlready)
        }
    }

    func cachedCustomerInfo(appUserID: String) -> CustomerInfo? {
        guard let customerInfoData = deviceCache.cachedCustomerInfoData(appUserID: appUserID) else {
            return nil
        }

        do {
            let info: CustomerInfo = try JSONDecoder.default.decode(jsonData: customerInfoData)

            if info.isInCurrentSchemaVersion {
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
            deviceCache.cache(customerInfo: jsonData, appUserID: appUserID)
            sendUpdateIfChanged(customerInfo: customerInfo)
        } catch {
            Logger.error(Strings.customerInfo.error_encoding_customerinfo(error))
        }
    }

    func clearCustomerInfoCache(forAppUserID appUserID: String) {
        customerInfoCacheLock.perform {
            deviceCache.clearCustomerInfoCache(appUserID: appUserID)
            lastSentCustomerInfo = nil
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

    /// Observers keyed by a monotonically increasing identifier.
    /// This allows cancelling observations by deleting them from this dictionary.
    /// These observers are used both for ``Purchases/customerInfoStream`` and
    /// `PurchasesDelegate/purchases(_:receivedUpdated:)``.
    private var customerInfoObserversByIdentifier: [Int: (CustomerInfo) -> Void] = [:]

    /// Allows monitoring changes to the active `CustomerInfo`.
    /// - Returns: closure that removes the created observation.
    /// - Note: this method is not thread-safe.
    func monitorChanges(_ changes: @escaping (CustomerInfo) -> Void) -> () -> Void {
        let lastIdentifier = self.customerInfoObserversByIdentifier.keys
            .sorted()
            .last
        let nextIdentifier = lastIdentifier
            .map { $0 + 1 } // Next index
            ?? 0 // Or default to 0

        self.customerInfoObserversByIdentifier[nextIdentifier] = changes

        return { [weak self] in
            self?.customerInfoObserversByIdentifier.removeValue(forKey: nextIdentifier)
        }
    }

    private func sendUpdateIfChanged(customerInfo: CustomerInfo) {
        customerInfoCacheLock.perform {
            guard !self.customerInfoObserversByIdentifier.isEmpty,
                  lastSentCustomerInfo != customerInfo else {
                      return
                  }

            if lastSentCustomerInfo != nil {
                Logger.debug(Strings.customerInfo.sending_updated_customerinfo_to_delegate)
            } else {
                Logger.debug(Strings.customerInfo.sending_latest_customerinfo_to_delegate)
            }

            self.lastSentCustomerInfo = customerInfo
            operationDispatcher.dispatchOnMainThread {
                for closure in self.customerInfoObserversByIdentifier.values {
                    closure(customerInfo)
                }
            }
        }
    }

}

extension CustomerInfoManager {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfo(appUserID: String) async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            return self.customerInfo(appUserID: appUserID, completion: continuation.resume)
        }
    }

}
