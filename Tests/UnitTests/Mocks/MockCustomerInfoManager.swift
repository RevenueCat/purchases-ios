//
// Created by Andrés Boedo on 1/7/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

// swiftlint:disable line_length
// Note: this class is implicitly `@unchecked Sendable` through its parent
// even though it's not actually thread safe.
class MockCustomerInfoManager: CustomerInfoManager {

    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0

    var invokedFetchAndCacheCustomerInfo = false
    var invokedFetchAndCacheCustomerInfoCount = 0
    var invokedFetchAndCacheCustomerInfoParameters: (appUserID: String,
                                                     isAppBackgrounded: Bool,
                                                     postTransactionsIfNeeded: Bool,
                                                     completion: CustomerInfoCompletion?)?
    var invokedFetchAndCacheCustomerInfoParametersList = [(appUserID: String,
                                                           isAppBackgrounded: Bool,
                                                           postTransactionsIfNeeded: Bool,
                                                           completion: CustomerInfoCompletion?)]()

    override func fetchAndCacheCustomerInfo(appUserID: String,
                                            isAppBackgrounded: Bool,
                                            postTransactionsIfNeeded: Bool = true,
                                            completion: CustomerInfoCompletion?) {
        self.invokedFetchAndCacheCustomerInfo = true
        self.invokedFetchAndCacheCustomerInfoCount += 1
        self.invokedFetchAndCacheCustomerInfoParameters = (appUserID, isAppBackgrounded, postTransactionsIfNeeded, completion)
        self.invokedFetchAndCacheCustomerInfoParametersList.append((appUserID,
                                                                    isAppBackgrounded,
                                                                    postTransactionsIfNeeded,
                                                                    completion))
    }

    var invokedFetchAndCacheCustomerInfoIfStale = false
    var invokedFetchAndCacheCustomerInfoIfStaleCount = 0
    var invokedFetchAndCacheCustomerInfoIfStaleParameters: (appUserID: String,
                                                            isAppBackgrounded: Bool,
                                                            postTransactionsIfNeeded: Bool,
                                                            completion: CustomerInfoCompletion?)?
    var invokedFetchAndCacheCustomerInfoIfStaleParametersList = [(appUserID: String,
                                                                  isAppBackgrounded: Bool,
                                                                  postTransactionsIfNeeded: Bool,
                                                                  completion: CustomerInfoCompletion?)]()

    override func fetchAndCacheCustomerInfoIfStale(appUserID: String,
                                                   isAppBackgrounded: Bool,
                                                   postTransactionsIfNeeded: Bool = true,
                                                   completion: CustomerInfoCompletion?) {
        self.invokedFetchAndCacheCustomerInfoIfStale = true
        self.invokedFetchAndCacheCustomerInfoIfStaleCount += 1
        self.invokedFetchAndCacheCustomerInfoIfStaleParameters = (appUserID,
                                                                  isAppBackgrounded,
                                                                  postTransactionsIfNeeded,
                                                                  completion)
        self.invokedFetchAndCacheCustomerInfoIfStaleParametersList.append((appUserID, isAppBackgrounded, postTransactionsIfNeeded, completion))
    }

    var invokedSendCachedCustomerInfoIfAvailable = false
    var invokedSendCachedCustomerInfoIfAvailableCount = 0
    var invokedSendCachedCustomerInfoIfAvailableParameters: (appUserID: String, Void)?
    var invokedSendCachedCustomerInfoIfAvailableParametersList = [(appUserID: String, Void)]()

    override func sendCachedCustomerInfoIfAvailable(appUserID: String) {
        self.invokedSendCachedCustomerInfoIfAvailable = true
        self.invokedSendCachedCustomerInfoIfAvailableCount += 1
        self.invokedSendCachedCustomerInfoIfAvailableParameters = (appUserID, ())
        self.invokedSendCachedCustomerInfoIfAvailableParametersList.append((appUserID, ()))
    }

    var invokedCustomerInfo = false
    var invokedCustomerInfoCount = 0
    var invokedCustomerInfoParameters: (appUserID: String,
                                        fetchPolicy: CacheFetchPolicy,
                                        postTransactionsIfNeeded: Bool,
                                        completion: CustomerInfoCompletion?)?
    var invokedCustomerInfoParametersList: [(appUserID: String,
                                             fetchPolicy: CacheFetchPolicy,
                                             postTransactionsIfNeeded: Bool,
                                             completion: CustomerInfoCompletion?)] = []

    var stubbedCustomerInfoResult: Result<CustomerInfo, BackendError> = .failure(.missingAppUserID())

    override func customerInfo(appUserID: String,
                               fetchPolicy: CacheFetchPolicy,
                               postTransactionsIfNeeded: Bool = true,
                               completion: CustomerInfoCompletion?) {
        self.invokedCustomerInfo = true
        self.invokedCustomerInfoCount += 1
        self.invokedCustomerInfoParameters = (appUserID, fetchPolicy, postTransactionsIfNeeded, completion)
        self.invokedCustomerInfoParametersList.append((appUserID, fetchPolicy, postTransactionsIfNeeded, completion))

        OperationDispatcher.dispatchOnMainActor {
            completion?(self.stubbedCustomerInfoResult)
        }
    }

    var invokedCachedCustomerInfo = false
    var invokedCachedCustomerInfoCount = 0
    var invokedCachedCustomerInfoParameters: (appUserID: String, Void)?
    var invokedCachedCustomerInfoParametersList = [(appUserID: String, Void)]()
    var stubbedCachedCustomerInfoResult: CustomerInfo?

    override func cachedCustomerInfo(appUserID: String) -> CustomerInfo? {
        self.invokedCachedCustomerInfo = true
        self.invokedCachedCustomerInfoCount += 1
        self.invokedCachedCustomerInfoParameters = (appUserID, ())
        self.invokedCachedCustomerInfoParametersList.append((appUserID, ()))

        return self.stubbedCachedCustomerInfoResult
    }

    var invokedCacheCustomerInfo = false
    var invokedCacheCustomerInfoCount = 0
    var invokedCacheCustomerInfoParameters: (info: CustomerInfo, appUserID: String)?
    var invokedCacheCustomerInfoParametersList = [(info: CustomerInfo, appUserID: String)]()

    override func cache(customerInfo: CustomerInfo, appUserID: String) {
        self.invokedCacheCustomerInfo = true
        self.invokedCacheCustomerInfoCount += 1
        self.invokedCacheCustomerInfoParameters = (customerInfo, appUserID)
        self.invokedCacheCustomerInfoParametersList.append((customerInfo, appUserID))
    }

    var invokedClearCustomerInfoCache = false
    var invokedClearCustomerInfoCacheCount = 0
    var invokedClearCustomerInfoCacheParameters: (appUserID: String, Void)?
    var invokedClearCustomerInfoCacheParametersList = [(appUserID: String, Void)]()

    override func clearCustomerInfoCache(forAppUserID appUserID: String) {
        self.invokedClearCustomerInfoCache = true
        self.invokedClearCustomerInfoCacheCount += 1
        self.invokedClearCustomerInfoCacheParameters = (appUserID, ())
        self.invokedClearCustomerInfoCacheParametersList.append((appUserID, ()))
    }
}
