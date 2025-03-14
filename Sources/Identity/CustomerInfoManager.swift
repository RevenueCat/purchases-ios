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
// swiftlint:disable:next type_body_length
class CustomerInfoManager {

    typealias CustomerInfoCompletion = @MainActor @Sendable (Result<CustomerInfo, BackendError>) -> Void

    private let offlineEntitlementsManager: OfflineEntitlementsManager
    private let operationDispatcher: OperationDispatcher
    private let backend: Backend
    private let systemInfo: SystemInfo
    private let transactionFetcher: StoreKit2TransactionFetcherType
    private let transactionPoster: TransactionPosterType

    private var diagnosticsTracker: DiagnosticsTrackerType?
    private let dateProvider: DateProvider

    /// Underlying synchronized data.
    private let data: Atomic<Data>

    init(offlineEntitlementsManager: OfflineEntitlementsManager,
         operationDispatcher: OperationDispatcher,
         deviceCache: DeviceCache,
         backend: Backend,
         transactionFetcher: StoreKit2TransactionFetcherType,
         transactionPoster: TransactionPosterType,
         systemInfo: SystemInfo,
         dateProvider: DateProvider = DateProvider()
    ) {
        self.offlineEntitlementsManager = offlineEntitlementsManager
        self.operationDispatcher = operationDispatcher
        self.backend = backend
        self.transactionFetcher = transactionFetcher
        self.transactionPoster = transactionPoster
        self.systemInfo = systemInfo
        self.dateProvider = dateProvider

        self.data = .init(.init(deviceCache: deviceCache))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    convenience init(offlineEntitlementsManager: OfflineEntitlementsManager,
                     operationDispatcher: OperationDispatcher,
                     deviceCache: DeviceCache,
                     backend: Backend,
                     transactionFetcher: StoreKit2TransactionFetcherType,
                     transactionPoster: TransactionPosterType,
                     systemInfo: SystemInfo,
                     diagnosticsTracker: DiagnosticsTrackerType?,
                     dateProvider: DateProvider = DateProvider()
    ) {
        self.init(offlineEntitlementsManager: offlineEntitlementsManager,
                  operationDispatcher: operationDispatcher,
                  deviceCache: deviceCache,
                  backend: backend,
                  transactionFetcher: transactionFetcher,
                  transactionPoster: transactionPoster,
                  systemInfo: systemInfo,
                  dateProvider: dateProvider)
        self.diagnosticsTracker = diagnosticsTracker
    }

    func fetchAndCacheCustomerInfo(appUserID: String,
                                   isAppBackgrounded: Bool,
                                   completion: CustomerInfoCompletion?) {
        let mappedCompetion: CustomerInfoDataCompletion?
        if let completion {
            mappedCompetion = { customerInfoData in
                completion(customerInfoData.result)
            }
        } else {
            mappedCompetion = nil
        }
        self.fetchAndCacheCustomerInfoData(appUserID: appUserID,
                                           isAppBackgrounded: isAppBackgrounded,
                                           completion: mappedCompetion)
    }

    func fetchAndCacheCustomerInfoIfStale(appUserID: String,
                                          isAppBackgrounded: Bool,
                                          completion: CustomerInfoCompletion?) {
        let mappedCompetion: CustomerInfoDataCompletion?
        if let completion {
            mappedCompetion = { customerInfoData in
                completion(customerInfoData.result)
            }
        } else {
            mappedCompetion = nil
        }
        self.fetchAndCacheCustomerInfoDataIfStale(appUserID: appUserID,
                                                  isAppBackgrounded: isAppBackgrounded,
                                                  completion: mappedCompetion)
    }

    // swiftlint:disable:next function_body_length
    func customerInfo(
        appUserID: String,
        fetchPolicy: CacheFetchPolicy,
        trackDiagnostics: Bool = false,
        completion: CustomerInfoCompletion?
    ) {
        self.trackGetCustomerInfoStartedIfNeeded(trackDiagnostics: trackDiagnostics)
        let startTime = self.dateProvider.now()

        switch fetchPolicy {
        case .fromCacheOnly:
            self.operationDispatcher.dispatchOnMainActor {
                let result = Result { try self.cachedCustomerInfo(appUserID: appUserID) }

                // We want the specific error for diagnostics
                let resultForDiagnostics = Result(result.value as? CustomerInfo,
                                                  result.error ?? BackendError.missingCachedCustomerInfo())
                self.trackGetCustomerInfoResultIfNeeded(trackDiagnostics: trackDiagnostics,
                                                        startTime: startTime,
                                                        cacheFetchPolicy: fetchPolicy,
                                                        hadUnsyncedPurchasesBefore: nil,
                                                        usedOfflineEntitlements: false,
                                                        result: resultForDiagnostics)

                // But for callers we only pass `.missingCachedCustomerInfo()` error
                completion?(
                    Result(result.value as? CustomerInfo, .missingCachedCustomerInfo())
                )
            }

        case .fetchCurrent:
            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.fetchAndCacheCustomerInfoData(
                    appUserID: appUserID,
                    isAppBackgrounded: isAppBackgrounded
                ) { [weak self] customerInfoData in
                    self?.trackGetCustomerInfoResultIfNeeded(
                        trackDiagnostics: trackDiagnostics,
                        startTime: startTime,
                        cacheFetchPolicy: fetchPolicy,
                        customerInfoDataResult: customerInfoData)
                    completion?(customerInfoData.result)
                }
            }

        case .cachedOrFetched:
            let completionCalled: Bool
            if let infoFromCache = try? self.cachedCustomerInfo(appUserID: appUserID) {
                Logger.debug(Strings.customerInfo.vending_cache)
                completionCalled = true

                self.trackGetCustomerInfoResultIfNeeded(trackDiagnostics: trackDiagnostics,
                                                        startTime: startTime,
                                                        cacheFetchPolicy: fetchPolicy,
                                                        hadUnsyncedPurchasesBefore: nil,
                                                        usedOfflineEntitlements: false,
                                                        result: .success(infoFromCache))
                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(.success(infoFromCache))
                    }
                }
            } else {
                completionCalled = false
            }

            // Prevent calling completion twice.
            let completionIfNotCalledAlready: CustomerInfoDataCompletion?
            if completionCalled {
                completionIfNotCalledAlready = nil
            } else {
                completionIfNotCalledAlready = { [weak self] customerInfoData in
                    self?.trackGetCustomerInfoResultIfNeeded(
                        // Only track diagnostics upon calling completion
                        trackDiagnostics: trackDiagnostics && !completionCalled,
                        startTime: startTime,
                        cacheFetchPolicy: fetchPolicy,
                        customerInfoDataResult: customerInfoData)
                    completion?(customerInfoData.result)
                }
            }

            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.fetchAndCacheCustomerInfoDataIfStale(appUserID: appUserID,
                                                          isAppBackgrounded: isAppBackgrounded,
                                                          completion: completionIfNotCalledAlready)
            }

        case .notStaleCachedOrFetched:
            let infoFromCache = try? self.cachedCustomerInfo(appUserID: appUserID)

            self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                let isCacheStale = self.withData {
                    $0.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded)
                }

                if let infoFromCache = infoFromCache, !isCacheStale {
                    Logger.debug(Strings.customerInfo.vending_cache)
                    self.trackGetCustomerInfoResultIfNeeded(trackDiagnostics: trackDiagnostics,
                                                            startTime: startTime,
                                                            cacheFetchPolicy: fetchPolicy,
                                                            hadUnsyncedPurchasesBefore: nil,
                                                            usedOfflineEntitlements: false,
                                                            result: .success(infoFromCache))
                    if let completion = completion {
                        self.operationDispatcher.dispatchOnMainActor {
                            completion(.success(infoFromCache))
                        }
                    }
                } else {
                    self.fetchAndCacheCustomerInfoData(
                        appUserID: appUserID,
                        isAppBackgrounded: isAppBackgrounded
                    ) { [weak self] customerInfoData in
                        self?.trackGetCustomerInfoResultIfNeeded(
                            trackDiagnostics: trackDiagnostics,
                            startTime: startTime,
                            cacheFetchPolicy: fetchPolicy,
                            customerInfoDataResult: customerInfoData)
                        completion?(customerInfoData.result)
                    }
                }
            }
        }
    }

    func cachedCustomerInfo(appUserID: String) throws -> CustomerInfo? {
        guard !self.systemInfo.dangerousSettings.uiPreviewMode else {
            return self.createPreviewCustomerInfo()
        }

        let cachedCustomerInfoData = self.withData {
            $0.deviceCache.cachedCustomerInfoData(appUserID: appUserID)
        }
        guard let customerInfoData = cachedCustomerInfoData else { return nil }

        do {
            let info: CustomerInfo = try JSONDecoder.default.decode(jsonData: customerInfoData)

            if info.schemaVersionIsCompatible {
                return info
            } else {
                let msg = Strings.customerInfo.cached_customerinfo_incompatible_schema.description
                throw ErrorUtils.customerInfoError(withMessage: msg)
            }
        } catch {
            Logger.error("Error loading customer info from cache:\n \(error.localizedDescription)")
            throw error
        }
    }

    func cache(customerInfo: CustomerInfo, appUserID: String) {
        guard !self.systemInfo.dangerousSettings.uiPreviewMode else {
            return
        }

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
        }
    }

    func setLastSentCustomerInfo(_ info: CustomerInfo) {
        self.modifyData {
            $0.lastSentCustomerInfo = info
        }
    }

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

    // Visible for tests
    var lastSentCustomerInfo: CustomerInfo? { return self.data.value.lastSentCustomerInfo }

    private func removeObserver(with identifier: Int) {
        self.modifyData {
            $0.customerInfoObserversByIdentifier.removeValue(forKey: identifier)
        }
    }

    private func sendUpdateIfChanged(customerInfo: CustomerInfo) {
        return self.modifyData {
            let lastSentCustomerInfo = $0.lastSentCustomerInfo

            if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
                if let tracker = self.diagnosticsTracker, lastSentCustomerInfo != customerInfo {
                    tracker.trackCustomerInfoVerificationResultIfNeeded(customerInfo)
                }
            }

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
        trackDiagnostics: Bool = false,
        fetchPolicy: CacheFetchPolicy
    ) async throws -> CustomerInfo {
        return try await Async.call { completion in
            return self.customerInfo(appUserID: appUserID,
                                     fetchPolicy: fetchPolicy,
                                     trackDiagnostics: trackDiagnostics,
                                     completion: completion)
        }
    }

}

// MARK: -

private extension CustomerInfoManager {

    private typealias CustomerInfoDataCompletion = @MainActor @Sendable (CustomerInfoDataResult) -> Void

    /// Wrapper around `Result<CustomerInfo, BackendError>` to hold some additional information
    /// useful for diagnostics.
    private struct CustomerInfoDataResult {
        let result: Result<CustomerInfo, BackendError>
        let hadUnsyncedPurchasesBefore: Bool
        let usedOfflineEntitlements: Bool

        init(result: Result<CustomerInfo, BackendError>,
             hadUnsyncedPurchasesBefore: Bool = false,
             usedOfflineEntitlements: Bool = false) {
            self.result = result
            self.hadUnsyncedPurchasesBefore = hadUnsyncedPurchasesBefore
            self.usedOfflineEntitlements = usedOfflineEntitlements
        }

    }

    private func getCustomerInfoData(appUserID: String,
                                     isAppBackgrounded: Bool,
                                     completion: @escaping @Sendable (CustomerInfoDataResult) -> Void) {
        guard !self.systemInfo.dangerousSettings.uiPreviewMode else {
            let previewCustomerInfo = self.createPreviewCustomerInfo()
            completion(CustomerInfoDataResult(result: .success(previewCustomerInfo)))
            return
        }
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            _ = Task<Void, Never> {
                let transactions = await self.transactionFetcher.unfinishedVerifiedTransactions

                if let transactionToPost = transactions.first {
                    Logger.debug(
                        Strings.customerInfo.posting_transactions_in_lieu_of_fetching_customerinfo(transactions)
                    )

                    let transactionData = PurchasedTransactionData(
                        appUserID: appUserID,
                        presentedOfferingContext: nil,
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
                    let result = await self.transactionPoster.handlePurchasedTransaction(
                        transactionToPost,
                        data: transactionData
                    )
                    completion(CustomerInfoDataResult(result: result, hadUnsyncedPurchasesBefore: true))
                } else {
                    self.requestCustomerInfo(appUserID: appUserID,
                                             isAppBackgrounded: isAppBackgrounded) { result in
                        completion(CustomerInfoDataResult(result: result, hadUnsyncedPurchasesBefore: false))
                    }
                }
            }
        } else {
            return self.requestCustomerInfo(appUserID: appUserID,
                                            isAppBackgrounded: isAppBackgrounded) { result in
                completion(CustomerInfoDataResult(result: result))
            }
        }
    }

    private func requestCustomerInfo(appUserID: String,
                                     isAppBackgrounded: Bool,
                                     completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let allowComputingOffline = self.offlineEntitlementsManager.shouldComputeOfflineCustomerInfo(
            appUserID: appUserID
        )

        self.backend.getCustomerInfo(appUserID: appUserID,
                                     isAppBackgrounded: isAppBackgrounded,
                                     allowComputingOffline: allowComputingOffline,
                                     completion: completion)
    }

    private func fetchAndCacheCustomerInfoData(appUserID: String,
                                               isAppBackgrounded: Bool,
                                               completion: CustomerInfoDataCompletion?) {
        self.getCustomerInfoData(appUserID: appUserID,
                                 isAppBackgrounded: isAppBackgrounded) { customerInfoDataResult in
            switch customerInfoDataResult.result {
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
                    completion(customerInfoDataResult)
                }
            }
        }
    }

    private func fetchAndCacheCustomerInfoDataIfStale(appUserID: String,
                                                      isAppBackgrounded: Bool,
                                                      completion: CustomerInfoDataCompletion?) {
        let isCacheStale = self.withData {
            $0.deviceCache.isCustomerInfoCacheStale(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded)
        }

        guard !isCacheStale, let customerInfo = try? self.cachedCustomerInfo(appUserID: appUserID) else {
            Logger.debug(isAppBackgrounded
                            ? Strings.customerInfo.customerinfo_stale_updating_in_background
                            : Strings.customerInfo.customerinfo_stale_updating_in_foreground)
            self.fetchAndCacheCustomerInfoData(appUserID: appUserID,
                                               isAppBackgrounded: isAppBackgrounded,
                                               completion: completion)
            return
        }

        if let completion = completion {
            self.operationDispatcher.dispatchOnMainActor {
                completion(CustomerInfoDataResult(result: .success(customerInfo)))
            }
        }
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

    // MARK: - For UI Preview mode

    /// Generates a dummy `CustomerInfo` with hardcoded information exclusively for UI Preview mode.
    private func createPreviewCustomerInfo() -> CustomerInfo {
        let previewSubscriber = CustomerInfoResponse.Subscriber(
            originalAppUserId: IdentityManager.uiPreviewModeAppUserID,
            firstSeen: Date(),
            subscriptions: [:],
            nonSubscriptions: [:],
            entitlements: [:]
        )
        let previewCustomerInfoResponse = CustomerInfoResponse(subscriber: previewSubscriber,
                                                               requestDate: Date(),
                                                               rawData: [:])
        let previewCustomerInfo = CustomerInfo(response: previewCustomerInfoResponse,
                                               entitlementVerification: .verified,
                                               sandboxEnvironmentDetector: BundleSandboxEnvironmentDetector.default)
        return previewCustomerInfo
    }

    private func trackGetCustomerInfoStartedIfNeeded(trackDiagnostics: Bool) {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *), trackDiagnostics {
            self.diagnosticsTracker?.trackGetCustomerInfoStarted()
        }
    }

    private func trackGetCustomerInfoResultIfNeeded(trackDiagnostics: Bool,
                                                    startTime: Date,
                                                    cacheFetchPolicy: CacheFetchPolicy,
                                                    customerInfoDataResult: CustomerInfoDataResult) {
        self.trackGetCustomerInfoResultIfNeeded(
            trackDiagnostics: trackDiagnostics,
            startTime: startTime,
            cacheFetchPolicy: cacheFetchPolicy,
            hadUnsyncedPurchasesBefore: customerInfoDataResult.hadUnsyncedPurchasesBefore,
            usedOfflineEntitlements: customerInfoDataResult.usedOfflineEntitlements,
            result: customerInfoDataResult.result.mapError({ $0 as Error })
        )
    }

    // swiftlint:disable:next function_parameter_count
    private func trackGetCustomerInfoResultIfNeeded(trackDiagnostics: Bool,
                                                    startTime: Date,
                                                    cacheFetchPolicy: CacheFetchPolicy,
                                                    hadUnsyncedPurchasesBefore: Bool?,
                                                    usedOfflineEntitlements: Bool,
                                                    result: Swift.Result<CustomerInfo, Error>) {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *), trackDiagnostics {

            let error: PurchasesError?
            switch result.error {
            case let purchasesError as PurchasesError:
                error = purchasesError
            case let purchasesErrorConvertible as PurchasesErrorConvertible:
                error = purchasesErrorConvertible.asPurchasesError
            case let otherError:
                error = otherError.map { PurchasesError(error: .unknownError, userInfo: ($0 as NSError).userInfo) }
            }
            let customerInfo = result.value
            let responseTime = self.dateProvider.now().timeIntervalSince(startTime)

            self.diagnosticsTracker?.trackGetCustomerInfoResult(
                cacheFetchPolicy: cacheFetchPolicy,
                verificationResult: customerInfo?.entitlements.verification,
                hadUnsyncedPurchasesBefore: hadUnsyncedPurchasesBefore,
                errorMessage: error?.localizedDescription,
                errorCode: error?.errorCode,
                responseTime: responseTime
            )
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
