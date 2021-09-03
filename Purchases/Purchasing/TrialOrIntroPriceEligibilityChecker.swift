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

    init(receiptFetcher: ReceiptFetcher,
         introEligibilityCalculator: IntroEligibilityCalculator,
         backend: Backend,
         identityManager: IdentityManager,
         operationDispatcher: OperationDispatcher) {
        self.receiptFetcher = receiptFetcher
        self.introEligibilityCalculator = introEligibilityCalculator
        self.backend = backend
        self.identityManager = identityManager
        self.operationDispatcher = operationDispatcher
    }

    // swiftlint:disable line_length
    func checkTrialOrIntroPriceEligibilityFromOptimalStoreKitVersion(_ productIdentifiers: [String],
                                                                     completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:enable line_length
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            sk2checkTrialOrIntroPriceEligibility(productIdentifiers, completionBlock: receiveEligibility)
        } else {
            sk1checkTrialOrIntroPriceEligibility(productIdentifiers, completionBlock: receiveEligibility)
        }
    }

    // swiftlint:disable line_length
    func sk1checkTrialOrIntroPriceEligibility(_ productIdentifiers: [String],
                                              completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:enable line_length
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            if #available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *),
               let data = maybeData {
                self.modernEligibilityHandler(maybeReceiptData: data,
                                              productIdentifiers: productIdentifiers,
                                              completionBlock: receiveEligibility)
            } else {
                self.backend.getIntroEligibility(appUserID: self.appUserID,
                                                 receiptData: maybeData ?? Data(),
                                                 productIdentifiers: productIdentifiers) { result, maybeError in
                    if let error = maybeError {
                        Logger.error(String(format: "Unable to getIntroEligibilityForAppUserID: %@",
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
    func sk2checkTrialOrIntroPriceEligibility(_ productIdentifiers: [String],
                                              completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:enable line_length
        Task {
            do {
                let products = try await Product.products(for: productIdentifiers)
                var introDict: [String: IntroEligibility] = [:]
                for product in products {
                    let maybeIsEligible = await product.subscription?.isEligibleForIntroOffer
                    let eligibilityStatus: IntroEligibilityStatus

                    if let isEligible = maybeIsEligible {
                        eligibilityStatus = isEligible ? .eligible : .eligible
                    } else {
                        eligibilityStatus = .unknown
                    }

                    introDict[product.id] = IntroEligibility(eligibilityStatus: eligibilityStatus)
                }
                receiveEligibility(introDict)
            } catch let error {
                Logger.error(String(format: "Unable to get intro eligibility: %@", error.localizedDescription))
                let unknownEligibilities = [IntroEligibility](repeating: IntroEligibility(eligibilityStatus: .unknown),
                                                              count: productIdentifiers.count)
                let productIdentifiersToEligibility = zip(productIdentifiers, unknownEligibilities)
                receiveEligibility(Dictionary(uniqueKeysWithValues: productIdentifiersToEligibility))
            }
        }
    }

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    private func modernEligibilityHandler(maybeReceiptData data: Data,
                                          productIdentifiers: [String],
                                          completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        // swiftlint:disable line_length
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
                            Logger.error(String(format: "Unable to get intro eligibility: %@",
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
