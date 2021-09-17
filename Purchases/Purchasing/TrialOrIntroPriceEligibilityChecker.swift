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
                          completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            Task {
                let eligibility = await sk2CheckEligibility(productIdentifiers)
                receiveEligibility(eligibility)
            }
        } else {
            sk1CheckEligibility(productIdentifiers, completionBlock: receiveEligibility)
        }
    }

    func sk1CheckEligibility(_ productIdentifiers: [String],
                             completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            if #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *),
               let data = maybeData {
                self.sk1CheckEligibility(with: data,
                                         productIdentifiers: productIdentifiers,
                                         completionBlock: receiveEligibility)
            } else {
                self.backend.getIntroEligibility(appUserID: self.appUserID,
                                                 receiptData: maybeData ?? Data(),
                                                 productIdentifiers: productIdentifiers) { result, maybeError in
                    if let error = maybeError {
                        Logger.error(Strings.purchase.unable_to_get_intro_eligibility_for_user(error: error))
                    }
                    self.operationDispatcher.dispatchOnMainThread {
                        receiveEligibility(result)
                    }
                }
            }
        }
    }

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.2, *)
    private func sk1CheckEligibility(with receiptData: Data,
                                     productIdentifiers: [String],
                                     completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        introEligibilityCalculator
            .checkEligibility(with: receiptData,
                              productIdentifiers: Set(productIdentifiers)) { receivedEligibility, maybeError in
                if let error = maybeError {
                    Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
                    self.backend
                        .getIntroEligibility(appUserID: self.appUserID,
                                             receiptData: receiptData,
                                             productIdentifiers: productIdentifiers) { result, maybeAnotherError in
                            if let intoEligibilityError = maybeAnotherError {
                                let errorMessage =
                                Strings.purchase.unable_to_get_intro_eligibility_with_error(error: intoEligibilityError)
                                Logger.error(errorMessage)
                            }
                            self.operationDispatcher.dispatchOnMainThread {
                                receiveEligibility(result)
                            }
                        }
                    return
                }
                var convertedEligibility: [String: IntroEligibility] = [:]
                for (key, value) in receivedEligibility {
                    let introEligibility = IntroEligibility(eligibilityStatus: value)
                    convertedEligibility[key] = introEligibility
                }
                self.operationDispatcher.dispatchOnMainThread {
                    receiveEligibility(convertedEligibility)
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
