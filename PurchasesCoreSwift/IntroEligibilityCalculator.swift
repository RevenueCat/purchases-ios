//
//  IntroEligibilityCalculator.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCIntroEligibilityCalculator) public class IntroEligibilityCalculator: NSObject {
    private let productsManager: ProductsManager
    private let receiptParser: ReceiptParser

    @objc public override init() {
        self.productsManager = ProductsManager()
        self.receiptParser = ReceiptParser()
    }

    internal init(productsManager: ProductsManager,
                  receiptParser: ReceiptParser) {
        self.productsManager = productsManager
        self.receiptParser = receiptParser
    }

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    @objc public func checkTrialOrIntroductoryPriceEligibility(
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

            let hasIntroductoryPrice = candidate.introductoryPrice != nil
            result[candidate.productIdentifier] = !hasIntroductoryPrice || usedIntroForProductIdentifier
                ? IntroEligibilityStatus.ineligible.toNSNumber()
                : IntroEligibilityStatus.eligible.toNSNumber()
        }
        return result
    }
}

enum IntroEligibilityStatus: Int {
    case unknown,
         ineligible,
         eligible
}

extension IntroEligibilityStatus {
    func toNSNumber() -> NSNumber {
        return self.rawValue as NSNumber
    }
}
