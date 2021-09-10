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

    // swiftlint:disable line_length
    func checkTrialOrIntroPriceEligibilityFromOptimalStoreKitVersion(_ productIdentifiers: [String],
                                                                     completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:enable line_length
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            sk2CheckTrialOrIntroPriceEligibility(productIdentifiers, completionBlock: receiveEligibility)
        } else {
            sk1CheckTrialOrIntroPriceEligibility(productIdentifiers, completionBlock: receiveEligibility)
        }
    }

    // swiftlint:disable line_length
    func sk1CheckTrialOrIntroPriceEligibility(_ productIdentifiers: [String],
                                              completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:enable line_length
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            if #available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *),
               let data = maybeData {
                self.sk1ModernEligibilityHandler(maybeReceiptData: data,
                                              productIdentifiers: productIdentifiers,
                                              completionBlock: receiveEligibility)
            } else {
                self.backend.getIntroEligibility(appUserID: self.appUserID,
                                                 receiptData: maybeData ?? Data(),
                                                 productIdentifiers: productIdentifiers) { result, maybeError in
                    if let error = maybeError {
                        Logger.error(String(format: Strings.purchase.unable_to_get_intro_eligibility_for_user,
                                            error.localizedDescription))
                    }
                    self.operationDispatcher.dispatchOnMainThread {
                        receiveEligibility(result)
                    }
                }
            }
        }
    }

    // swiftlint:disable line_length
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2CheckTrialOrIntroPriceEligibility(_ productIdentifiers: [String],
                                              completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:enable line_length
        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: Set(productIdentifiers)) { products in
            Task {
                var introDict = productIdentifiers.reduce(into: [:]) { resultDict, productId in
                    resultDict[productId] = IntroEligibility(eligibilityStatus: IntroEligibilityStatus.unknown)
                }
                for product in products {
                    guard let sk2ProductDetails = product as? SK2ProductDetails else {
                        continue
                    }
                    // TODO: remove when this gets fixed.
                    // limiting to arm architecture since builds on beta 5 fail if other archs are included
                    #if arch(arm64)
                    let maybeIsEligible = await sk2ProductDetails.isEligibleForIntroOffer()

                    let eligibilityStatus: IntroEligibilityStatus

                    if let isEligible = maybeIsEligible {
                        eligibilityStatus = isEligible ? .eligible : .ineligible
                    } else {
                        eligibilityStatus = .unknown
                    }

                    introDict[sk2ProductDetails.productIdentifier] =
                        IntroEligibility(eligibilityStatus: eligibilityStatus)
                    #endif
                }
                receiveEligibility(introDict)
            }
        }
    }

    // swiftlint:disable line_length
    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    private func sk1ModernEligibilityHandler(maybeReceiptData data: Data,
                                             productIdentifiers: [String],
                                             completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        introEligibilityCalculator
            .checkTrialOrIntroductoryPriceEligibility(with: data,
                                                      productIdentifiers: Set(productIdentifiers)) { receivedEligibility, maybeError in
                if let error = maybeError {
                    Logger.error(String(format: Strings.receipt.parse_receipt_locally_error,
                                        error.localizedDescription))
                    self.backend.getIntroEligibility(appUserID: self.appUserID,
                                                     receiptData: data,
                                                     productIdentifiers: productIdentifiers) { result, maybeAnotherError in
                        if let intoEligibilityError = maybeAnotherError {
                            Logger.error(String(format: Strings.purchase.unable_to_get_intro_eligibility_with_error,
                                                intoEligibilityError.localizedDescription))
                        }
                        self.operationDispatcher.dispatchOnMainThread {
                            receiveEligibility(result)
                        }
                    }
                } else {
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
        // swiftlint:enable line_length
    }

}
