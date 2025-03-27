//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroTrialOrIntroductoryPriceEligibilityChecker.swift
//
//  Created by César de la Vega on 8/31/21.

import Foundation
import StoreKit

typealias ReceiveIntroEligibilityBlock = ([String: IntroEligibility]) -> Void

/// A type that can determine `IntroEligibility` for products.
protocol TrialOrIntroPriceEligibilityCheckerType: Sendable {

    func checkEligibility(productIdentifiers: Set<String>, completion: @escaping ReceiveIntroEligibilityBlock)
}

class TrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    private var appUserID: String { self.currentUserProvider.currentAppUserID }

    private let systemInfo: SystemInfo
    private let receiptFetcher: ReceiptFetcher
    private let introEligibilityCalculator: IntroEligibilityCalculator
    private let backend: Backend
    private let currentUserProvider: CurrentUserProvider
    private let operationDispatcher: OperationDispatcher
    private let productsManager: ProductsManagerType
    private let diagnosticsTracker: DiagnosticsTrackerType?
    private let dateProvider: DateProvider

    init(
        systemInfo: SystemInfo,
        receiptFetcher: ReceiptFetcher,
        introEligibilityCalculator: IntroEligibilityCalculator,
        backend: Backend,
        currentUserProvider: CurrentUserProvider,
        operationDispatcher: OperationDispatcher,
        productsManager: ProductsManagerType,
        diagnosticsTracker: DiagnosticsTrackerType?,
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
    }

    func checkEligibility(productIdentifiers: Set<String>,
                          completion: @escaping ReceiveIntroEligibilityBlock) {
        guard !self.systemInfo.dangerousSettings.uiPreviewMode else {
            // No check eligibility request should happen in UI preview mode.
            // Thus, the eligibility status for all product identifiers are set to `.unknown`
            let result = productIdentifiers.reduce(into: [:]) { resultDict, productId in
                resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
            }
            completion(result)
            return
        }

        guard !productIdentifiers.isEmpty else {
            Logger.warn(Strings.eligibility.check_eligibility_no_identifiers)
            completion([:])
            return
        }

        let startTime = self.dateProvider.now()

        // Extracting and wrapping the completion block from the async call
        // to avoid having to mark ReceiveIntroEligibilityBlock as @Sendable
        // up to the public API thus making a breaking change.
        let completionBlock: ([String: IntroEligibility], Error?, StoreKitVersion) -> Void =
        { [weak self] (result, error, storeKitVersion) in
            self?.trackTrialOrIntroEligibilityRequestIfNeeded(startTime: startTime,
                                                              requestedProductIds: productIdentifiers,
                                                              result: result,
                                                              error: error,
                                                              storeKitVersion: storeKitVersion)
            self?.operationDispatcher.dispatchOnMainActor {
                completion(result)
            }
        }

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable {
            Async.call(with: completionBlock) {
                let result: [String: IntroEligibility]
                let checkError: Error?
                do {
                    result = try await self.sk2CheckEligibility(productIdentifiers)
                    checkError = nil
                } catch {
                    Logger.appleError(Strings.eligibility.unable_to_get_intro_eligibility_for_user(error: error))

                    result = productIdentifiers.reduce(into: [:]) { resultDict, productId in
                        resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
                    }
                    checkError = error
                }
                return (result, checkError, .storeKit2)
            }
        } else {
            self.sk1CheckEligibility(productIdentifiers) { eligibility, error in
                completionBlock(eligibility, error, .storeKit1)
            }
        }
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
    func sk2CheckEligibility(_ productIdentifiers: Set<String>) async throws -> [String: IntroEligibility] {
        var introDictionary: [String: IntroEligibility] = productIdentifiers.dictionaryWithValues { _ in
                .init(eligibilityStatus: .unknown)
        }

        let products = try await self.productsManager.sk2Products(withIdentifiers: productIdentifiers)
        for sk2StoreProduct in products {
            let sk2Product = sk2StoreProduct.underlyingSK2Product

            let eligibilityStatus: IntroEligibilityStatus

            if let subscription = sk2Product.subscription, subscription.introductoryOffer != nil {
                let isEligible = await TimingUtil.measureAndLogIfTooSlow(
                    threshold: .introEligibility,
                    message: Strings.eligibility.sk2_intro_eligibility_too_slow.description) {
                        return await subscription.isEligibleForIntroOffer
                    }
                eligibilityStatus = isEligible ? .eligible : .ineligible
            } else {
                eligibilityStatus = .noIntroOfferExists
            }

            introDictionary[sk2StoreProduct.productIdentifier] = .init(eligibilityStatus: eligibilityStatus)
        }

        return introDictionary
    }

}

/// Default overload implementation that takes a single `StoreProductType`.
extension TrialOrIntroPriceEligibilityCheckerType {

    func checkEligibility(product: StoreProductType, completion: @escaping (IntroEligibilityStatus) -> Void) {
        self.checkEligibility(productIdentifiers: [product.productIdentifier]) { eligibility in
            completion(eligibility[product.productIdentifier]?.status ?? .unknown)
        }
    }

}

// MARK: - Implementations

private extension TrialOrIntroPriceEligibilityChecker {

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

        self.backend.offerings.getIntroEligibility(appUserID: self.appUserID,
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

                                                                    responseTime: responseTime)
    }

}
