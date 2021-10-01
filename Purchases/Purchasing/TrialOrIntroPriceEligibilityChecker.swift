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
            Task {
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
                self.fetchIntroEligibilityFromBackend(with: maybeData ?? Data(),
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
        let products = await productsManager.sk2ProductDetails(withIdentifiers: identifiers)
        for sk2ProductDetails in products {
            let sk2Product = sk2ProductDetails.underlyingSK2Product
            let maybeIsEligible = await sk2Product.subscription?.isEligibleForIntroOffer

            let eligibilityStatus: IntroEligibilityStatus

            if let isEligible = maybeIsEligible {
                eligibilityStatus = isEligible ? .eligible : .ineligible
            } else {
                eligibilityStatus = .unknown
            }

            introDict[sk2ProductDetails.productIdentifier] =
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
                    self.fetchIntroEligibilityFromBackend(with: receiptData,
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

    func fetchIntroEligibilityFromBackend(with receiptData: Data,
                                          productIdentifiers: [String],
                                          completion: @escaping ReceiveIntroEligibilityBlock) {
        self.backend.getIntroEligibility(appUserID: self.appUserID,
                                         receiptData: receiptData,
                                         productIdentifiers: productIdentifiers) { backendResult, maybeError in
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
