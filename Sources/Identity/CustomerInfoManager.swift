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

// swiftlint:disable file_length

class CustomerInfoManager {

    typealias CustomerInfoCompletion = @MainActor @Sendable (Result<CustomerInfo, BackendError>) -> Void

    var lastSentCustomerInfo: CustomerInfo? { return self.data.value.lastSentCustomerInfo }

    private let offlineEntitlementsManager: OfflineEntitlementsManager
    private let operationDispatcher: OperationDispatcher
    private let backend: Backend
    private let systemInfo: SystemInfo
    private let transactionFetcher: StoreKit2TransactionFetcherType
    private let transactionPoster: TransactionPosterType

    /// Underlying synchronized data.
    private let data: Atomic<Data>

    init(offlineEntitlementsManager: OfflineEntitlementsManager,
         operationDispatcher: OperationDispatcher,
         deviceCache: DeviceCache,
         backend: Backend,
         transactionFetcher: StoreKit2TransactionFetcherType,
         transactionPoster: TransactionPosterType,
         systemInfo: SystemInfo
    ) {
        self.offlineEntitlementsManager = offlineEntitlementsManager
        self.operationDispatcher = operationDispatcher
        self.backend = backend
        self.transactionFetcher = transactionFetcher
        self.transactionPoster = transactionPoster
        self.systemInfo = systemInfo

        self.data = .init(.init(deviceCache: deviceCache))
    }

    func fetchAndCacheCustomerInfo(appUserID: String,
                                   isAppBackgrounded: Bool,
                                   completion: CustomerInfoCompletion?) {
        self.getCustomerInfo(appUserID: appUserID,
                             isAppBackgrounded: isAppBackgrounded) { result in
            switch result {
            case let .failure(error):
                self.withData { $0.deviceCache.clearCustomerInfoCacheTimestamp(appUserID: appUserID) }
                Logger.warn(Strings.customerInfo.customerinfo_updated_from_network_error(error))

            case let .success(info):
                self.cache(customerInfo: info, appUserID: appUserID)
                Logger.rcSuccess(
                    info.isComputedOffline
                    ? Strings.customerInfo.customerinfo_updated_offline
                    : Strings.customerInfo.customerinfo_updated_from_network
                )
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
        let isCacheStale = self.withData {
            $0.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded)
        }

        guard !isCacheStale, let customerInfo = self.cachedCustomerInfo(appUserID: appUserID) else {
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
        if customerInfo.shouldCache {
            do {
                let jsonData = try JSONEncoder.default.encode(customerInfo)
                self.withData { $0.deviceCache.cache(customerInfo: jsonData, appUserID: appUserID) }
            } catch {
                Logger.error(Strings.customerInfo.error_encoding_customerinfo(error))
            }
        } else {
            Logger.debug(Strings.customerInfo.not_caching_offline_customer_info)
            self.clearCustomerInfoCache(forAppUserID: appUserID)
        }

        self.sendUpdateIfChanged(customerInfo: customerInfo)
    }

    func clearCustomerInfoCache(forAppUserID appUserID: String) {
        self.modifyData {
            $0.deviceCache.clearCustomerInfoCache(appUserID: appUserID)
            $0.lastSentCustomerInfo = nil
        }
    }

    func setLastSentCustomerInfo(_ info: CustomerInfo) {
        self.modifyData {
            $0.lastSentCustomerInfo = info
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    var customerInfoStream: AsyncStream<CustomerInfo> {
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            if let lastSentCustomerInfo = self.lastSentCustomerInfo {
                continuation.yield(lastSentCustomerInfo)
            }

            let disposable = self.monitorChanges { _, new in continuation.yield(new) }

            continuation.onTermination = { @Sendable _ in disposable() }
        }
    }

    typealias CustomerInfoChangeClosure = (_ old: CustomerInfo?, _ new: CustomerInfo) -> Void

    /// Allows monitoring changes to the active `CustomerInfo`.
    /// - Returns: closure that removes the created observation.
    func monitorChanges(_ changes: @escaping CustomerInfoChangeClosure) -> () -> Void {
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
        return self.modifyData {
            let lastSentCustomerInfo = $0.lastSentCustomerInfo

            guard !$0.customerInfoObserversByIdentifier.isEmpty, lastSentCustomerInfo != customerInfo else {
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
                    closure(lastSentCustomerInfo, customerInfo)
                }
            }
        }
    }

}

// MARK: - async extensions

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension CustomerInfoManager {

    func fetchAndCacheCustomerInfo(appUserID: String, isAppBackgrounded: Bool) async throws -> CustomerInfo {
        return try await Async.call { completion in
            return self.fetchAndCacheCustomerInfo(appUserID: appUserID,
                                                  isAppBackgrounded: isAppBackgrounded,
                                                  completion: completion)
        }
    }

    func customerInfo(
        appUserID: String,
        fetchPolicy: CacheFetchPolicy
    ) async throws -> CustomerInfo {
        return try await Async.call { completion in
            return self.customerInfo(appUserID: appUserID,
                                     fetchPolicy: fetchPolicy,
                                     completion: completion)
        }
    }

}

// MARK: -

private extension CustomerInfoManager {

    func getCustomerInfo(appUserID: String,
                         isAppBackgrounded: Bool,
                         completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            _ = Task<Void, Never> {
                let transactions = await self.transactionFetcher.unfinishedVerifiedTransactions

                if let transactionToPost = transactions.first {
                    Logger.debug(
                        Strings.customerInfo.posting_transactions_in_lieu_of_fetching_customerinfo(transactions)
                    )

                    let transactionData = PurchasedTransactionData(
                        appUserID: appUserID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: [:],
                        storefront: await Storefront.currentStorefront,
                        source: Self.sourceForUnfinishedTransaction
                    )

                    // Post everything but the first transaction in the background
                    // in parallel so they can be de-duped
                    let otherTransactionsToPostInParalel = Array(transactions.dropFirst())
                    Task.detached(priority: .background) {
                        await self.postTransactions(otherTransactionsToPostInParalel, transactionData)
                    }

                    // Return the result of posting the first transaction.
                    // The posted receipt will include the content of every other transaction
                    // so we don't need to wait for those.
                    completion(await self.transactionPoster.handlePurchasedTransaction(
                        transactionToPost,
                        data: transactionData
                    ))
                } else {
                    self.requestCustomerInfo(appUserID: appUserID,
                                             isAppBackgrounded: isAppBackgrounded,
                                             completion: completion)
                }
            }
        } else {
            return self.requestCustomerInfo(appUserID: appUserID,
                                            isAppBackgrounded: isAppBackgrounded,
                                            completion: completion)
        }
    }

    private func requestCustomerInfo(appUserID: String,
                                     isAppBackgrounded: Bool,
                                     completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let allowComputingOffline = self.offlineEntitlementsManager.shouldComputeOfflineCustomerInfo(
            appUserID: appUserID
        )

        self.backend.getCustomerInfo(appUserID: appUserID,
                                     withRandomDelay: isAppBackgrounded,
                                     allowComputingOffline: allowComputingOffline,
                                     completion: completion)
    }

    /// Posts all `transactions` in parallel.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    private func postTransactions(
        _ transactions: [StoreTransaction],
        _ data: PurchasedTransactionData
    ) async {
        await withTaskGroup(of: Void.self) { group in
            for transaction in transactions {
                group.addTask {
                    _ = await self.transactionPoster.handlePurchasedTransaction(
                        transaction,
                        data: data
                    )
                }
            }
        }
    }

    // Note: this is just a best guess.
    private static let sourceForUnfinishedTransaction: PurchaseSource = .init(
        isRestore: false,
        // This might have been in theory a `.purchase`. The only downside of this is that the server
        // won't validate that the product is present in the receipt.
        initiationSource: .queue
    )

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
        var customerInfoObserversByIdentifier: [Int: CustomerInfoManager.CustomerInfoChangeClosure]

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

private extension CustomerInfo {

    var shouldCache: Bool {
        guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) else {
            return true
        }

        return self.entitlements.verification.shouldCache
    }

}

private extension VerificationResult {

    var shouldCache: Bool {
        switch self {
        case .failed, .verified, .notRequested: return true
        case .verifiedOnDevice: return false
        }
    }

}
