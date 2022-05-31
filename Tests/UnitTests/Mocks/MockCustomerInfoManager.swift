//
// Created by Andrés Boedo on 1/7/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

// swiftlint:disable large_tuple
// swiftlint:disable line_length
class MockCustomerInfoManager: CustomerInfoManager {
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0

    var invokedFetchAndCacheCustomerInfo = false
    var invokedFetchAndCacheCustomerInfoCount = 0
    var invokedFetchAndCacheCustomerInfoParameters: (appUserID: String, isAppBackgrounded: Bool, completion: ((Result<CustomerInfo, BackendError>) -> Void)?)?
    var invokedFetchAndCacheCustomerInfoParametersList = [(appUserID: String,
                                                           isAppBackgrounded: Bool,
                                                           completion: ((Result<CustomerInfo, BackendError>) -> Void)?)]()

    override func fetchAndCacheCustomerInfo(appUserID: String,
                                            isAppBackgrounded: Bool,
                                            completion: ((Result<CustomerInfo, BackendError>) -> Void)?) {
        invokedFetchAndCacheCustomerInfo = true
        invokedFetchAndCacheCustomerInfoCount += 1
        invokedFetchAndCacheCustomerInfoParameters = (appUserID, isAppBackgrounded, completion)
        invokedFetchAndCacheCustomerInfoParametersList.append((appUserID, isAppBackgrounded, completion))
    }

    var invokedFetchAndCacheCustomerInfoIfStale = false
    var invokedFetchAndCacheCustomerInfoIfStaleCount = 0
    var invokedFetchAndCacheCustomerInfoIfStaleParameters: (appUserID: String, isAppBackgrounded: Bool, completion: ((Result<CustomerInfo, BackendError>) -> Void)?)?
    var invokedFetchAndCacheCustomerInfoIfStaleParametersList = [(appUserID: String,
                                                                  isAppBackgrounded: Bool,
                                                                  completion: ((Result<CustomerInfo, BackendError>) -> Void)?)]()

    override func fetchAndCacheCustomerInfoIfStale(appUserID: String,
                                                   isAppBackgrounded: Bool,
                                                   completion: ((Result<CustomerInfo, BackendError>) -> Void)?) {
        invokedFetchAndCacheCustomerInfoIfStale = true
        invokedFetchAndCacheCustomerInfoIfStaleCount += 1
        invokedFetchAndCacheCustomerInfoIfStaleParameters = (appUserID, isAppBackgrounded, completion)
        invokedFetchAndCacheCustomerInfoIfStaleParametersList.append((appUserID, isAppBackgrounded, completion))
    }

    var invokedSendCachedCustomerInfoIfAvailable = false
    var invokedSendCachedCustomerInfoIfAvailableCount = 0
    var invokedSendCachedCustomerInfoIfAvailableParameters: (appUserID: String, Void)?
    var invokedSendCachedCustomerInfoIfAvailableParametersList = [(appUserID: String, Void)]()

    override func sendCachedCustomerInfoIfAvailable(appUserID: String) {
        invokedSendCachedCustomerInfoIfAvailable = true
        invokedSendCachedCustomerInfoIfAvailableCount += 1
        invokedSendCachedCustomerInfoIfAvailableParameters = (appUserID, ())
        invokedSendCachedCustomerInfoIfAvailableParametersList.append((appUserID, ()))
    }

    var invokedCustomerInfo = false
    var invokedCustomerInfoCount = 0
    var invokedCustomerInfoParameters: (appUserID: String,
                                        fetchPolicy: CacheFetchPolicy,
                                        completion: ((Result<CustomerInfo, BackendError>) -> Void)?)?
    var invokedCustomerInfoParametersList: [(appUserID: String,
                                             fetchPolicy: CacheFetchPolicy,
                                             completion: ((Result<CustomerInfo, BackendError>) -> Void)?)] = []

    var stubbedCustomerInfoResult: Result<CustomerInfo, BackendError> = .failure(.missingAppUserID())

    override func customerInfo(appUserID: String,
                               fetchPolicy: CacheFetchPolicy,
                               completion: ((Result<CustomerInfo, BackendError>) -> Void)?) {
        invokedCustomerInfo = true
        invokedCustomerInfoCount += 1
        invokedCustomerInfoParameters = (appUserID, fetchPolicy, completion)
        invokedCustomerInfoParametersList.append((appUserID, fetchPolicy, completion))
        completion?(self.stubbedCustomerInfoResult)
    }

    var invokedCachedCustomerInfo = false
    var invokedCachedCustomerInfoCount = 0
    var invokedCachedCustomerInfoParameters: (appUserID: String, Void)?
    var invokedCachedCustomerInfoParametersList = [(appUserID: String, Void)]()
    var stubbedCachedCustomerInfoResult: CustomerInfo!

    override func cachedCustomerInfo(appUserID: String) -> CustomerInfo {
        invokedCachedCustomerInfo = true
        invokedCachedCustomerInfoCount += 1
        invokedCachedCustomerInfoParameters = (appUserID, ())
        invokedCachedCustomerInfoParametersList.append((appUserID, ()))
        return stubbedCachedCustomerInfoResult
    }

    var invokedCacheCustomerInfo = false
    var invokedCacheCustomerInfoCount = 0
    var invokedCacheCustomerInfoParameters: (info: CustomerInfo, appUserID: String)?
    var invokedCacheCustomerInfoParametersList = [(info: CustomerInfo, appUserID: String)]()

    override func cache(customerInfo: CustomerInfo, appUserID: String) {
        invokedCacheCustomerInfo = true
        invokedCacheCustomerInfoCount += 1
        invokedCacheCustomerInfoParameters = (customerInfo, appUserID)
        invokedCacheCustomerInfoParametersList.append((customerInfo, appUserID))
    }

    var invokedClearCustomerInfoCache = false
    var invokedClearCustomerInfoCacheCount = 0
    var invokedClearCustomerInfoCacheParameters: (appUserID: String, Void)?
    var invokedClearCustomerInfoCacheParametersList = [(appUserID: String, Void)]()

    override func clearCustomerInfoCache(forAppUserID appUserID: String) {
        invokedClearCustomerInfoCache = true
        invokedClearCustomerInfoCacheCount += 1
        invokedClearCustomerInfoCacheParameters = (appUserID, ())
        invokedClearCustomerInfoCacheParametersList.append((appUserID, ()))
    }
}
