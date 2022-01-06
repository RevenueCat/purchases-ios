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
                                   completion maybeCompletion: ((CustomerInfo?, Error?) -> Void)?) {
        deviceCache.setCacheTimestampToNowToPreventConcurrentCustomerInfoUpdates(appUserID: appUserID)
        operationDispatcher.dispatchOnWorkerThread(withRandomDelay: isAppBackgrounded) {
            self.backend.getSubscriberData(appUserID: appUserID) { maybeCustomerInfo, maybeError in
                if let error = maybeError {
                    self.deviceCache.clearCustomerInfoCacheTimestamp(appUserID: appUserID)
                    Logger.warn(Strings.customerInfo.customerinfo_updated_from_network_error(error: error))
                } else if let info = maybeCustomerInfo {
                    self.cache(customerInfo: info, appUserID: appUserID)
                    Logger.rcSuccess(Strings.customerInfo.customerinfo_updated_from_network)
                }

                if let completion = maybeCompletion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(maybeCustomerInfo, maybeError)
                    }
                }

            }
        }
    }

    func fetchAndCacheCustomerInfoIfStale(appUserID: String,
                                          isAppBackgrounded: Bool,
                                          completion: ((CustomerInfo?, Error?) -> Void)?) {
        let maybeCachedCustomerInfo = cachedCustomerInfo(appUserID: appUserID)
        let isCacheStale = deviceCache.isCustomerInfoCacheStale(appUserID: appUserID,
                                                                isAppBackgrounded: isAppBackgrounded)
        let needsToRefresh = isCacheStale || maybeCachedCustomerInfo == nil
        if needsToRefresh {
            Logger.debug(isAppBackgrounded
                            ? Strings.customerInfo.customerinfo_stale_updating_in_background
                            : Strings.customerInfo.customerinfo_stale_updating_in_foreground)
            fetchAndCacheCustomerInfo(appUserID: appUserID,
                                      isAppBackgrounded: isAppBackgrounded,
                                      completion: completion)
        } else {
            if let completion = completion {
                operationDispatcher.dispatchOnMainThread {
                    completion(maybeCachedCustomerInfo, nil)
                }
            }
        }
    }

    func sendCachedCustomerInfoIfAvailable(appUserID: String) {
        guard let info = cachedCustomerInfo(appUserID: appUserID) else {
            return
        }

        sendUpdateIfChanged(customerInfo: info)
    }

    func customerInfo(appUserID: String, completion maybeCompletion: ((CustomerInfo?, Error?) -> Void)?) {
        let maybeInfoFromCache = cachedCustomerInfo(appUserID: appUserID)
        var completionCalled = false

        if let infoFromCache = maybeInfoFromCache {
            Logger.debug(Strings.customerInfo.vending_cache)
            if let completion = maybeCompletion {
                completionCalled = true
                operationDispatcher.dispatchOnMainThread {
                    completion(infoFromCache, nil)
                }
            }
        }

        // Prevent calling completion twice.
        let completionIfNotCalledAlready = completionCalled ? nil : maybeCompletion

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
            let maybeInfoDict = try JSONSerialization.jsonObject(with: customerInfoData) as? [String: Any]
            guard let customerInfoDict = maybeInfoDict else {
                return nil
            }

            let info: CustomerInfo
            do {
                info = try CustomerInfo(data: customerInfoDict)
            } catch {
                if let customerInfoError = error as? CustomerInfoError {
                    Logger.error(customerInfoError.description)
                } else {
                    Logger.error("Error loading customer info from cache: \(error)")
                }
                return nil
            }

            if let schema = info.schemaVersion, schema == CustomerInfo.currentSchemaVersion {
                return info
            }
        } catch {
            Logger.error("Unable to unmarshall CustomerInfo from cache:\n \(error.localizedDescription)")
        }

        return nil
    }

    func cache(customerInfo: CustomerInfo, appUserID: String) {
        let customerInfoJSONObject = customerInfo.jsonObject()
        if JSONSerialization.isValidJSONObject(customerInfoJSONObject) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: customerInfo.jsonObject())
                deviceCache.cache(customerInfo: jsonData, appUserID: appUserID)
                sendUpdateIfChanged(customerInfo: customerInfo)
            } catch {
                Logger.error(Strings.customerInfo.error_getting_data_from_customerinfo_json(error: error))
            }
        } else {
            Logger.error(Strings.customerInfo.invalid_json)
        }
    }

    func clearCustomerInfoCache(forAppUserID appUserID: String) {
        customerInfoCacheLock.perform {
            deviceCache.clearCustomerInfoCache(appUserID: appUserID)
            lastSentCustomerInfo = nil
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    var customerInfoStream: AsyncStream<CustomerInfo> {
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let disposable = self.monitorChanges { continuation.yield($0) }

            continuation.onTermination = { @Sendable _ in disposable() }
        }
    }

    private var customerInfoObserversByIdentifier: [Int: (CustomerInfo) -> Void] = [:]

    /// Allows monitoring changes to the active `CustomerInfo`.
    /// - Returns: closure that removes the created observation.
    /// - Note: this method is not thread-safe.
    func monitorChanges(_ changes: @escaping (CustomerInfo) -> Void) -> () -> Void {
        let identifier = self.customerInfoObserversByIdentifier.keys
            .sorted().last.map { $0 + 1 } // Next index
            ?? 0 // Or default to 0

        self.customerInfoObserversByIdentifier[identifier] = changes

        return { [weak self] in
            self?.customerInfoObserversByIdentifier.removeValue(forKey: identifier)
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
