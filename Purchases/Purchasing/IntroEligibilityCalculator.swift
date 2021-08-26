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

    init(productsManager: ProductsManager = ProductsManager(), receiptParser: ReceiptParser = ReceiptParser()) {
        self.productsManager = productsManager
        self.receiptParser = receiptParser
    }

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    func checkTrialOrIntroductoryPriceEligibility(
        with receiptData: Data,
        productIdentifiers candidateProductIdentifiers: Set<String>,
        completion: @escaping ([String: NSNumber], Error?) -> Void) {
        guard candidateProductIdentifiers.count > 0 else {
            completion([:], nil)
            return
        }
        Logger.debug(Strings.purchaserInfo.checking_intro_eligibility_locally)

        var result: [String: NSNumber] = candidateProductIdentifiers.reduce(into: [:]) { resultDict, productId in
            resultDict[productId] = IntroEligibilityStatus.unknown.toNSNumber()
        }
        do {
            let receipt = try receiptParser.parse(from: receiptData)
            let purchasedProductIdsWithIntroOffersOrFreeTrials =
                receipt.purchasedIntroOfferOrFreeTrialProductIdentifiers()

            let allProductIdentifiers =
                candidateProductIdentifiers.union(purchasedProductIdsWithIntroOffersOrFreeTrials)

            productsManager.products(withIdentifiers: allProductIdentifiers) { allProducts in
                let purchasedProductsWithIntroOffersOrFreeTrials = allProducts.filter {
                    purchasedProductIdsWithIntroOffersOrFreeTrials.contains($0.productIdentifier)
                }
                let candidateProducts = allProducts.filter {
                    candidateProductIdentifiers.contains($0.productIdentifier)
                }

                let eligibility: [String: NSNumber] = self.checkIntroEligibility(
                    candidateProducts: candidateProducts,
                    purchasedProductsWithIntroOffers: purchasedProductsWithIntroOffersOrFreeTrials)
                result.merge(eligibility) { (_, new) in new }

                Logger.debug(String(format: Strings.purchaserInfo.checking_intro_eligibility_locally_result, result))
                completion(result, nil)
            }
        } catch let error {
            Logger.error(
                String(
                    format: Strings.purchaserInfo.checking_intro_eligibility_locally_error, error.localizedDescription
                )
            )
            completion([:], error)
            return
        }
    }
}

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
private extension IntroEligibilityCalculator {

    func checkIntroEligibility(candidateProducts: Set<SKProduct>,
                               purchasedProductsWithIntroOffers: Set<SKProduct>) -> [String: NSNumber] {
        var result: [String: NSNumber] = [:]
        for candidate in candidateProducts {
            let usedIntroForProductIdentifier = purchasedProductsWithIntroOffers
                .contains { purchased in
                    let foundByGroupId = (candidate.subscriptionGroupIdentifier != nil
                        && candidate.subscriptionGroupIdentifier == purchased.subscriptionGroupIdentifier)
                    return foundByGroupId
                }
            result[candidate.productIdentifier] = usedIntroForProductIdentifier
                ? IntroEligibilityStatus.ineligible.toNSNumber()
                : IntroEligibilityStatus.eligible.toNSNumber()
        }
        return result
    }

}

extension IntroEligibilityStatus {

    func toNSNumber() -> NSNumber {
        return self.rawValue as NSNumber
    }

}
