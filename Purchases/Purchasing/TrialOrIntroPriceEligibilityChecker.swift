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
        guard !productIdentifiers.isEmpty else {
            Logger.warn(Strings.purchase.check_eligibility_no_identifiers)
            completion([:])
            return
        }

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            _ = Task<Void, Never> {
                do {
                    completion(try await sk2CheckEligibility(productIdentifiers))
                } catch {
                    Logger.appleError(Strings.purchase.unable_to_get_intro_eligibility_for_user(error: error))

                    let introDict = productIdentifiers.reduce(into: [:]) { resultDict, productId in
                        resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
                    }
                    completion(introDict)
                }
            }
        } else {
            sk1CheckEligibility(productIdentifiers, completion: completion)
        }
    }

    func checkEligibility(product: StoreProductType,
                          completion: @escaping (IntroEligibilityStatus) -> Void) {
        checkEligibility(productIdentifiers: [product.productIdentifier]) { eligibility in
            completion(eligibility[product.productIdentifier]?.status ?? .unknown)
        }
    }

    func sk1CheckEligibility(_ productIdentifiers: [String],
                             completion: @escaping ReceiveIntroEligibilityBlock) {
        receiptFetcher.receiptData(refreshPolicy: .never) { data in
            if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *),
               let data = data {
                self.sk1CheckEligibility(with: data,
                                         productIdentifiers: productIdentifiers,
                                         completion: completion)
            } else {
                self.getIntroEligibility(with: data ?? Data(),
                                         productIdentifiers: productIdentifiers,
                                         completion: completion)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2CheckEligibility(_ productIdentifiers: [String]) async throws -> [String: IntroEligibility] {
        let identifiers = Set(productIdentifiers)
        var introDict = productIdentifiers.reduce(into: [:]) { resultDict, productId in
            resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
        }

        let products = try await productsManager.sk2StoreProducts(withIdentifiers: identifiers)
        for sk2StoreProduct in products {
            let sk2Product = sk2StoreProduct.underlyingSK2Product

            let eligibilityStatus: IntroEligibilityStatus

            if let subscription = sk2Product.subscription {
                let isEligible = await subscription.isEligibleForIntroOffer
                eligibilityStatus = isEligible ? .eligible : .ineligible
            } else {
                eligibilityStatus = .noIntroOfferExists
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
                              productIdentifiers: Set(productIdentifiers)) { receivedEligibility, error in
                if let error = error {
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
            // Products that don't have an introductory discount don't need to be sent to the backend
            // Step 1: Filter out products without introductory discount and give .noIntroOfferExists status
            // Step 2: Send products without eligibility status to backend
            // Step 3: Merge results from step 1 and step 2
            self.productsWithKnownIntroEligibilityStatus(productIdentifiers: productIdentifiers) { onDeviceResults in
                let nilProductIdentifiers = productIdentifiers.filter { productIdentifier in
                    return onDeviceResults[productIdentifier] == nil
                }

                self.getIntroEligibilityFromBackend(with: receiptData,
                                                    productIdentifiers: nilProductIdentifiers) { backendResults in
                    let results = onDeviceResults + backendResults
                    completion(results)
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
    func productsWithKnownIntroEligibilityStatus(productIdentifiers: [String],
                                                 completion: @escaping ReceiveIntroEligibilityBlock) {
        self.productsManager.products(withIdentifiers: Set(productIdentifiers)) { products in
            let eligibility: [(String, IntroEligibility)] = Array(products.value ?? [])
                .filter { $0.introductoryDiscount == nil }
                .map { ($0.productIdentifier, IntroEligibility(eligibilityStatus: .noIntroOfferExists)) }

            let productIdsToIntroEligibleStatus = Dictionary(uniqueKeysWithValues: eligibility)
            completion(productIdsToIntroEligibleStatus)
        }
    }

    func getIntroEligibilityFromBackend(with receiptData: Data,
                                        productIdentifiers: [String],
                                        completion: @escaping ReceiveIntroEligibilityBlock) {
        if productIdentifiers.isEmpty {
            completion([:])
            return
        }

        self.backend.getIntroEligibility(appUserID: self.appUserID,
                                         receiptData: receiptData,
                                         productIdentifiers: productIdentifiers) { backendResult, error in
            var result = backendResult
            if let error = error {
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
