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

class TrialOrIntroPriceEligibilityChecker {

    typealias ReceiveIntroEligibilityBlock = ([String: IntroEligibility]) -> Void

    private var appUserID: String { identityManager.currentAppUserID }
    private let receiptFetcher: ReceiptFetcher
    private let introEligibilityCalculator: IntroEligibilityCalculator
    private let backend: Backend
    private let identityManager: IdentityManager
    private let operationDispatcher: OperationDispatcher
    private let productsManager: ProductsManager

    init(receiptFetcher: ReceiptFetcher,
         introEligibilityCalculator: IntroEligibilityCalculator,
         backend: Backend,
         identityManager: IdentityManager,
         operationDispatcher: OperationDispatcher,
         productsManager: ProductsManager) {
        self.receiptFetcher = receiptFetcher
        self.introEligibilityCalculator = introEligibilityCalculator
        self.backend = backend
        self.identityManager = identityManager
        self.operationDispatcher = operationDispatcher
        self.productsManager = productsManager
    }

    func checkEligibility(productIdentifiers: [String],
                          completion: @escaping ReceiveIntroEligibilityBlock) {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            _ = Task<Void, Never> {
                let eligibility = await sk2CheckEligibility(productIdentifiers)
                completion(eligibility)
            }
        } else {
            sk1CheckEligibility(productIdentifiers, completion: completion)
        }
    }

    func sk1CheckEligibility(_ productIdentifiers: [String],
                             completion: @escaping ReceiveIntroEligibilityBlock) {
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *),
               let data = maybeData {
                self.sk1CheckEligibility(with: data,
                                         productIdentifiers: productIdentifiers,
                                         completion: completion)
            } else {
                self.getIntroEligibility(with: maybeData ?? Data(),
                                         productIdentifiers: productIdentifiers,
                                         completion: completion)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2CheckEligibility(_ productIdentifiers: [String]) async -> [String: IntroEligibility] {
        let identifiers = Set(productIdentifiers)
        var introDict = productIdentifiers.reduce(into: [:]) { resultDict, productId in
            resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
        }

        // fixme: handle errors
        let products = (try? await productsManager.sk2StoreProducts(withIdentifiers: identifiers)) ?? []
        for sk2StoreProduct in products {
            let sk2Product = sk2StoreProduct.underlyingSK2Product
            let maybeIsEligible = await sk2Product.subscription?.isEligibleForIntroOffer

            let eligibilityStatus: IntroEligibilityStatus

            if let isEligible = maybeIsEligible {
                eligibilityStatus = isEligible ? .eligible : .ineligible
            } else {
                eligibilityStatus = .unknown
            }

            introDict[sk2StoreProduct.productIdentifier] =
            IntroEligibility(eligibilityStatus: eligibilityStatus)
        }
        return introDict
    }

}

fileprivate extension TrialOrIntroPriceEligibilityChecker {

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *)
    func sk1CheckEligibility(with receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping ReceiveIntroEligibilityBlock) {
        introEligibilityCalculator
            .checkEligibility(with: receiptData,
                              productIdentifiers: Set(productIdentifiers)) { receivedEligibility, maybeError in
                if let error = maybeError {
                    Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
                    self.getIntroEligibility(with: receiptData,
                                             productIdentifiers: productIdentifiers,
                                             completion: completion)
                    return
                }
                var convertedEligibility: [String: IntroEligibility] = [:]
                for (key, value) in receivedEligibility {
                    let introEligibility = IntroEligibility(eligibilityStatus: value)
                    convertedEligibility[key] = introEligibility
                }
                self.operationDispatcher.dispatchOnMainThread {
                    completion(convertedEligibility)
                }
            }
    }

    func getIntroEligibility(with receiptData: Data,
                             productIdentifiers: [String],
                             completion: @escaping ReceiveIntroEligibilityBlock) {
        if #available(iOS 11.2, macOS 10.13.2, macCatalyst 13.0, tvOS 11.2, watchOS 6.2, *) {
            self.productsWithIntroOffers(productIdentifiers: productIdentifiers) {
                self.getIntroEligibility(with: receiptData,
                                         productIdentifiers: productIdentifiers,
                                         productIdsToIntroEligibleStatusFromApple: $0,
                                         completion: completion)
            }
        } else {
            self.getIntroEligibility(with: receiptData,
                                     productIdentifiers: productIdentifiers,
                                     productIdsToIntroEligibleStatusFromApple: [:],
                                     completion: completion)
        }
    }

}

private extension TrialOrIntroPriceEligibilityChecker {

    @available(iOS 11.2, macOS 10.13.2, macCatalyst 13.0, tvOS 11.2, watchOS 6.2, *)
    func productsWithIntroOffers(productIdentifiers: [String], completion: @escaping ReceiveIntroEligibilityBlock) {
        self.productsManager.products(withIdentifiers: Set(productIdentifiers)) { products in
            let eligibility: [(String, IntroEligibility)] = Array(products.value ?? [])
                .filter { $0.introductoryPrice != nil }
                .map { ($0.productIdentifier, IntroEligibility(eligibilityStatus: .eligible)) }

            let productIdsToIntroEligibleStatus = Dictionary(uniqueKeysWithValues: eligibility)
            completion(productIdsToIntroEligibleStatus)
        }
    }

    func getIntroEligibility(with receiptData: Data,
                             productIdentifiers: [String],
                             productIdsToIntroEligibleStatusFromApple: [String: IntroEligibility],
                             completion: @escaping ReceiveIntroEligibilityBlock) {
        // Remove any productIds we already have intro pricing for so we don't try to fetch them from the backend.
        let idsToFetchFromBackend = productIdentifiers.filter { productIdsToIntroEligibleStatusFromApple[$0] == nil }
        if idsToFetchFromBackend.isEmpty {
            completion(productIdsToIntroEligibleStatusFromApple)
            return
        }

        self.backend.fetchIntroEligibility(appUserID: self.appUserID,
                                           receiptData: receiptData,
                                           productIdentifiers: idsToFetchFromBackend) { backendResult, maybeError in
            var result = backendResult
            if let error = maybeError {
                Logger.error(Strings.purchase.unable_to_get_intro_eligibility_for_user(error: error))
                let resultWithUnknowns = productIdentifiers.reduce(into: [:]) { resultDict, productId in
                    resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
                }
                result = resultWithUnknowns
            }
            self.operationDispatcher.dispatchOnMainThread {
                completion(result)
            }
        }
    }

}
