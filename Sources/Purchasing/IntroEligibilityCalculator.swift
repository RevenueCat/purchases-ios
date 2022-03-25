//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroEligibilityCalculator.swift
//
//  Created by Andrés Boedo on 7/14/20.
//

import Foundation
import StoreKit

class IntroEligibilityCalculator {

    private let productsManager: ProductsManager
    private let receiptParser: ReceiptParser

    init(productsManager: ProductsManager,
         receiptParser: ReceiptParser) {
        self.productsManager = productsManager
        self.receiptParser = receiptParser
    }

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    func checkEligibility(with receiptData: Data,
                          productIdentifiers candidateProductIdentifiers: Set<String>,
                          completion: @escaping ([String: IntroEligibilityStatus], Error?) -> Void) {
        guard candidateProductIdentifiers.count > 0 else {
            completion([:], nil)
            return
        }
        Logger.debug(Strings.customerInfo.checking_intro_eligibility_locally)

        var result = candidateProductIdentifiers.reduce(into: [:]) { resultDict, productId in
            resultDict[productId] = IntroEligibilityStatus.unknown
        }
        do {
            let receipt = try receiptParser.parse(from: receiptData)
            let purchasedProductIdsWithIntroOffersOrFreeTrials =
                receipt.purchasedIntroOfferOrFreeTrialProductIdentifiers()

            let allProductIdentifiers =
                candidateProductIdentifiers.union(purchasedProductIdsWithIntroOffersOrFreeTrials)

            productsManager.products(withIdentifiers: allProductIdentifiers) {
                let allProducts = $0.value ?? []

                let purchasedProductsWithIntroOffersOrFreeTrials = allProducts.filter {
                    purchasedProductIdsWithIntroOffersOrFreeTrials.contains($0.productIdentifier)
                }
                let candidateProducts = allProducts.filter {
                    candidateProductIdentifiers.contains($0.productIdentifier)
                }

                let eligibility = self.checkEligibility(
                    candidateProducts: candidateProducts,
                    purchasedProductsWithIntroOffers: purchasedProductsWithIntroOffersOrFreeTrials)
                result.merge(eligibility) { (_, new) in new }

                Logger.debug(
                    Strings.customerInfo.checking_intro_eligibility_locally_result(productIdentifiers: result)
                )
                completion(result, nil)
            }
        } catch {
            Logger.error(Strings.customerInfo.checking_intro_eligibility_locally_error(error: error))
            completion([:], error)
            return
        }
    }
}

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
private extension IntroEligibilityCalculator {

    func checkEligibility(candidateProducts: Set<StoreProduct>,
                          purchasedProductsWithIntroOffers: Set<StoreProduct>) -> [String: IntroEligibilityStatus] {
        var result: [String: IntroEligibilityStatus] = [:]

        for candidate in candidateProducts {
            guard candidate.subscriptionPeriod != nil else {
                result[candidate.productIdentifier] = IntroEligibilityStatus.unknown
                continue
            }
            let usedIntroForProductIdentifier = purchasedProductsWithIntroOffers
                .contains { purchased in
                    let foundByGroupId = (candidate.subscriptionGroupIdentifier != nil
                        && candidate.subscriptionGroupIdentifier == purchased.subscriptionGroupIdentifier)
                    return foundByGroupId
                }

            if candidate.introductoryDiscount == nil {
                result[candidate.productIdentifier] = .noIntroOfferExists
            } else {
                result[candidate.productIdentifier] = usedIntroForProductIdentifier
                    ? IntroEligibilityStatus.ineligible
                    : IntroEligibilityStatus.eligible
            }
        }
        return result
    }

}
