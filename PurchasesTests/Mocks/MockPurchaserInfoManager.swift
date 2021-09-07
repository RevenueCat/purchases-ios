//
// Created by Andrés Boedo on 1/7/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockPurchaserInfoManager: PurchaserInfoManager {
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0

    var invokedFetchAndCachePurchaserInfo = false
    var invokedFetchAndCachePurchaserInfoCount = 0
    var invokedFetchAndCachePurchaserInfoParameters: (appUserID: String, isAppBackgrounded: Bool, completion: ReceivePurchaserInfoBlock?)?
    var invokedFetchAndCachePurchaserInfoParametersList = [(appUserID: String,
        isAppBackgrounded: Bool,
        completion: ReceivePurchaserInfoBlock?)]()

    override func fetchAndCachePurchaserInfo(appUserID: String,
                                             isAppBackgrounded: Bool,
                                             completion: ReceivePurchaserInfoBlock?) {
        invokedFetchAndCachePurchaserInfo = true
        invokedFetchAndCachePurchaserInfoCount += 1
        invokedFetchAndCachePurchaserInfoParameters = (appUserID, isAppBackgrounded, completion)
        invokedFetchAndCachePurchaserInfoParametersList.append((appUserID, isAppBackgrounded, completion))
    }

    var invokedFetchAndCachePurchaserInfoIfStale = false
    var invokedFetchAndCachePurchaserInfoIfStaleCount = 0
    var invokedFetchAndCachePurchaserInfoIfStaleParameters: (appUserID: String, isAppBackgrounded: Bool, completion: ReceivePurchaserInfoBlock?)?
    var invokedFetchAndCachePurchaserInfoIfStaleParametersList = [(appUserID: String,
        isAppBackgrounded: Bool,
        completion: ReceivePurchaserInfoBlock?)]()

    override func fetchAndCachePurchaserInfoIfStale(appUserID: String,
                                                    isAppBackgrounded: Bool,
                                                    completion: ReceivePurchaserInfoBlock?) {
        invokedFetchAndCachePurchaserInfoIfStale = true
        invokedFetchAndCachePurchaserInfoIfStaleCount += 1
        invokedFetchAndCachePurchaserInfoIfStaleParameters = (appUserID, isAppBackgrounded, completion)
        invokedFetchAndCachePurchaserInfoIfStaleParametersList.append((appUserID, isAppBackgrounded, completion))
    }

    var invokedSendCachedPurchaserInfoIfAvailable = false
    var invokedSendCachedPurchaserInfoIfAvailableCount = 0
    var invokedSendCachedPurchaserInfoIfAvailableParameters: (appUserID: String, Void)?
    var invokedSendCachedPurchaserInfoIfAvailableParametersList = [(appUserID: String, Void)]()

    override func sendCachedPurchaserInfoIfAvailable(appUserID: String) {
        invokedSendCachedPurchaserInfoIfAvailable = true
        invokedSendCachedPurchaserInfoIfAvailableCount += 1
        invokedSendCachedPurchaserInfoIfAvailableParameters = (appUserID, ())
        invokedSendCachedPurchaserInfoIfAvailableParametersList.append((appUserID, ()))
    }

    var invokedPurchaserInfo = false
    var invokedPurchaserInfoCount = 0
    var invokedPurchaserInfoParameters: (appUserID: String, completion: ReceivePurchaserInfoBlock?)?
    var invokedPurchaserInfoParametersList = [(appUserID: String, completion: ReceivePurchaserInfoBlock?)]()

    var stubbedPurchaserInfo: PurchaserInfo?
    var stubbedError: Error?

    override func purchaserInfo(appUserID: String,
                                completion: ReceivePurchaserInfoBlock?) {
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

    override func cachedPurchaserInfo(appUserID: String) -> PurchaserInfo {
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

    override func cache(purchaserInfo: PurchaserInfo, appUserID: String) {
        invokedCachePurchaserInfo = true
        invokedCachePurchaserInfoCount += 1
        invokedCachePurchaserInfoParameters = (purchaserInfo, appUserID)
        invokedCachePurchaserInfoParametersList.append((purchaserInfo, appUserID))
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
