//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaserInfoManager.swift
//
//  Created by Joshua Liebowitz on 8/5/21.

import Foundation

public typealias ReceivePurchaserInfoBlock = (PurchaserInfo?, Error?) -> Void

@objc(RCPurchaserInfoManagerDelegate) public protocol PurchaserInfoManagerDelegate: NSObjectProtocol {

    @objc(purchaserInfoManagerDidReceiveUpdatedPurchaserInfo:)
    func purchaserInfoManagerDidReceiveUpdated(purchaserInfo: PurchaserInfo)

}

@objc(RCPurchaserInfoManager) public class PurchaserInfoManager: NSObject {

    @objc public weak var delegate: PurchaserInfoManagerDelegate?

    private(set) var lastSentPurchaserInfo: PurchaserInfo?
    private let operationDispatcher: OperationDispatcher
    private let deviceCache: DeviceCache
    private let backend: Backend
    private let systemInfo: SystemInfo
    private let purchaserInfoCacheLock = NSRecursiveLock()

    @objc public init(operationDispatcher: OperationDispatcher,
                      deviceCache: DeviceCache,
                      backend: Backend,
                      systemInfo: SystemInfo) {
        self.operationDispatcher = operationDispatcher
        self.deviceCache = deviceCache
        self.backend = backend
        self.systemInfo = systemInfo
    }

    @objc public func fetchAndCachePurchaserInfo(appUserID: String,
                                                 isAppBackgrounded: Bool,
                                                 completion: ReceivePurchaserInfoBlock?) {
        deviceCache.setPurchaserInfoCacheTimestampToNow(appUserID: appUserID)
        operationDispatcher.dispatchOnWorkerThread(withRandomDelay: isAppBackgrounded) {
            self.backend.getSubscriberData(appUserID: appUserID) { purchaserInfo, error in
                if error != nil {
                    self.deviceCache.clearPurchaserInfoCacheTimestamp(appUserID: appUserID)
                } else if let info = purchaserInfo {
                    self.cache(purchaserInfo: info, appUserID: appUserID)
                }

                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(purchaserInfo, error)
                    }
                }

            }
        }
    }

    @objc public func fetchAndCachePurchaserInfoIfStale(appUserID: String,
                                                        isAppBackgrounded: Bool,
                                                        completion: ReceivePurchaserInfoBlock?) {
        let cachedPurchaserInfo = cachedPurchaserInfo(appUserID: appUserID)
        let isCacheStale = deviceCache.isPurchaserInfoCacheStale(appUserID: appUserID,
                                                                 isAppBackgrounded: isAppBackgrounded)
        let needsToRefresh = isCacheStale || cachedPurchaserInfo == nil
        if needsToRefresh {
            Logger.debug(isAppBackgrounded
                            ? Strings.purchaserInfo.purchaserinfo_stale_updating_in_background
                            : Strings.purchaserInfo.purchaserinfo_stale_updating_in_foreground)
            fetchAndCachePurchaserInfo(appUserID: appUserID,
                                       isAppBackgrounded: isAppBackgrounded,
                                       completion: completion)
            Logger.rcSuccess(Strings.purchaserInfo.purchaserinfo_updated_from_network)
        } else {
            if let completion = completion {
                operationDispatcher.dispatchOnMainThread {
                    completion(cachedPurchaserInfo, nil)
                }
            }
        }
    }

    // TODO(post-migration): Switch to internal
    @objc(sendCachedPurchaserInfoIfAvailableForAppUserID:)
    public func sendCachedPurchaserInfoIfAvailable(appUserID: String) {
        guard let info = cachedPurchaserInfo(appUserID: appUserID) else {
            return
        }

        sendUpdateIfChanged(purchaserInfo: info)
    }

    @objc(purchaserInfoWithAppUserID:completionBlock:)
    public func purchaserInfo(appUserID: String, completionBlock: ReceivePurchaserInfoBlock?) {
        let infoFromCache = cachedPurchaserInfo(appUserID: appUserID)
        var completionCalled = false

        if let infoFromCache = infoFromCache {
            Logger.debug(Strings.purchaserInfo.vending_cache)
            if let completion = completionBlock {
                completionCalled = true
                operationDispatcher.dispatchOnMainThread {
                    completion(infoFromCache, nil)
                }
            }
        }

        // Prevent calling completion twice.
        let fetchPurchaserInfoCompletion = completionCalled ? nil : completionBlock

        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.fetchAndCachePurchaserInfoIfStale(appUserID: appUserID,
                                                   isAppBackgrounded: isAppBackgrounded,
                                                   completion: fetchPurchaserInfoCompletion)
        }
    }

    // TODO: Ensure this is tested
    @objc(cachedPurchaserInfoForAppUserID:)
    public func cachedPurchaserInfo(appUserID: String) -> PurchaserInfo? {
        guard let purchaserInfoData = deviceCache.cachedPurchaserInfoData(appUserID: appUserID) else {
            return nil
        }

        do {
            let infoDict = try JSONSerialization.jsonObject(with: purchaserInfoData) as? [String: Any]
            guard let infoDict = infoDict,
                  let info = PurchaserInfo(data: infoDict) else {
                return nil
            }

            if let schema = info.schemaVersion, schema == PurchaserInfo.currentSchemaVersion {
                return info
            }
        } catch {
            Logger.warn("Unable to unmarshall PurchaserInfo from cache:\n \(error.localizedDescription)")
        }

        return nil
    }

    @objc(cachePurchaserInfo:forAppUserID:)
    public func cache(purchaserInfo: PurchaserInfo, appUserID: String) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: purchaserInfo.jsonObject())
            deviceCache.cache(purchaserInfo: jsonData, appUserID: appUserID)
            sendUpdateIfChanged(purchaserInfo: purchaserInfo)
        } catch {
            Logger.warn("Invalid JSON returned from purchaserInfo.jsonObject\n\(error.localizedDescription)")
        }
    }

    @objc public func clearPurchaserInfoCache(forAppUserID appUserID: String) {
        purchaserInfoCacheLock.lock()
        deviceCache.clearPurchaserInfoCache(appUserID: appUserID)
        lastSentPurchaserInfo = nil
        purchaserInfoCacheLock.unlock()
    }

    // TODO: Why do we have this? It's not referenced anywhere.
    func invalidatePurchaserInfoCache(appUserID: String) {
        Logger.debug(Strings.purchaserInfo.invalidating_purchaserinfo_cache)
        self.deviceCache.clearPurchaserInfoCache(appUserID: appUserID)
    }

    private func sendUpdateIfChanged(purchaserInfo: PurchaserInfo) {
        guard let delegate = self.delegate else {
            return
        }

        purchaserInfoCacheLock.lock()
        guard lastSentPurchaserInfo != purchaserInfo else {
            purchaserInfoCacheLock.unlock()
            return
        }

        if lastSentPurchaserInfo != nil {
            Logger.debug(Strings.purchaserInfo.sending_updated_purchaserinfo_to_delegate)
        } else {
            Logger.debug(Strings.purchaserInfo.sending_latest_purchaserinfo_to_delegate)
        }

        self.lastSentPurchaserInfo = purchaserInfo
        operationDispatcher.dispatchOnMainThread {
            self.purchaserInfoCacheLock.unlock()
            delegate.purchaserInfoManagerDidReceiveUpdated(purchaserInfo: purchaserInfo)
        }
    }

}
