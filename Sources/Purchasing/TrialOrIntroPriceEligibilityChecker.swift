//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
import StoreKit

class TrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private let systemInfo: SystemInfo
    private let receiptFetcher: ReceiptFetcher
    private let introEligibilityCalculator: IntroEligibilityCalculator
    private let backend: Backend
    private let currentUserProvider: CurrentUserProvider
    private let operationDispatcher: OperationDispatcher
    private let productsManager: ProductsManagerType
    private let diagnosticsTracker: DiagnosticsTrackerType?
    private let dateProvider: DateProvider

    private let groupEligibilityCache: SubscriptionGroupIntroEligibilityCache

    init(
        systemInfo: SystemInfo,
        receiptFetcher: ReceiptFetcher,
        introEligibilityCalculator: IntroEligibilityCalculator,
        backend: Backend,
        currentUserProvider: CurrentUserProvider,
        operationDispatcher: OperationDispatcher,
        productsManager: ProductsManagerType,
        diagnosticsTracker: DiagnosticsTrackerType?,
        groupEligibilityCache: SubscriptionGroupIntroEligibilityCache,
        dateProvider: DateProvider = DateProvider()
    ) {
        self.systemInfo = systemInfo
        self.receiptFetcher = receiptFetcher
        self.introEligibilityCalculator = introEligibilityCalculator
        self.backend = backend
        self.currentUserProvider = currentUserProvider
        self.operationDispatcher = operationDispatcher
        self.productsManager = productsManager
        self.diagnosticsTracker = diagnosticsTracker
        self.dateProvider = dateProvider
        self.groupEligibilityCache = groupEligibilityCache
    }

    func clearCache() {
        self.groupEligibilityCache.clearCache()
    }

    /// Delivers the caching wrapper's results after its asynchronous eligibility work completes.
    /// Start timing before the main-actor hop so callback delivery logs exclude the eligibility check itself.
    func deliverEligibility(_ result: [String: IntroEligibility], completion: @escaping ReceiveIntroEligibilityBlock) {
        let logDelivery = IntroEligibilityLog.deliveryLogger(clock: self.systemInfo.clock)
        self.operationDispatcher.dispatchOnMainActor {
            logDelivery(result)
            completion(result)
        }
    }

    func checkEligibility(productIdentifiers: Set<String>) async -> [String: IntroEligibility] {
        if let result = self.immediateEligibility(for: productIdentifiers) {
            return result
        }

        guard !self.systemInfo.isSimulatedStoreAPIKey else {
            // Simulated Store products carry backend-computed eligibility in their introductory discount.
            // Products without that discount have no introductory offer.
            let products = (try? await self.productsManager.products(withIdentifiers: productIdentifiers)) ?? []
            let productsByID = products.dictionaryAllowingDuplicateKeys { $0.productIdentifier }
            return productIdentifiers.dictionaryWithValues { productID in
                let status: IntroEligibilityStatus
                if let product = productsByID[productID] {
                    status = product.introductoryDiscount != nil ? .eligible : .noIntroOfferExists
                } else {
                    status = .unknown
                }
                return IntroEligibility(eligibilityStatus: status)
            }
        }

        let startTime = self.dateProvider.now()
        let didCheckStoreKit = Atomic(false)
        let result: [String: IntroEligibility]
        let checkError: Error?
        let storeKitVersion: StoreKitVersion

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable {
            storeKitVersion = .storeKit2
            do {
                result = try await self.sk2CheckEligibility(productIdentifiers) { groupID in
                    didCheckStoreKit.value = true
                    return await SK2Product.SubscriptionInfo.isEligibleForIntroOffer(for: groupID)
                }
                checkError = nil
            } catch {
                Logger.appleError(Strings.eligibility.unable_to_get_intro_eligibility_for_user(error: error))
                result = productIdentifiers.dictionaryWithValues { _ in IntroEligibility(eligibilityStatus: .unknown) }
                checkError = error
            }
        } else {
            storeKitVersion = .storeKit1
            (result, checkError) = await Async.call { completion in
                self.sk1CheckEligibility(productIdentifiers) { completion(($0, $1)) }
            }
        }

        if storeKitVersion == .storeKit1 || didCheckStoreKit.value || checkError != nil {
            self.trackTrialOrIntroEligibilityRequestIfNeeded(startTime: startTime,
                                                             requestedProductIds: productIdentifiers,
                                                             result: result,
                                                             error: checkError,
                                                             storeKitVersion: storeKitVersion)
        }
        return result
    }

    func sk1CheckEligibility(_ productIdentifiers: Set<String>,
                             completion: @escaping ([String: IntroEligibility], Error?) -> Void) {
        // We don't want to refresh receipts because it will likely prompt the user for their credentials,
        // and intro eligibility is triggered programmatically.
        self.receiptFetcher.receiptData(refreshPolicy: .never) { data, _ in
            if let data = data {
                self.sk1CheckEligibility(with: data,
                                         productIdentifiers: productIdentifiers) { eligibility, error in
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(eligibility, error)
                    }
                }
            } else {
                self.getIntroEligibility(with: data ?? Data(),
                                         productIdentifiers: productIdentifiers) { eligibility, error in
                    self.operationDispatcher.dispatchOnMainActor {
                        completion(eligibility, error)
                    }
                }
            }
        }
    }
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2CheckEligibility(
        _ compoundProductIdentifiers: Set<String>,
        checkSubscriptionGroup: @escaping @Sendable (String) async -> Bool = {
            await SK2Product.SubscriptionInfo.isEligibleForIntroOffer(for: $0)
        }
    ) async throws -> [String: IntroEligibility] {
        var introDictionary = compoundProductIdentifiers.dictionaryWithValues { _ in
            IntroEligibility(eligibilityStatus: .unknown)
        }
        let log = IntroEligibilityLog(clock: self.systemInfo.clock)
        let products = try await log.products(identifiers: compoundProductIdentifiers,
                                              fetch: self.productsManager.products(withIdentifiers:))
        var productIdentifiersByGroup: [String: [String]] = [:]
        for product in products.compactMap({ $0.product as? SK2StoreProduct }) {
            if let subscriptionGroupID = product.subscriptionGroupIDForIntroEligibilityCheck {
                productIdentifiersByGroup[subscriptionGroupID, default: []].append(product.id)
            } else {
                introDictionary[product.id] = .init(eligibilityStatus: .noIntroOfferExists)
            }
        }

        await withTaskGroup(of: (String, Bool).self) { group in
            for subscriptionGroupID in productIdentifiersByGroup.keys {
                group.addTask {
                    let isEligible = await self.groupEligibilityCache.eligibility(
                        for: subscriptionGroupID, log: log, check: checkSubscriptionGroup
                    )
                    return (subscriptionGroupID, isEligible)
                }
            }
            for await (subscriptionGroupID, isEligible) in group {
                let status: IntroEligibilityStatus = isEligible ? .eligible : .ineligible
                for productIdentifier in productIdentifiersByGroup[subscriptionGroupID] ?? [] {
                    introDictionary[productIdentifier] = .init(eligibilityStatus: status)
                }
            }
        }
        log.finished(introDictionary)
        return introDictionary
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension SK2StoreProduct {

    /// Group to ask StoreKit about, or `nil` when the product has no introductory offer.
    var subscriptionGroupIDForIntroEligibilityCheck: String? {
        guard let subscription = self.underlyingSK2Product.subscription else { return nil }
        #if compiler(>=6.3.2)
        if self.representsBillingPlan {
            let hasIntroOffer = self.containsSubscriptionOfferTypeOnBillingPlan(subscriptionOfferType: .introductory)
            return hasIntroOffer ? subscription.subscriptionGroupID : nil
        }
        #endif
        return subscription.introductoryOffer == nil ? nil : subscription.subscriptionGroupID
    }
}

private extension TrialOrIntroPriceEligibilityChecker {

    func immediateEligibility(for productIdentifiers: Set<String>) -> [String: IntroEligibility]? {
        guard !self.systemInfo.dangerousSettings.uiPreviewMode else {
            // Preview mode skips eligibility checks and reports `.unknown` for each product.
            return productIdentifiers.dictionaryWithValues { _ in IntroEligibility(eligibilityStatus: .unknown) }
        }
        guard !productIdentifiers.isEmpty else {
            Logger.warn(Strings.eligibility.check_eligibility_no_identifiers)
            return [:]
        }
        return nil
    }

    func sk1CheckEligibility(with receiptData: Data,
                             productIdentifiers: Set<String>,
                             completion: @escaping ([String: IntroEligibility], Error?) -> Void) {
        introEligibilityCalculator
            .checkEligibility(with: receiptData,
                              productIdentifiers: productIdentifiers) { result in
                switch result {
                case .failure(let localCheckError):
                    Logger.error(Strings.receipt.parse_receipt_locally_error(error: localCheckError))
                    self.getIntroEligibility(with: receiptData,
                                             productIdentifiers: productIdentifiers) { eligibility, backendError in
                        completion(eligibility, backendError ?? localCheckError)
                    }
                case .success(let receivedEligibility):
                    let convertedEligibility = receivedEligibility.mapValues(IntroEligibility.init)

                    self.operationDispatcher.dispatchOnMainThread {
                        completion(convertedEligibility, nil)
                    }
                }
            }
    }

    func getIntroEligibility(with receiptData: Data,
                             productIdentifiers: Set<String>,
                             completion: @escaping ([String: IntroEligibility], BackendError?) -> Void) {
        if #available(iOS 11.2, macOS 10.13.2, macCatalyst 13.0, tvOS 11.2, watchOS 6.2, *) {
            // Products that don't have an introductory discount don't need to be sent to the backend
            // Step 1: Filter out products without introductory discount and give .noIntroOfferExists status
            // Step 2: Send products without eligibility status to backend
            // Step 3: Merge results from step 1 and step 2
            self.productsWithKnownIntroEligibilityStatus(productIdentifiers: productIdentifiers) { onDeviceResults in
                let nilProductIdentifiers = productIdentifiers.filter { productIdentifier in
                    return onDeviceResults[productIdentifier] == nil
                }

                self.getIntroEligibilityFromBackend(
                    with: receiptData,
                    productIdentifiers: nilProductIdentifiers
                ) { backendResults, error in
                    let results = onDeviceResults + backendResults
                    completion(results, error)
                }
            }
        } else {
            self.getIntroEligibilityFromBackend(with: receiptData,
                                                productIdentifiers: productIdentifiers,
                                                completion: completion)
        }
    }

}

extension TrialOrIntroPriceEligibilityChecker {

    @available(iOS 11.2, macOS 10.13.2, macCatalyst 13.0, tvOS 11.2, watchOS 6.2, *)
    func productsWithKnownIntroEligibilityStatus(productIdentifiers: Set<String>,
                                                 completion: @escaping ReceiveIntroEligibilityBlock) {
        self.productsManager.products(withIdentifiers: productIdentifiers) { products in
            let eligibility: [(String, IntroEligibility)] = Array(products.value ?? [])
                .filter { $0.introductoryDiscount == nil }
                .map { ($0.productIdentifier, IntroEligibility(eligibilityStatus: .noIntroOfferExists)) }

            let productIdsToIntroEligibleStatus = Dictionary(uniqueKeysWithValues: eligibility)
            completion(productIdsToIntroEligibleStatus)
        }
    }

    func getIntroEligibilityFromBackend(with receiptData: Data,
                                        productIdentifiers: Set<String>,
                                        completion: @escaping ([String: IntroEligibility], BackendError?) -> Void) {
        if productIdentifiers.isEmpty {
            completion([:], nil)
            return
        }

        self.backend.offerings.getIntroEligibility(appUserID: self.currentUserProvider.currentAppUserID,
                                                   receiptData: receiptData,
                                                   productIdentifiers: productIdentifiers) { backendResult, error in
            let result: [String: IntroEligibility] = {
                if let error = error {
                    Logger.error(Strings.eligibility.unable_to_get_intro_eligibility_for_user(error: error))
                    return productIdentifiers
                        .dictionaryWithValues { _ in IntroEligibility(eligibilityStatus: .unknown) }
                } else {
                    return backendResult
                }
            }()

            self.operationDispatcher.dispatchOnMainThread {
                completion(result, error)
            }
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TrialOrIntroPriceEligibilityChecker: @unchecked Sendable {}

// MARK: - Diagnostics

private extension TrialOrIntroPriceEligibilityChecker {

    func trackTrialOrIntroEligibilityRequestIfNeeded(startTime: Date,
                                                     requestedProductIds: Set<String>,
                                                     result: [String: IntroEligibility],
                                                     error: Error?,
                                                     storeKitVersion: StoreKitVersion) {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *),
              let diagnosticsTracker = self.diagnosticsTracker else {
            return
        }

        var unknownCount, ineligibleCount, eligibleCount, noIntroOfferCount: Int?
        if !result.isEmpty {
            (unknownCount, ineligibleCount, eligibleCount, noIntroOfferCount) = result.reduce(into: (0, 0, 0, 0)) {
                switch $1.value.status {
                case .unknown:
                    $0.0 += 1
                case .ineligible:
                    $0.1 += 1
                case .eligible:
                    $0.2 += 1
                case .noIntroOfferExists:
                    $0.3 += 1
                }
            }
        }

        let errorCode: Int?
        let errorMessage: String?
        switch error {
        case let purchasesError as PurchasesError:
            errorCode = purchasesError.errorCode
            errorMessage = purchasesError.localizedDescription
        case let purchasesErrorConvertible as PurchasesErrorConvertible:
            let purchasesError = purchasesErrorConvertible.asPurchasesError
            errorCode = purchasesError.errorCode
            errorMessage = purchasesError.localizedDescription
        case let receiptParserError as PurchasesReceiptParser.Error:
            errorCode = ErrorCode.invalidReceiptError.rawValue
            errorMessage = receiptParserError.errorDescription ?? receiptParserError.localizedDescription
        case let otherError:
            errorCode = otherError != nil ? ErrorCode.unknownError.rawValue : nil
            errorMessage = otherError?.localizedDescription
        }

        let responseTime = self.dateProvider.now().timeIntervalSince(startTime)

        diagnosticsTracker.trackAppleTrialOrIntroEligibilityRequest(storeKitVersion: storeKitVersion,
                                                                    requestedProductIds: requestedProductIds,
                                                                    eligibilityUnknownCount: unknownCount,
                                                                    eligibilityIneligibleCount: ineligibleCount,
                                                                    eligibilityEligibleCount: eligibleCount,
                                                                    eligibilityNoIntroOfferCount: noIntroOfferCount,
                                                                    errorMessage: errorMessage,
                                                                    errorCode: errorCode,
                                                                    storefront: self.systemInfo.storefront?.countryCode,
                                                                    responseTime: responseTime)
    }

}
