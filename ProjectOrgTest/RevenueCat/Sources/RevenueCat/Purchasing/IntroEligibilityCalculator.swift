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

    private let productsManager: ProductsManagerType
    private let receiptParser: PurchasesReceiptParser

    init(productsManager: ProductsManagerType,
         receiptParser: PurchasesReceiptParser) {
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

        var result = candidateProductIdentifiers.dictionaryWithValues { _ in IntroEligibilityStatus.unknown }
        do {
            let receipt = try self.receiptParser.parse(from: receiptData)
            Logger.debug(Strings.customerInfo.checking_intro_eligibility_locally_from_receipt(receipt))

            let activeSubscriptionsProductIdentifiers = receipt
                .activeSubscriptionsProductIdentifiers
            let expiredTrialProductIdentifiers = receipt.expiredTrialProductIdentifiers
            let allProductIdentifiers = candidateProductIdentifiers
                .union(activeSubscriptionsProductIdentifiers)
                .union(expiredTrialProductIdentifiers)

            self.productsManager.products(withIdentifiers: allProductIdentifiers) {
                let allProducts = $0.value ?? []

                let candidateProducts = allProducts.filter {
                    candidateProductIdentifiers.contains($0.productIdentifier)
                }
                let activeSubscriptionsProducts = allProducts.filter {
                    activeSubscriptionsProductIdentifiers.contains($0.productIdentifier)
                }
                let expiredTrialProducts = allProducts.filter {
                    expiredTrialProductIdentifiers.contains($0.productIdentifier)
                }

                let eligibility = self.checkEligibility(
                    candidateProducts: candidateProducts,
                    activeSubscriptionsProducts: activeSubscriptionsProducts,
                    expiredTrialProducts: expiredTrialProducts
                )
                result += eligibility

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

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension IntroEligibilityCalculator: @unchecked Sendable {}

// MARK: - Private

@available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
private extension IntroEligibilityCalculator {

    func checkEligibility(
        candidateProducts: Set<StoreProduct>,
        activeSubscriptionsProducts: Set<StoreProduct>,
        expiredTrialProducts: Set<StoreProduct>
    ) -> [String: IntroEligibilityStatus] {
        var result: [String: IntroEligibilityStatus] = [:]

        for candidate in candidateProducts {
            guard candidate.subscriptionPeriod != nil else {
                result[candidate.productIdentifier] = .unknown
                continue
            }
            let activeSubscriptionInGroup = activeSubscriptionsProducts.contains {
                $0.subscriptionGroupIdentifier == candidate.subscriptionGroupIdentifier
            }
            let expiredTrialInGroup = expiredTrialProducts.contains {
                $0.subscriptionGroupIdentifier == candidate.subscriptionGroupIdentifier
            }

            if candidate.introductoryDiscount == nil {
                result[candidate.productIdentifier] = .noIntroOfferExists
            } else {
                let isEligible = !activeSubscriptionInGroup && !expiredTrialInGroup

                result[candidate.productIdentifier] = isEligible
                    ? .eligible
                    : .ineligible
            }
        }
        return result
    }

}
