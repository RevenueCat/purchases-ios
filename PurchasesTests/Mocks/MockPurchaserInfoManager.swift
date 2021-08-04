//
// Created by Andrés Boedo on 1/7/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import PurchasesCoreSwift

class MockPurchaserInfoManager: PurchaserInfoManager {
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0

    var invokedFetchAndCachePurchaserInfo = false
    var invokedFetchAndCachePurchaserInfoCount = 0
    var invokedFetchAndCachePurchaserInfoParameters: (appUserID: String, isAppBackgrounded: Bool, completion: Purchases.ReceivePurchaserInfoBlock?)?
    var invokedFetchAndCachePurchaserInfoParametersList = [(appUserID: String,
        isAppBackgrounded: Bool,
        completion: Purchases.ReceivePurchaserInfoBlock?)]()

    override func fetchAndCachePurchaserInfo(withAppUserID appUserID: String,
                                             isAppBackgrounded: Bool,
                                             completion: Purchases.ReceivePurchaserInfoBlock?) {
        invokedFetchAndCachePurchaserInfo = true
        invokedFetchAndCachePurchaserInfoCount += 1
        invokedFetchAndCachePurchaserInfoParameters = (appUserID, isAppBackgrounded, completion)
        invokedFetchAndCachePurchaserInfoParametersList.append((appUserID, isAppBackgrounded, completion))
    }

    var invokedFetchAndCachePurchaserInfoIfStale = false
    var invokedFetchAndCachePurchaserInfoIfStaleCount = 0
    var invokedFetchAndCachePurchaserInfoIfStaleParameters: (appUserID: String, isAppBackgrounded: Bool, completion: Purchases.ReceivePurchaserInfoBlock?)?
    var invokedFetchAndCachePurchaserInfoIfStaleParametersList = [(appUserID: String,
        isAppBackgrounded: Bool,
        completion: Purchases.ReceivePurchaserInfoBlock?)]()

    override func fetchAndCachePurchaserInfoIfStale(withAppUserID appUserID: String,
                                                    isAppBackgrounded: Bool,
                                                    completion: Purchases.ReceivePurchaserInfoBlock?) {
        invokedFetchAndCachePurchaserInfoIfStale = true
        invokedFetchAndCachePurchaserInfoIfStaleCount += 1
        invokedFetchAndCachePurchaserInfoIfStaleParameters = (appUserID, isAppBackgrounded, completion)
        invokedFetchAndCachePurchaserInfoIfStaleParametersList.append((appUserID, isAppBackgrounded, completion))
    }

    var invokedSendCachedPurchaserInfoIfAvailable = false
    var invokedSendCachedPurchaserInfoIfAvailableCount = 0
    var invokedSendCachedPurchaserInfoIfAvailableParameters: (appUserID: String, Void)?
    var invokedSendCachedPurchaserInfoIfAvailableParametersList = [(appUserID: String, Void)]()

    override func sendCachedPurchaserInfoIfAvailable(forAppUserID appUserID: String) {
        invokedSendCachedPurchaserInfoIfAvailable = true
        invokedSendCachedPurchaserInfoIfAvailableCount += 1
        invokedSendCachedPurchaserInfoIfAvailableParameters = (appUserID, ())
        invokedSendCachedPurchaserInfoIfAvailableParametersList.append((appUserID, ()))
    }

    var invokedPurchaserInfo = false
    var invokedPurchaserInfoCount = 0
    var invokedPurchaserInfoParameters: (appUserID: String, completion: Purchases.ReceivePurchaserInfoBlock?)?
    var invokedPurchaserInfoParametersList = [(appUserID: String, completion: Purchases.ReceivePurchaserInfoBlock?)]()

    var stubbedPurchaserInfo: PurchaserInfo?
    var stubbedError: Error?

    override func purchaserInfo(withAppUserID appUserID: String,
                                completionBlock completion: Purchases.ReceivePurchaserInfoBlock?) {
        invokedPurchaserInfo = true
        invokedPurchaserInfoCount += 1
        invokedPurchaserInfoParameters = (appUserID, completion)
        invokedPurchaserInfoParametersList.append((appUserID, completion))
        completion?(stubbedPurchaserInfo, stubbedError)
    }

    var invokedCachedPurchaserInfo = false
    var invokedCachedPurchaserInfoCount = 0
    var invokedCachedPurchaserInfoParameters: (appUserID: String, Void)?
    var invokedCachedPurchaserInfoParametersList = [(appUserID: String, Void)]()
    var stubbedCachedPurchaserInfoResult: PurchaserInfo!

    override func cachedPurchaserInfo(forAppUserID appUserID: String) -> PurchaserInfo {
        invokedCachedPurchaserInfo = true
        invokedCachedPurchaserInfoCount += 1
        invokedCachedPurchaserInfoParameters = (appUserID, ())
        invokedCachedPurchaserInfoParametersList.append((appUserID, ()))
        return stubbedCachedPurchaserInfoResult
    }

    var invokedCachePurchaserInfo = false
    var invokedCachePurchaserInfoCount = 0
    var invokedCachePurchaserInfoParameters: (info: PurchaserInfo, appUserID: String)?
    var invokedCachePurchaserInfoParametersList = [(info: PurchaserInfo, appUserID: String)]()

    override func cachePurchaserInfo(_ info: PurchaserInfo,
                                     forAppUserID appUserID: String) {
        invokedCachePurchaserInfo = true
        invokedCachePurchaserInfoCount += 1
        invokedCachePurchaserInfoParameters = (info, appUserID)
        invokedCachePurchaserInfoParametersList.append((info, appUserID))
    }

    var invokedClearPurchaserInfoCache = false
    var invokedClearPurchaserInfoCacheCount = 0
    var invokedClearPurchaserInfoCacheParameters: (appUserID: String, Void)?
    var invokedClearPurchaserInfoCacheParametersList = [(appUserID: String, Void)]()

    override func clearPurchaserInfoCache(forAppUserID appUserID: String) {
        invokedClearPurchaserInfoCache = true
        invokedClearPurchaserInfoCacheCount += 1
        invokedClearPurchaserInfoCacheParameters = (appUserID, ())
        invokedClearPurchaserInfoCacheParametersList.append((appUserID, ()))
    }
}
